# Step 8: Self-Check Findings

Before compiling the summary, run two checks against every CRITICAL and ERROR finding produced in steps 1–7. This step exists to catch hallucinated drift, paraphrased "this seems off" calls, and severities that drift above what the rules specify.

**Note:** Do NOT write any files in this step. Do NOT return output yet. You are validating findings; step 09 compiles the summary, step 10 writes the report.

## Scope

- **In scope:** every CRITICAL and ERROR finding.
- **Out of scope:** WARNING and INFO findings — pass through unchanged.

## Check A: Disconfirmation

For each in-scope finding:

1. Locate the tool output you cited as evidence (Grep result, Read excerpt, Glob result).
2. Confirm the cited output **directly proves** the violation. Inference chains, "this implies", and "presumably" do not count.
3. For **codebase-drift findings** (the pack claims X about the codebase; tool output shows Y), apply the additional rules in `essentials/domain-standards.md` §3:
   - The pack must cite a **specific named identifier** (function, class, file path, flag, env var, table name) that fails to resolve.
   - The finding must include the **verbatim quote** from the pack.
   - The finding must include the **tool output** (or its absence) that establishes the discrepancy.
   - Conceptual-paraphrase drift (e.g., "the service validates balance" with no specific identifier) is LOW confidence and dropped.
4. Assign a confidence level:
   - **HIGH** — direct pack quote + tool-verified discrepancy.
   - **MEDIUM** — structural issue confirmed by tool output (missing/empty section via Read, broken cross-reference via Glob, orphan term via Grep).
   - **LOW** — anything weaker.
5. **LOW findings:** one re-investigation pass with a single targeted tool call. If it lifts to HIGH or MEDIUM, keep. Otherwise drop. Do not downgrade a LOW codebase-drift finding to WARNING — drop it.

## Check B: Severity Calibration

For each surviving finding:

1. Find the severity the relevant step file (or `domain-standards.md` §1) specifies for that violation.
2. If the assigned severity is higher than what the rule specifies, downgrade.
3. If lower, upgrade.
4. Do not invent severities the rule files do not define.

## Loop Guard

- One re-investigation pass per LOW finding.
- A second pass is not allowed — drop the finding instead.
- Total step duration: do not exceed the time it took to produce the original findings in steps 1–7.

## Recording

For each surviving CRITICAL/ERROR finding, record:

- **Confidence:** HIGH or MEDIUM (LOW are dropped, not recorded)
- **Final severity** after calibration
- **Verbatim pack quote** (for drift findings)
- **Tool output reference** (Grep command + result, or Read excerpt with line numbers)

WARNING and INFO findings carry through to step 09 unchanged. They do not require a Confidence value, but step 09's report format will accept one if the writer chose to assign it.

## When Complete

You have a verified set of findings, each CRITICAL/ERROR finding carrying a HIGH or MEDIUM Confidence value.

**DO NOT write any files yet. DO NOT return output yet.**

Proceed to step 09: Create Summary
Read: `steps/09-create-summary.md`
