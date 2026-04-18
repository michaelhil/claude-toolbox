# claude-toolbox

A portable, reusable Claude Code plugin bundling skills and commands that improve daily coding sessions. Install once per project; everything auto-triggers from natural language.

## What's in it

| Item | Type | Triggers on | What it does |
|------|------|-------------|--------------|
| **catch-up** | Skill | "catch me up", "resume", "what was I doing", "audit this project", "I'm back" | Audits recent git activity, in-flight work, TODOs, and CLAUDE.md drift. Asks up to 3 clarifying questions. Produces a brief (including hygiene signal counts) and writes it to `.claude/context/last-session.md` for next time. Points at `tidy` and `engineering:tech-debt` for deeper dives. |
| **sdd** | Skill | "plan this feature", "how should we approach X", "design the Y feature", `/plan` | Spec-driven development: idea → spec → phased plan → task list. Asks up to 2 clarifying questions on scope. Pairs with stress-test for review. |
| **stress-test** | Skill | "stress-test this plan", "review this before I build", "poke holes in this", "what's wrong with this plan", "red-team this" | Adversarial review of a coding plan across five axes (correctness, project fit, simplicity/bloat, refactor opportunities, tech debt). Asks clarifying questions inline. Returns a revised plan with finding-disposition table and changelog. |
| **tidy** | Skill | "tidy", "clean up this repo", "repo hygiene", "what should I clean up", "audit file scope" | Repo hygiene audit — scope drift, versioned duplicates, tracked build artifacts, large files, untracked sprawl. Asks up to 3 clarifying questions. Produces a disposition table (keep / gitignore / move / delete / extract-to-separate-repo) + proposed commands. Never auto-applies destructive actions. |
| **/plan** | Command | Manual: `/plan <feature description>` | Explicit invocation of the sdd skill when auto-trigger isn't firing. |

## Why use it

- **No tools to remember.** Skills auto-trigger from natural phrasing. The agent picks them up; you don't memorize names.
- **Human-in-the-loop by design.** Every skill uses `AskUserQuestion` with clickable multiple-choice options at ambiguity points — so you steer without re-typing, and the agent doesn't guess wrong.
- **One install per project.** `/plugin install` and done. No per-project configuration.
- **Plan–critique loop built in.** SDD produces plans → stress-test critiques them → you approve → implement. No second install.

## Install (once, globally)

The plugin installs at **user scope** — once installed, skills auto-apply in every project without further setup.

**From inside Claude Code (slash commands):**
```
/plugin marketplace add michaelhil/claude-toolbox
/plugin install claude-toolbox@claude-toolbox
```

**From a terminal (agent-friendly):**
```bash
claude plugin marketplace add michaelhil/claude-toolbox
claude plugin install claude-toolbox@claude-toolbox
```

**Restart Claude Code** after install so skills are picked up by the session.

**To update:**
```bash
claude plugin update claude-toolbox@claude-toolbox
# or inside Claude Code:
/plugin marketplace update claude-toolbox
```

## Skills vs. commands — how to invoke

- **Skills** (catch-up, sdd, stress-test, tidy) auto-trigger from natural language matching their description. Just say what you want — `"catch me up"`, `"plan the login feature"`, `"stress-test this plan"`, `"tidy this repo"`. Do **not** type `/catch-up` — that's not a slash command.
- **Slash commands** (`/plan`) are typed explicitly. Only `/plan` is a slash command in this plugin.

## Example: daily use

Morning, returning to a project after a week away:

> **You:** "I'm back on this project, catch me up."
>
> *(agent runs git intake silently)*
>
> **Agent (AskUserQuestion):** "Uncommitted changes in `src/agents/human.ts`. Resume or abandon?"
> **You:** *click "Resume — mid-feature"*
>
> **Agent:** Produces a brief showing current focus, in-flight work at specific file:line, what changed in the last 14 commits, 3 open TODOs cited concretely, and a single concrete next step. Writes it to `.claude/context/last-session.md`.

Then, before writing new code:

> **You:** "Let's plan the thinking-mode toggle feature."
>
> *(sdd auto-triggers)*
>
> **Agent (AskUserQuestion):** "Expose via UI toggle, CLI flag, or both?"
> **You:** *click "Both"*
>
> **Agent:** Returns spec + plan + tasks. Reminds you: "Run stress-test on this before implementing."

> **You:** "Stress-test it."
>
> *(stress-test skill auto-triggers — bundled in this plugin)*
>
> **Agent:** Runs the adversarial review. Asks clarifying questions inline. Returns a revised plan with finding-disposition table and a what/why/how changelog.

## Use cases

- **Returning to a project** after any gap → `catch-up`
- **Starting a new feature** → `sdd` via natural ask or `/plan`
- **Before committing to a plan** → `stress-test` via natural ask ("stress-test this", "poke holes in this plan")
- **Repo feels cluttered / wrong files in the repo** → `tidy`
- **Code-quality audit** → not bundled; use the built-in `engineering:tech-debt` skill
- **Multi-project developer** who wants consistent workflow across repos → install once, globally

## How the skills relate

```
catch-up  ──▶  surfaces hygiene signals ──▶  hand off to  tidy  (for action)
catch-up  ──▶  surfaces debt signals    ──▶  hand off to  engineering:tech-debt
sdd       ──▶  drafts plan              ──▶  hand off to  stress-test  (for critique)
```

Each skill stays narrow and fast. Deep dives live in their own skill, invoked explicitly.

## Companion tools (not bundled; install separately)

- **Claude Code LSP plugin** (e.g. `Piebald-AI/claude-code-lsps`) — background typecheck diagnostics. Strongly recommended for TypeScript projects.
- **RTK, Context Mode MCP** — token-reduction tools. Install only if `/context` baseline shows they'd help.

## About the bundled stress-test skill

The `stress-test` skill here is a pinned snapshot of [michaelhil/stress-test-skill](https://github.com/michaelhil/stress-test-skill) — the standalone repo remains the canonical source. The pin (short SHA) is recorded at `skills/stress-test/.upstream-pin`.

To pull in upstream changes before a claude-toolbox release:

```bash
scripts/sync-stress-test.sh           # re-copy at the currently pinned ref
scripts/sync-stress-test.sh main      # pick up upstream HEAD
scripts/sync-stress-test.sh v0.3      # pin to a specific tag/SHA
```

Review the diff, update `.upstream-pin` and `plugin.json` version, commit. Bundled users get new stress-test behaviour only when a new claude-toolbox version ships — upstream changes don't propagate automatically.

## How it fits with CLAUDE.md and memory

- **CLAUDE.md** — static project rules. catch-up reads it as part of intake; doesn't replace it.
- **Auto-memory** (`~/.claude/projects/<proj>/memory/`) — persistent user/project facts. catch-up reads the index if available but the handoff file in `.claude/context/last-session.md` is the primary anchor.
- **`.claude/context/last-session.md`** — per-repo, per-session handoff; written by catch-up; gitignored by default.

## Maintenance and feedback

This toolbox improves by use. If you hit a bug, a skill fires when it shouldn't (or doesn't fire when it should), or you see an opportunity to simplify — **file a GitHub issue**.

Each skill includes an instruction to the coding agent to **offer to file an issue** when it encounters a rough edge during use. If the agent offers, accept or decline; the agent will only file after you agree.

When filing manually or via the agent, include:

1. **What happened** — skill name, trigger phrasing used, expected behavior
2. **What the skill produced** — paste the relevant output (redact sensitive bits)
3. **What would have been better** — concrete, ideally with an improvement proposal
4. **Context** — project type, language/runtime if relevant

Issues: <https://github.com/michaelhil/claude-toolbox/issues>

Templates are provided under `.github/ISSUE_TEMPLATE/`.

## Structure

```
claude-toolbox/
├── .claude-plugin/
│   ├── plugin.json           plugin manifest
│   └── marketplace.json      marketplace manifest (this repo is its own marketplace)
├── skills/
│   ├── catch-up/
│   │   ├── SKILL.md
│   │   └── references/checklist.md
│   ├── sdd/
│   │   └── SKILL.md
│   ├── stress-test/
│   │   ├── SKILL.md
│   │   ├── references/axes-checklist.md
│   │   └── .upstream-pin     SHA pinning the bundled snapshot
│   └── tidy/
│       └── SKILL.md
├── commands/
│   └── plan.md               /plan slash command
├── scripts/
│   └── sync-stress-test.sh   re-sync stress-test from upstream
├── .github/ISSUE_TEMPLATE/   bug + improvement templates
├── LICENSE                   MIT
└── README.md                 this file
```

## License

MIT
