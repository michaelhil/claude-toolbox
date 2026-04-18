---
name: stress-test
description: Aggressive adversarial review of a coding or implementation plan — finds flaws, inconsistencies, poor fit with the existing project, unnecessary complexity or bloat, missed refactor opportunities, and tech debt. Asks clarifying questions inline via the AskUserQuestion tool when the right tradeoff depends on user intent, then returns a revised plan with a finding-disposition table and a what/why/how changelog. Use whenever the user asks to review, critique, poke holes in, stress-test, red-team, harden, or find flaws in a coding plan — even implicitly ("what's wrong with this plan", "am I missing anything", "review this before I build"). Skip for PR reviews, reviews of already-committed code, bug triage, or non-coding strategy plans.
---

# Stress-Test: Adversarial Coding Plan Review

Apply this skill when a coding plan has just been proposed and the user wants it attacked before implementation.

## Flow

### 1. Scope check
- Is there a plan in context? If not, ask the user to paste or point to it — do not invent one.
- Is the plan partially implemented? Read the relevant files and flag any divergence between plan and code.

### 2. Goal check (conditional)
If the plan's goal is ambiguous, restate it in one sentence and confirm. Otherwise skip — do not waste tokens restating a clear plan.

### 3. Read the code the plan touches
Read the files named in the plan, in the main context. Grep for key symbols only if the plan is vague about locations. Do not spawn an Explore subagent — the reviewer needs to quote specifics.

### 4. Critique along five axes
For each axis, either cite a concrete element of the plan (specific file, step, decision) with the problem and proposed fix, or explicitly pass with one sentence of reasoning. No vague complaints. No "looks good overall" summaries.

1. **Correctness & consistency** — logic errors, missed edge cases, race conditions, wrong assumptions about APIs, internal contradictions within the plan, and basic verifiability (how will the user know it worked?)
2. **Fit with the existing project** — conventions, patterns, CLAUDE.md rules, architectural constraints; does the plan match what's already there
3. **Simplicity & bloat** — *scope: what the plan adds.* Unnecessary files, deps, abstractions, config flags, feature-flag scaffolding, premature generality; is there a materially simpler approach. Cleanup of existing code belongs in axis 4.
4. **Refactor opportunities** — *scope: existing code the plan touches or reveals.* Adjacent cleanup that should happen in the same PR (in-scope) and adjacent cleanup that should *not* (out-of-scope, with reason). Be explicit about both lists. Additions the plan makes belong in axis 3.
5. **Tech debt** — debt paid, debt added, debt ignored

Per-axis concrete prompts live in [references/axes-checklist.md](references/axes-checklist.md). Load that file at the start of step 4.

### 5. Ask clarifying questions inline
Whenever a finding depends on user intent (which tradeoff to make, which style to match, whether to expand scope), ask via the **AskUserQuestion tool**. Rules:
- Use AskUserQuestion, never free-text prompts. The user wants clickable options.
- 2–4 suggested options per question, plus free-text fallback.
- Maximum 5 questions across the whole review (not per axis). If uncertainty remains in later axes after the cap is reached, raise it as inline text inside the finding ("assumes X; flag if wrong"), not as an additional question.
- Only ask questions that would materially change a finding or the revised plan. No questions for the sake of questions.

### 6. Produce the revised plan
After the user answers, return a revised plan containing, in order:

1. **Updated plan** — full, standalone, ready to execute. Do not require the user to reconstruct it from diffs.

2. **Finding-disposition table** — every finding from step 4 appears here with status `accepted` / `mitigated` / `rejected` and a one-line reason. No silent drops.

   | Finding | Disposition | Reason |
   |---------|-------------|--------|
   | ...     | accepted    | ...    |

3. **Changelog** — what changed from the original plan, why, and how.

   | What | Why | How |
   |------|-----|-----|
   | ...  | ... | ... |

**Stop here.** Hand control back to the user. Do not start implementing the revised plan — implementation is a separate invocation.

## Anti-patterns (refuse these)
- Rubber-stamp passes across all axes with no specifics
- Findings that don't cite a concrete plan element
- Silently dropping findings in the revised plan (use the disposition table)
- Restating a clear plan as a steelman when step 2 should have been skipped
- Free-text clarifying questions instead of AskUserQuestion
- Spawning Explore subagents — read in main context
- Attacking a strawman: if you misread the plan, fix the reading and re-critique

## Worked example (calibration — not a template to copy)

*Original plan (summary):* "Add a `/export` endpoint to `server.ts` that dumps the `sessions` table as CSV. Add a new `src/core/export/csvWriter.ts` utility with a configurable delimiter and header-casing options."

*Findings (abbreviated):*

- **Correctness — axis 1.** Plan doesn't say how large `sessions` can get. For >100k rows the CSV build blows memory. *Fix: stream rows via async iterator.* Verifiability: suggest `curl /export | wc -l` against a known row count.
- **Fit — axis 2.** Existing exports in `src/core/api/` use route files with snake_case symbols; the plan proposes camelCase `csvWriter.ts`. Inconsistent.
- **Simplicity — axis 3.** Configurable delimiter and header-casing have no current caller. Speculative generality — drop both until a second caller exists.
- **Refactor — axis 4.** In-scope: `src/core/api/server.ts:142` already has near-duplicate CSV logic for the `audits` endpoint; collapse both into the new utility. Out-of-scope: the broader rewrite of `api/server.ts` route registration — tempting but bigger than this PR.
- **Tech debt — axis 5.** No new debt if the streaming fix lands. Plan as written adds debt (the speculative options).

*Inline question (via AskUserQuestion):* "Collapse the existing `audits` CSV into the new utility in this PR?" → options: yes / no (defer) / other.

*Revised plan:* single streaming `csvWriter` (no options), used by both `/export` and `/audits`, file named to match existing convention.

*Disposition table:*

| Finding | Disposition | Reason |
|---|---|---|
| Streaming for large exports | accepted | prevents OOM |
| File/symbol casing | accepted | matches existing convention |
| Drop configurable options | accepted | no second caller |
| Collapse `audits` duplicate | accepted | per user answer |
| Broader route-registration rewrite | rejected | out of scope for this PR |

Keep findings this concrete in your own reviews.

## Handling edge cases
- **No plan in context**: ask the user to paste or reference it. Do not fabricate.
- **Iteration**: the skill is re-invokable. If the user says "review the revision" or re-runs the skill on the updated plan, rerun the full flow.
- **Very large plan**: critique the highest-leverage axes first and tell the user which axes you deferred and why.
