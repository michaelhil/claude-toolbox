---
name: sdd
description: Spec-driven development for a new feature or change — turns a rough idea into a written spec, a phased plan, and a task breakdown before any code is written. Asks clarifying questions inline via AskUserQuestion when requirements, scope, or acceptance criteria are ambiguous. Produces artifacts the stress-test skill can critique and the user can approve. Use when the user asks to plan, design, spec, or break down a feature — even implicitly ("how should we approach X", "what's the plan for Y", "let's design the Z feature"). Skip for single-file edits, bug fixes with an obvious cause, and work already mid-implementation.
---

# SDD: Spec-Driven Development

Apply this skill when a new feature or non-trivial change needs shape before code. Output three artifacts: **spec**, **plan**, **tasks**. Each feeds the next. Keep them short — SDD that produces 20-page specs defeats the point.

## When NOT to use

- Single-file edits or renames — just do it.
- Bug fixes where the cause is already localized — use debug or fix directly.
- Work where a plan is already in context — run stress-test on the existing plan instead.
- Exploratory "what could we do about X" conversations — answer in 2–3 sentences first; only invoke SDD if the user then says "ok, let's plan it".

## Flow

### 1. Scope check

Read any context already in the conversation (CLAUDE.md, prior messages, files the user named). Do not re-fetch what you already have.

If the user's ask is one sentence with no detail, ask one **AskUserQuestion** to clarify the outcome before proceeding. Example:

> "What outcome does this feature need to produce?"
> options: [user-visible UI change] [new API/endpoint] [internal refactor enabling future work] [other — describe]

### 2. Draft the spec (short)

Target: ~150 words. Headings:

```markdown
# Spec: <feature name>

## Goal
One sentence. The user-observable or system-observable outcome.

## Non-goals
Bulleted. What this explicitly does *not* do — prevents scope creep.

## Acceptance criteria
Bulleted, verifiable. "User can X", "Endpoint returns Y under Z", "No regression in W".

## Constraints
CLAUDE.md rules, existing architecture, runtime (Bun/Node), language (TypeScript-only), dependencies allowed/forbidden.
```

### 3. AskUserQuestion — spec confirmation (cap: 2 at this stage)

Only ask when a decision in the spec is ambiguous *and* would materially change the plan. Skip otherwise. Examples of decisions worth asking:

- Scope boundary: "Does this include migration for existing data, or only new?"
- Runtime surface: "Expose via HTTP endpoint or MCP tool?"
- Backwards-compatibility: "Preserve the old path, or remove it?"

Use 2–4 options + free-text fallback.

### 4. Draft the plan

Target: ~200 words. Phased. Each phase must be independently verifiable.

```markdown
# Plan: <feature name>

## Phase 1 — <name>
- What: <concrete change>
- Where: `<file or directory>`
- Verify: <how the user confirms this phase works before moving on>

## Phase 2 — <name>
...

## Risks
- <concrete risk> — <mitigation>
```

**Constraints on the plan:**
- Every phase names specific files or directories — no vague "update relevant code".
- Every phase has a verify step — no "trust me it works".
- No speculative abstractions. If a config flag or options object has no current caller, drop it.
- Honor CLAUDE.md project rules (single server, TypeScript-only, no mocks without approval, etc.).

### 5. Task breakdown

Target: one line per task. 5–15 tasks total for a typical feature. Each task should be completable in under ~30 minutes.

```markdown
# Tasks: <feature name>

- [ ] <specific action> in `<file>`
- [ ] <specific action> in `<file>`
...
```

### 6. Hand off

Output the three artifacts inline, in order: spec → plan → tasks. Tell the user: "Run `stress-test` on this before implementing." Do not start implementing.

## Pairing with stress-test-skill

SDD and stress-test are complementary, not overlapping:
- SDD *creates* the plan.
- stress-test *attacks* the plan.

A healthy workflow for non-trivial features: `/plan` (invokes SDD) → review inline → invoke stress-test → apply revisions → implement.

## Anti-patterns (refuse these)

- 20-page specs — short is the whole point
- Plans without verify steps per phase
- Plans that introduce speculative config flags or abstractions with no current caller
- Task lists that are actually phase lists (too coarse)
- Starting implementation inside the skill
- Re-fetching files already in conversation context
- Asking more than 2 questions in step 3

## Edge cases

- **Feature touches multiple repos** — produce one spec per repo but a single plan with cross-repo phases.
- **Existing partial implementation** — spec + plan must account for it; plan phase 1 is usually "audit and decide what to keep".
- **User pushes back on a phase** — revise, don't restart. Re-emit only the phases that changed.

## Reporting issues with this skill

If you hit a rough edge — a question archetype that doesn't fit, a template that produces bloat, a place where SDD should have been skipped — offer the user to file a GitHub issue on `michaelhil/claude-toolbox` via `gh issue create`. Include: what the skill produced, what would have been better, and a concrete improvement proposal. Only file after the user agrees.
