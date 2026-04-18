---
name: tidy
description: Repo hygiene audit — flags files that don't fit the repo's declared purpose (scope drift), versioned duplicates (paper-v1.md…v10.md), build artifacts tracked by git, large/binary files that should be gitignored or LFS'd, untracked sprawl, and stale markers. Asks up to 3 AskUserQuestion clarifications when repo purpose or a disposition is ambiguous. Produces a disposition table per finding (keep / gitignore / move / delete / extract-to-separate-repo). Does NOT auto-apply destructive actions. Use when the user asks to tidy, clean up, audit repo hygiene, check for scope drift, find repo bloat, remove clutter, or asks "what should I clean up." Skip for code quality (use engineering:tech-debt), secrets (use a secret scanner), branch cleanup, or formatting.
---

# Tidy: Repo Hygiene Audit

Apply when a repo has accumulated drift and needs a categorized list of candidates to remove, ignore, move, or extract — *without* auto-deleting anything.

## When NOT to use

- **Code quality / tech debt** — use `engineering:tech-debt`. Tidy is file-level, not code-level.
- **Secret scanning** — use a dedicated scanner.
- **Branch cleanup** — out of scope; `git branch --merged` handles it.
- **Formatting / lint** — out of scope; use the project's formatter.
- **Test coverage** — out of scope.

## Flow

### 1. Infer repo purpose

Read (in parallel):
- `README.md` (first 100 lines) — stated purpose
- `package.json` (name, description, main, type, scripts) — runtime and language
- `pyproject.toml` / `Cargo.toml` / `go.mod` — alternative language signals
- `.gitignore` — what the user already considers out of scope

Form a one-sentence working hypothesis: *"This repo is a TypeScript library that exposes X, runs on Bun."* Keep it internal until step 3 confirms.

### 2. Run cheap signals (parallel)

All sub-second. Do not read source files. Do not run tests.

| Signal | Command | What it flags |
|---|---|---|
| **Tracked files that match ignore patterns** | `git ls-files \| xargs -I{} git check-ignore -v {} 2>/dev/null` | Build artifacts slipped in (dist/, .DS_Store) |
| **Untracked sprawl** | `git ls-files --others --exclude-standard` | Files never committed, never gitignored — decision pending |
| **Large files (tracked or untracked)** | `find . -type f -size +1M -not -path "./.git/*" -not -path "./node_modules/*"` | Candidates for LFS or exclusion |
| **Versioned duplicates** | Regex on basenames: `-v\d+\.`, `\.(bak|old|copy|backup)(\.|$)`, `\s\(\d+\)\.`, `(^\|/)[^/]+-(\d{4}-\d{2}-\d{2})\.` | `paper-v1.md` through `paper-v10.md`, `foo.bak`, `bar (2).txt` |
| **Extension mismatch vs. repo purpose** | Compare file extensions to declared language / purpose | `.pdf`, `.docx`, `.xlsx` in a TypeScript library = scope drift |
| **`.git` directory size** | `du -sh .git/` | History bloat; very large often means binaries committed then deleted |
| **Duplicate basenames across dirs** | `git ls-files \| awk -F/ '{print $NF}' \| sort \| uniq -d` | Possible confusion; sometimes legitimate (index.ts) |

Collect counts + top N examples per signal. Do not produce findings for empty signals.

### 3. AskUserQuestion — clarification (cap: 3)

Only when a signal's disposition depends on user intent. Skip otherwise.

**Archetype 1 — Scope confirmation** (when the repo has clear scope drift):
> "This repo's `package.json` declares a TypeScript library, but I see 19 `.md` + `.pdf` paper drafts in `docs/`. Are the papers part of this repo's scope?"
> options:
> - [Yes — keep them here, they're intentional]
> - [No — they should move to a separate repo]
> - [No — they should be gitignored here, tracked elsewhere]
> - [Mixed — I'll clarify per file]

**Archetype 2 — Versioned-duplicate policy** (when many `-v1…vN` files exist):
> "10 files match `paper-v{1..10}.md`. Keep the full version history, or collapse?"
> options:
> - [Keep — versions matter]
> - [Keep latest only — delete v1..v9]
> - [Move old versions to an archive/ subfolder]

**Archetype 3 — Large file disposition** (when >1MB files tracked without LFS):
> "3 PDFs over 2MB each are tracked in git. Move to git-lfs, exclude, or keep?"
> options:
> - [git-lfs]
> - [Exclude via .gitignore — don't track]
> - [Keep as-is]

Free-text fallback always available. Hard cap: 3 questions.

### 4. Produce the disposition table

One row per concrete finding. No silent drops. Dispositions are **recommendations, not actions** — nothing is deleted by this skill.

```markdown
## Findings

| # | Finding | Disposition | Reason | Action |
|---|---------|-------------|--------|--------|
| 1 | 19 paper drafts `docs/paper-multiagent-v{1..10}.md` + PDFs | **Move** | Scope drift — TS library repo shouldn't host papers (per user answer) | Create separate `multiagent-paper` repo; `git rm --cached docs/paper-*`; add `docs/paper-*` to `.gitignore` |
| 2 | `.DS_Store` tracked in 3 locations | **Gitignore** | macOS artifact, not project content | `git rm --cached **/.DS_Store`; ensure `.DS_Store` in `.gitignore` |
| 3 | `dist/` committed (14 files) | **Gitignore** | Build output | `git rm --cached -r dist/`; ensure `dist/` in `.gitignore` |
| 4 | `hildebrandt-multiagent-v9.pdf` (2.8MB), `-v10.pdf` (3.1MB) untracked | **Exclude** | Large binary outputs of papers; shouldn't be tracked | Add `docs/*.pdf` to `.gitignore` |
| 5 | `src/ui/lib/nanostores.ts` (231 lines) duplicates `node_modules/nanostores` | **Keep** | Intentional local vendor per project convention (check CLAUDE.md) | None — flagged for awareness only |

## Proposed .gitignore additions

```
docs/paper-*
**/.DS_Store
dist/
docs/*.pdf
```

## Proposed next commands (for user to run)

```bash
git rm --cached **/.DS_Store
git rm --cached -r dist/
git rm --cached docs/paper-*.md docs/paper-*.pdf docs/make_pdf.py docs/keep-table-with-caption.lua docs/paper-style.css
# After updating .gitignore:
git add .gitignore
git commit -m "tidy: exclude scope-drift files, build artifacts, macOS noise"
```
```

### 5. Stop

Do **not** execute destructive actions automatically. Output the proposed commands; the user runs them. If the user explicitly says "go ahead and apply," execute one command at a time, confirming each bulk `git rm` before running.

## Anti-patterns (refuse these)

- Auto-running `git rm`, `rm`, or modifying `.gitignore` without explicit user approval on the proposed action list
- Vague findings without file paths ("repo has some clutter")
- Findings that don't specify a disposition
- Marking things for deletion based on guesses about user intent — ask via AskUserQuestion when unsure
- Over-flagging — if a signal has 1–2 items and they're not obvious drift, omit the signal entirely
- Running expensive scans (AST parsing, full file reads, test runs) — this skill must stay sub-second for signals
- Flagging `node_modules/`, `.git/`, or files already in `.gitignore` — filter these out of the report
- Filing a finding that overlaps with another skill's domain (code quality → tech-debt; secrets → scanner)

## Worked example (calibration — not a template)

*Repo:* a TypeScript library for multi-agent conversations (inferred from `package.json` name + README first paragraph).

*Cheap signals found:*
- 19 untracked files in `docs/` with extensions `.md`, `.pdf`, `.html`, `.css`, `.lua`, `.py`
- 10 of them match versioned-duplicate regex: `paper-multiagent-v{1..10}.md`
- 2 PDFs over 2MB
- No tracked files match `.gitignore` patterns (clean)
- `.git/` is 45MB (not flagged — under threshold)

*Question asked (1 of 3):* Archetype 1 — scope confirmation. User answered "No — they should move to a separate repo."

*Disposition table produced:* 4 findings (scope drift, versioned duplicates collapsed into one finding, large PDFs, PDF tooling). 0 findings for tracked ignore-pattern matches (signal was empty — omitted).

*Commands proposed:* `git rm --cached` for any tracked paper files (none — they were untracked), `.gitignore` additions, suggestion to create separate repo.

*User ran the commands manually.* Skill did not execute anything.

## Edge cases

- **No README / no manifest** — ask one question to establish repo purpose, then proceed.
- **Monorepo** — run intake per top-level package; findings are per-package. Flag extension-mismatch only against the owning package's manifest.
- **Repo intentionally hosts mixed content** (e.g., a personal notes + code repo) — respect the user's answer in Archetype 1; omit scope-drift findings entirely.
- **`.git/` > 1GB** — flag separately; recommend `git-sizer` for deep analysis, don't attempt it inline.

## Reporting issues with this skill

If a finding was wrong, a disposition didn't fit, or the scope inference misread the repo, offer the user to file a GitHub issue via `gh issue create --repo michaelhil/claude-toolbox`. Include: the repo type, the finding that was off, and why the recommendation didn't fit. Aggregate multiple session observations into one issue where possible.
