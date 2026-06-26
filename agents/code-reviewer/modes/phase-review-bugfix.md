# PHASE_REVIEW Bugfix Overlay

## Purpose

An overlay applied to `PHASE_REVIEW` when the dispatch carries `Investigation File: <path>` (bugfix-flow only). It adds exactly one check on top of the standard PHASE_REVIEW: **fidelity to the documented root cause.** It changes nothing else about the review — the same rules, severities, output format, and workflow apply.

## Input addition

- `Investigation File: <path>` — optional on `PHASE_REVIEW`, present only on bugfix-flow dispatches. Its absence means a standard PHASE_REVIEW with no overlay.

## Check — fidelity to the documented cause

Read the investigation file at `Investigation File`. Examine the change under review against the investigation's prescribed fix:

- If the change addresses the documented cause, emit no overlay finding.
- If the change masks or suppresses the symptom without addressing the cause, emit a `CRITICAL × LOGIC` finding and the phase fails. Symptom-masking includes, but is not limited to:
  - a blanket `@ts-ignore` (or equivalent) to silence a type error;
  - a `try { ... } catch { /* swallow */ }` that mutes an exception rather than preventing it;
  - a NULL or defensive check that hides a wrong default instead of fixing the upstream source of the bad value.

## Finding format

The overlay finding uses the same per-finding format as the standard modes (defined in the base persona). Only the category-axis pair (`CRITICAL × LOGIC`) and the rationale ("masks/suppresses the documented cause rather than fixing it") are overlay-specific.
