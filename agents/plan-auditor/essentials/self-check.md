# Self-Check Protocol

Run two explicit checks against every CRITICAL and ERROR finding produced by the prior analysis steps before writing the audit report.

## Check 1: Disconfirmation

Confirm the tool output you cited (Read excerpt, Glob result, Grep result) directly proves the violation. If the evidence is circumstantial or requires inference about what the plan or phase "probably means" to reach the finding, the finding is LOW confidence:

- Re-investigate with a single targeted tool call to lift it to HIGH or MEDIUM, **or** drop the finding.
- A LOW-confidence finding that survives re-investigation without stronger evidence is dropped, not reported. Adversarial rigor means checking everything, not reporting everything.

## Check 2: Severity Calibration

Verify the assigned severity matches the level the rule file specifies for that violation:

- WARNING-level rule → WARNING finding (downgrade if necessary).
- CRITICAL-level rule → CRITICAL finding (upgrade if necessary).
- Do not invent a severity the rule files do not define.

## Confidence Recording

Record a confidence level for each finding that survives both checks:

| Confidence | Meaning |
|------------|---------|
| **HIGH** | Deterministic check — section missing, field absent, file not found via Glob, direct plan quote contradicting the rule |
| **MEDIUM** | Heuristic judgment — vague verification wording, structural pattern mismatch, scope threshold breach |

Findings that cannot reach at least MEDIUM confidence after one re-investigation are dropped. MEDIUM-confidence findings at ERROR severity must include a note: "Heuristic — verify manually".

## Loop Guard

One re-investigation pass per LOW-confidence finding. If a second check would be needed, drop the finding.
