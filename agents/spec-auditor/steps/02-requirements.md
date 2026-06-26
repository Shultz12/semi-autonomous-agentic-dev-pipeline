# Step 2: Requirements Quality

Validate FR-X requirement IDs, sequential numbering, priority tags, and per-requirement quality fields.

## FR-X ID Extraction

1. Grep SRS.md for the pattern `### FR-\d+:` to extract all functional requirement headings
2. Parse each match to extract:
   - The FR number (integer after "FR-")
   - The requirement name (text between ":" and "(")
   - The priority tag (P0, P1, or P2 in parentheses)

## FR-X Count Check

- If zero FR-X headings found: CRITICAL — "No functional requirements found. SRS must contain at least one FR-X requirement"

## Sequential Numbering

1. Sort extracted FR numbers
2. Check that the sequence starts at 1 and has no gaps
3. If gap found: ERROR — "FR-X numbering gap: FR-[N] missing between FR-[N-1] and FR-[N+1]"

## Priority Validation

For each FR-X heading:
1. Check that the priority tag matches `(P0)`, `(P1)`, or `(P2)`
2. If missing or invalid: ERROR — "FR-[X] missing valid priority. Must be (P0), (P1), or (P2)"

## Per-Requirement Quality Checks

For each FR-X, read the section content (from the FR-X heading to the next FR-X heading or next ## heading):

### Acceptance Criteria

1. Grep for `**Acceptance Criteria:**` or a checklist pattern (`- [ ]`) within the section
2. If neither found: ERROR — "FR-[X] has no acceptance criteria. Every requirement must have testable acceptance criteria"
3. If found but contains fewer than 2 items: WARNING — "FR-[X] has only [N] acceptance criterion. Consider whether this fully specifies the requirement"

### User Story

1. Grep for `**User Story:**` or the pattern `As a .* I want .* So that` within the section
2. If not found: WARNING — "FR-[X] has no user story"

### Edge Cases

1. Grep for `**Edge Cases:**` or an edge case table within the section
2. If not found: WARNING — "FR-[X] has no edge cases documented"

## Non-Functional Requirements Check

1. Grep for `## 6. Non-Functional Requirements` heading
2. If not found: already caught in Step 1, skip
3. If found: count subsection headings (`### 6.X`) within Section 6
4. If zero subsections: ERROR — "Non-Functional Requirements section has no subsections"
5. For each subsection found: check that it has non-empty content
   - If empty: WARNING — "NFR subsection [name] is present but empty"
