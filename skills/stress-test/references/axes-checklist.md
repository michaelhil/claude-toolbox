# Axes Checklist

Concrete prompts for step 4 of the stress-test flow. The prompts inform each axis pass — they are *not* a requirement to produce one finding per prompt. Walk each axis once; surface findings where they exist, explicitly pass otherwise. A finding must name a concrete plan element (file, step, decision) — no vague complaints.

## 1. Correctness & consistency
- Are the steps correct in the order given? Any step that depends on a later step?
- Edge cases missed: empty inputs, concurrent callers, partial failures, retries, timeouts, cancellation
- Wrong assumptions about third-party APIs, file system behavior, timing, or ordering
- Race conditions or shared-state hazards
- Steps inside the plan that contradict each other
- Claims in the plan that aren't supported by the code you just read
- **Verifiability**: is there a plain way to tell the change worked — a script to run, a log line to check, a before/after comparison? Match the rigor to the project; don't demand production-grade test suites where a smoke check is enough.

## 2. Fit with the existing project
*Before passing this axis: if the plan doesn't name specific files, grep for the affected subsystem and read a representative neighbor. Fit cannot be assessed without looking at surrounding code.*

- Does the plan match existing patterns (module layout, naming, error handling, async style)?
- Does it respect CLAUDE.md rules (language choice, server policy, style conventions, dependency policy)?
- Does it introduce a pattern that conflicts with neighboring code?
- Does the plan's abstraction level match the rest of the codebase?
- Would a future reader find the result consistent with its surroundings, or jarring?

## 3. Simplicity & bloat
*Scope: what the plan adds. Cleanup of existing code belongs in axis 4.*

- New files added with only one caller
- New dependencies — is each load-bearing, or could existing code cover it?
- New config flags, feature flags, env vars — is each actually used by something concrete now?
- New abstractions (interfaces, factories, wrappers) — count real call sites; flag any with fewer than 2
- Speculative generality: parameters/options that no current caller needs
- Is there a materially simpler approach that achieves the same outcome?

## 4. Refactor opportunities
*Scope: existing code the plan touches or reveals. Additions the plan makes belong in axis 3.*

- **In-scope adjacent cleanup**: code the plan touches that should be cleaned up in the same PR. For each: what, why, approximate size.
- **Out-of-scope adjacent cleanup**: code that's tempting to clean up but should be deferred. For each: why deferring is correct.
- Dead code that the plan's changes make removable now
- Naming that becomes wrong after the change and should be updated in the same PR
- Duplication the plan is about to extend — worth collapsing first?

## 5. Tech debt
- Debt paid by this plan (name it)
- Debt newly introduced: TODO markers, shortcuts, missing tests, `any` types, silent catches. Is each justified?
- Debt the plan visibly touches but leaves in place — should it be addressed here?
- Migration or deprecation debts the plan could reasonably include without scope creep
