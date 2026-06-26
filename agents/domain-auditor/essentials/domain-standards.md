# Domain Standards

Canonical definitions referenced by step files during validation.

---

## Reviewer Posture

Apply these standards like an adversarial reviewer: strict, by-the-book, and actively hunting for violations rather than rationalizing the pack into compliance. Default to doubt. Grant no benefit of the doubt on paraphrased content, unverified cross-references, or claims that rest on what "used to be" true about the codebase. If a rule could plausibly apply to a section and you have not checked it, check it. Borderline findings get surfaced, not absorbed on the pack author's behalf.

Rigor here means coverage — every loaded standard checked against every pack section and every cross-reference. Rigor does **not** mean inventing staleness the pack does not exhibit, inflating severities above what this file specifies, or fabricating drift the tools cannot prove.

**LOW-confidence codebase-drift claims are dropped, not downgraded to WARNING.** Soft drift findings create noise that looks authoritative; the pack author has no lint or build to independently verify them, so a false positive sticks until a human chases it down. If you cannot reach HIGH or MEDIUM confidence on a drift claim after one re-investigation, drop it.

Advisory status (the auditor cannot block creation) does not change rigor — it only changes what happens with the findings. Coverage stays the same; severities stay calibrated to the rules in this file.

---

## 1. Severity Definitions

| Severity | Code | Definition | Action Required |
|----------|------|------------|-----------------|
| **CRITICAL** | `[CRITICAL]` | Prevents domain from functioning correctly | Must fix before use |
| **ERROR** | `[ERROR]` | Violates standards, may cause issues | Should fix |
| **WARNING** | `[WARNING]` | Suboptimal but functional | Consider fixing |
| **INFO** | `[INFO]` | Suggestion for improvement | Optional |

**Overall Status Determination:**
- **PASS**: No CRITICAL or ERROR issues
- **WARNINGS**: No CRITICAL/ERROR but has WARNING issues
- **ISSUES FOUND**: Has CRITICAL or ERROR issues

---

## 2. Confidence Definitions

Every finding carries a Confidence value. The self-check step assigns it; LOW-confidence findings are re-investigated once and either lifted to HIGH/MEDIUM or dropped.

| Confidence | When to Assign |
|------------|----------------|
| **HIGH** | A direct quote from the pack plus a tool-verified discrepancy (Grep result, Read excerpt) that proves the violation. Required for any factual-drift claim. |
| **MEDIUM** | A structural issue confirmed by tool output: a missing required section confirmed by Read, an empty/`TBD`-only section confirmed by Read, a broken cross-reference confirmed by Glob, an orphan term confirmed by Grep. |
| **LOW (drop)** | Stylistic critique, "this could be clearer" calls, or any drift claim resting on assumption rather than tool output. Dropped unless one re-investigation lifts it. |

---

## 3. Evidence Standards for Codebase-Drift Findings

Drift findings are the easiest to hallucinate, so the bar is highest:

1. **Specific identifier required.** A drift finding (the pack claims X about the codebase; the codebase shows Y) is only reportable when the pack cites a **specific named identifier** — a function, class, file path, flag, env var, or table name — that fails to resolve via Grep or Glob.
2. **Conceptual paraphrases are not drift.** When the pack says "the credit service validates balance before deducting" and a Grep for `validates balance` returns nothing, that proves nothing — the concept may exist under different wording. Conceptual-claim drift is LOW confidence and dropped.
3. **Direct pack quote required.** Every drift finding must include the verbatim sentence from the pack so the reader can verify the claim was actually made.
4. **Tool output required.** Every drift finding must include the Grep or Read result (or its absence) that establishes the discrepancy.

---

## 4. Defect Classes (illustrative)

These are not a closed taxonomy and are not required category labels on findings. They illustrate the kinds of defects the adversarial posture is meant to catch:

- **STALE-REFERENCE** — pack cites a function/file/class that has been renamed or removed (Grep proves absence).
- **FACTUAL-DRIFT** — pack claims the codebase uses approach X for a specific identifier; tool output shows approach Y for that identifier.
- **BROKEN-CROSS-REFERENCE** — pack references another pack, file, or section that does not exist (Glob/Read confirms).
- **ORPHAN-TERM** — pack introduces a term in a glossary or definition section but that term is never used elsewhere in the pack (Grep confirms).
- **INCOMPLETE** — required section is titled but empty or contains only `TBD`.
- **RESTATEMENT** — paraphrased content adds no structure, insight, or actionable detail beyond the source it paraphrases.

Severity for each instance is calibrated against the existing severity rules in the step files (e.g., a missing required section in step 2 is the severity that step 2 specifies, not a severity invented for "INCOMPLETE").

---

## 5. Convention Quality Criteria

Every convention MUST be specific, actionable, and verifiable. An auditor should be able to write a pass/fail rule for each convention.

| Criterion | What to Check | Severity if Failed |
|-----------|---------------|---------------------|
| Specific | Names a concrete artifact, format, or pattern | WARNING |
| Actionable | Describes what to do, not just what to be | WARNING |
| Verifiable | Could be checked by grep/glob/read | WARNING |

**GOOD conventions:**
- "All API endpoints must include rate-limiting middleware"
- "File names use kebab-case with `.handler.ts` suffix"

**BAD conventions:**
- "APIs should be well-designed" (subjective)
- "Use good naming conventions" (vague)
- "Follow best practices" (unmeasurable)
