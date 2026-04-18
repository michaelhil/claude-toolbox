# Catch-Up Intake Checklist

Load this when running step 1 (silent intake). Run as much as applies, in parallel where independent.

## Git state

- `git log --since="3 weeks ago" --oneline --all` — recent activity across branches
- `git branch -a` — list branches
- `git stash list` — forgotten work
- `git status --short` — uncommitted / untracked
- `git diff --stat HEAD~10..HEAD` (or smaller window if fewer commits) — scope of change
- Note the current branch and whether it's ahead/behind origin

## Repo state

- Read `CLAUDE.md` at repo root
- Read `.claude/CLAUDE.md` if it exists
- Read `.claude/context/last-session.md` if it exists — prior anchor
- Read the memory index if the session has one available

## Work-in-flight signals

- Grep recent diffs for `TODO|FIXME|XXX|HACK` — prefer `git log -p --since="2 weeks ago" -S "TODO"` style, or inspect the latest few commits' diffs
- Untracked files that look substantive (not build artifacts)
- Open branches with unmerged commits (compare to main/master)

## Tooling signals

- `package.json` scripts — note the test/typecheck/build commands, don't run them
- Presence of `bun.lock` vs `package-lock.json` — runtime signal
- Presence of `.claude-plugin/` or `.claude/settings.json` — project-specific tooling

## Hygiene signals (counts only)

Sub-second. Feeds the brief's `Hygiene signals` line. Not findings — just counts.

- `git ls-files --others --exclude-standard | wc -l` — untracked count
- `du -sh . --exclude=.git --exclude=node_modules 2>/dev/null` — repo size
- `git ls-files | awk -F/ '{print $NF}' | sort | uniq -d | wc -l` — duplicate basenames

If any count is non-trivial (untracked >20, duplicates >5, size >500MB), recommend `tidy` in the brief.

## What NOT to do in intake

- Do not run tests or build
- Do not spawn Explore subagents
- Do not read every source file — only the ones explicitly named in recent commits or CLAUDE.md
- Do not ask any questions yet — batch them for step 2
