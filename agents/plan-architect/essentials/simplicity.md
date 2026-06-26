# Simplicity Discipline

Every plan emitted by `plan-architect` is the **simplest plan that fully satisfies the SRS/SDD and approved findings** — not the most thorough one imaginable. A plan is where complexity enters the system: a speculative abstraction or extra layer named in a task becomes code a developer is obligated to build, so removing it here is the cheapest point in the pipeline to prevent it.

The governing rule: **add structure only when a present requirement demands it.** Complexity must be pulled by a documented need, not pushed in anticipation of one.

## A. No speculative structure (YAGNI)

Do not plan abstractions, base classes, generic utilities, interfaces, config options, feature flags, or extension points the SRS/SDD does not call for. "We might later need…" is not a planning input — the future phase that needs the structure will plan it then, at low cost.

## B. Rule of Three for shared code

Do not plan a shared utility, helper, or abstraction until three real consumers exist — across the codebase (verified via Grep/Glob) or demanded by the spec. With two or fewer, prefer in-place implementation; a small amount of duplication is cheaper to maintain than the wrong abstraction. Within-feature reuse is expressed through REUSE/EXTRACT directives against code that already exists, not by inventing a shared layer for a feature's first use. A new cross-file abstraction reaches a plan only as an already-approved finding in a refactor plan — choosing one soundly requires call-site analysis across the whole codebase, which the planning stage does not perform.

## C. Fewest moving parts

Among equally-correct alternatives, prefer the plan with fewer phases, fewer new files, fewer layers, and fewer new dependencies. A new file, service, queue, or datastore in a task must trace to an SDD decision that justified it; do not introduce one the design did not call for.

## D. Least complexity when complexity is required

Some requirements are genuinely complex (a state machine, a transaction boundary, a migration). When the requirement demands it, plan the *least* complexity that meets it — the simplest correct decomposition, not the most defensive one. Make the necessity legible: the phase or task should make clear *which requirement* forces the complexity, so a reviewer can see it was pulled, not pushed.

## E. Why this matters

Smaller plans produce smaller, more secure, more maintainable code: less surface area, fewer paths to test, fewer places for a defect to hide. Over-planning forces downstream over-engineering, because the developer builds what the plan names.

These rules apply to every target (`feature-draft`, `feature-final`, `test-plan`, `refactor-plan`, `deviation`). They constrain what the plan asks for; they do not relax the structural rules in `writing-discipline.md`.
