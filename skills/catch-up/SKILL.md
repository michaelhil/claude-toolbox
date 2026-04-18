---
name: catch-up
description: Resume a project after a break. Audits recent git activity, in-flight work, untracked files, TODOs, and divergence from CLAUDE.md, asks up to 3 clarifying questions inline via AskUserQuestion, and produces a compact brief that gets the coding agent up to speed. Writes a handoff file to .claude/context/last-session.md so future sessions have an anchor. Use whenever the user asks to catch up, resume, audit the project, pick up where they left off, re-enter, onboard the agent, review project status, or says "what was I doing" — even implicitly ("I'm back", "where are we", "remind me where we were"). Skip for fresh project bootstrap (use /init instead) and for plan critique (use stress-test instead).
---

# Catch-Up: Returning-Developer Project Audit

Apply this skill when a developer returns to a project and the coding agent needs to reconstruct current goals, in-flight work, and open problems before writing any code.

## Flow

### 1. Silent intake (no questions yet)

Gather project state in parallel using Bash and Read:

- `git log --since="3 weeks ago" --oneline --all` — recent commits across branches
- `git branch -a` and `git stash list` — branches and stashes
- `git status --short` — uncommitted and untracked files
- `git diff --stat HEAD~10..HEAD` if <10 commits exist, else last 10 — scope of recent change
- Read `CLAUDE.md` (project root + `.claude/`) and `.claude/context/last-session.md` if present
- Grep recent diffs for `TODO|FIXME|XXX|HACK` added in the last 2 weeks
- If a typecheck or test command is obvious from `package.json` scripts, note it — do not run it yet

Do **not** spawn Explore subagents. This is a shallow scan, not a code read.

### 2. AskUserQuestion clarification (cap: 3)

Skip any question whose answer is obvious from intake. Skip the step entirely if nothing is ambiguous.

**Rules (inherited from stress-test-skill):**
- Use the **AskUserQuestion tool**, never free-text. The user wants clickable options.
- 2–4 suggested options per question, plus a free-text fallback.
- Hard cap: 3 questions across the whole audit. If ambiguity remains, raise it as "assumes X; flag if wrong" in the brief.
- Only ask questions that materially change the brief or the suggested next step.
- Never ask what git log already answered.

**Question archetypes** (use as patterns; phrase with concrete project evidence):

- *Focus clarification* — when recent activity spans multiple areas:
  > "I see N commits on `<branch>` plus uncommitted changes in `<path>`. What's the focus now?"
  > options: [continue feature on branch] [work in uncommitted area] [something else — describe] [just exploring]

- *In-flight disposition* — when uncommitted or stashed work is unclear:
  > "Uncommitted changes in `<file>` (N insertions). Resume or abandon?"
  > options: [resume — mid-feature] [abandon — safe to discard] [review with me first]

- *TODO triage* — when many recent TODOs cluster around a theme:
  > "Three TODOs added in the last week mention `<theme>`. Real follow-ups or placeholders?"
  > options: [real — track as open problems] [placeholder — ignore] [mixed — I'll clarify]

### 3. Produce the brief

Return this exact structure inline to the user. Every bullet must cite a concrete file, path, or commit — or explicitly pass ("nothing to flag"). No vague filler, no rubber-stamp summaries.

```markdown
## Current focus
<one line grounded in user answer + code evidence>

## In-flight work
| What | Where | Disposition |
|------|-------|-------------|
| <concrete item> | `<file:line>` or `<branch>` | Resume / Abandon / Needs review |

## Changed since last session
| What | Why | How to apply |
|------|-----|--------------|
| <concrete change> | <reason from commit/diff> | <how it affects next work> |

## Open problems
- `<file:line>` — <concrete issue, cited>
- (or: "nothing to flag")

## Suggested next step
<one concrete action — not a menu>
```

### 4. Persist handoff

Write the brief to `.claude/context/last-session.md`, overwriting any existing file. Prepend a timestamp header: `# Last session — YYYY-MM-DD HH:MM`.

On first write in a repo:
- Check if `.claude/context/` is covered by `.gitignore`. If not, append `.claude/context/` to the repo's `.gitignore` (create one if absent). Tell the user you did this.

Do not commit these files.

### 5. Stop

Hand control back. Do **not** start implementing the suggested next step — that is a separate invocation.

## Anti-patterns (refuse these)

- Rubber-stamp "project looks healthy" with no specifics
- Re-listing CLAUDE.md content the user already wrote
- Restating the user's own stated focus back at them
- Vague open problems ("some cleanup needed", "tests could be better")
- Free-text clarifying questions instead of AskUserQuestion
- Asking more than 3 questions
- Spawning Explore subagents — stay in main context
- Running the test suite, type-check, or build as part of the audit — too slow, not the point. Note the command for the user if they want it.
- Auto-implementing the suggested next step without a fresh go-ahead

## Worked example (calibration — not a template)

*Intake found:* 14 commits on `master` since last session, uncommitted edits in `src/agents/human.ts`, 3 TODOs added mentioning "circuit breaker", no existing `.claude/context/last-session.md`.

*Question asked (1 of 3, then stopped):*
> "Uncommitted changes in `src/agents/human.ts` — resume or abandon?"
> options: [resume — mid-feature] [abandon — safe to discard] [review with me first]

User answered: resume.

*Brief produced:*

```markdown
## Current focus
Finishing human-agent lifecycle fixes (session-token restore, disconnect cleanup) in src/agents/human.ts.

## In-flight work
| What | Where | Disposition |
|------|-------|-------------|
| Session token restore on reconnect | src/agents/human.ts:142 | Resume |
| Cleanup on disconnect | src/agents/human.ts:210 | Resume |

## Changed since last session
| What | Why | How to apply |
|------|-----|--------------|
| Typed Ollama errors landed (fc5fe25) | Circuit breaker + retry needed typed errors | Error UX now goes through typed paths — reuse in human-agent error handling |
| Thinking indicator fixes (0de0800, fb37d34) | Phase label broke on room re-entry | Check that human-agent reconnect doesn't re-trigger the same bug |

## Open problems
- src/agents/human.ts:210 — TODO "circuit breaker needed for disconnect storms"
- src/core/rooms/registry.ts:88 — TODO "handle stale token on reconnect"

## Suggested next step
Implement the disconnect-cleanup branch in src/agents/human.ts:210 — the typed-error work from fc5fe25 unblocks it.
```

Brief was also written to `.claude/context/last-session.md`. `.claude/context/` was added to `.gitignore`.

## Edge cases

- **No git history**: note it, skip sections that depend on git, base brief on CLAUDE.md + file tree.
- **No CLAUDE.md**: suggest `/init` at the end, don't run it yourself.
- **Existing last-session.md**: read it first and include a "Since last catch-up" mini-section only if materially different.
- **Very large recent diff (>50 commits)**: sample — last 20 + earliest 5 of the window — and tell the user you sampled.
- **Multiple active branches**: list each with a one-line status; ask which is the focus (counts as 1 of 3 questions).

## Reporting issues with this skill

If you encounter a bug, a wrong assumption, or an opportunity to improve this skill during use, offer the user to file a GitHub issue. Use `gh issue create` on `michaelhil/claude-toolbox` with:

- **Title**: one-line summary
- **Body**: what happened, what you expected, concrete reproduction context (redact anything sensitive), and a proposed improvement if you have one

Only file after the user agrees. Do not file trivially — aggregate multiple observations from one session into a single issue where possible.
