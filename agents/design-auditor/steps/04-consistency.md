# Step 4: Consistency Validation

Verify internal consistency within the SDD and alignment with SRS scope.

## Checks to Perform

### Check 4.1: Scope Boundary Alignment

**What to verify:**
- SDD Constraints & Boundaries do not contradict SRS Boundaries

**How to verify:**
1. Read the SDD's Constraints & Boundaries section (In scope, Out of scope)
2. Read the SRS's Boundaries section (Section 7)
3. Compare scope claims:
   - If the SDD claims something is "in scope" that the SRS explicitly lists as "out of scope": ERROR — "SDD scope contradicts SRS: '[item]' is in-scope in SDD but out-of-scope in SRS"
   - If the SDD claims something is "out of scope" that the SRS explicitly requires via an FR-X: ERROR — "SDD scope contradicts SRS: '[item]' is out-of-scope in SDD but required by FR-[X] in SRS"

Note: This is a semantic check. Flag only clear, unambiguous contradictions. Do not flag items that are simply absent from one document.

### Check 4.2: Design Decision Rationale Completeness

**What to verify:**
- Every DD-# has non-empty Rationale content

**How to verify:**
1. For each DD-# section, locate the Rationale field
2. Check that content follows the `- **Rationale:**` marker
3. If Rationale is empty or contains only generic text like "Standard approach": WARNING — "DD-[N] has empty or generic rationale"

### Check 4.3: Component-Traceability Alignment

**What to verify:**
- Component names in the Requirement Traceability table exist in the Component Architecture table

**How to verify:**
1. Extract all component names from the Component Architecture table's Component column
2. Extract all component names from the Requirement Traceability table's Component column
3. For each component in the traceability table:
   - If it does not appear in the Component Architecture table: WARNING — "Traceability table references component '[name]' not listed in Component Architecture"

### Check 4.4: Design Confidence Reasonableness

**What to verify:**
- Design Confidence level aligns with the quality of the SDD content

**How to verify:**
This is an informational check only:
1. If Design Confidence is "High" but there are ERROR issues found in steps 1-3: INFO — "Design Confidence is High but [N] errors were found — consider whether confidence level is accurate"
2. If Design Confidence is "Low" and no issues found: INFO — "Design Confidence is Low but no structural issues found — confidence may be understated"

### Check 4.5: ASK-FIRST Governance for Design Decisions

**What to verify:**

No DD-#, Component Architecture Table row, or Integration Points Table row mandates a new environment variable, new package, or new infrastructure component without an explicit user-approval marker. The full rule definition — categories, signals, required marker forms, and finding format — is in the `## ASK-FIRST Governance for Design Decisions` section of `essentials/design-review-rules.md`. Apply that rule here.

**How to verify:**

For every DD-#:
1. Read the DD-#'s **Decision** and **Alternatives Rejected** fields. Identify any named env vars, packages, or infrastructure components.
2. For each candidate, verify whether it is already present in the project:
   - Env vars — Grep the project's env template (`.env.example`, `.env.template`).
   - Packages — Grep the project's manifest file(s) (`package.json`, `requirements.txt`, `go.mod`, `pyproject.toml`) and the codebase for an existing import.
   - Infrastructure — Grep config, docker-compose, deployment manifests, or scheduler config for an existing usage.
3. For each unmatched candidate, search the DD-# block for an approval marker matching one of the three forms in the rules file:
   - `User Approval: <YYYY-MM-DD> — <context>` inside the DD-# block
   - `Requires User Approval: yes` field with explanation
   - SDD-level Meta field `Infrastructure Additions Approved:` listing the addition

For every Component Architecture Table row and Integration Points Table row, repeat the same scan: identify named additions, verify against the project, look for an approval marker on the row or in the SDD Meta.

**Pass/Fail:**

- PASS: All candidates carry a matching approval marker; OR no candidates found.
- FAIL [ERROR] (HIGH): Use the finding format from the rules file — name the category (env var / package / infra), location (`DD-<n>` or `<Table>:<row>`), the introduced identifier, evidence quoted from the SDD, and the required fix.

A single missing-marker finding renders the SDD INVALID. Multiple unmarked additions produce multiple findings, one per hit.

**Confidence calibration:**

- HIGH when the introduced identifier is named explicitly in the SDD and verified absent from the project.
- MEDIUM when the SDD names a category without specifying the component (e.g., "introduce a queue" with no broker named) — emit the finding with a suggestion that the SDD name the component before approval can be granted.

## When Complete

Record all findings with their severity levels. All steps are now complete.
Return to the workflow in `modes/full-audit.md` for the Self-Check phase (Phase 5).
