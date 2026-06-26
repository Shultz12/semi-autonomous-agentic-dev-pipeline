# Step 3: Code Reference Validation

Verify that file paths referenced in the SDD actually exist in the codebase.

## Checks to Perform

### Check 3.1: Integration Points File Paths

**What to verify:**
- Every file path in the Integration Points table's File Location column exists in the codebase

**How to verify:**
- Extract all backtick-wrapped file paths from the File Location column
- For each path, use Glob to check if the file exists
- If section is marked N/A with reason, skip this check

**Pass/Fail:**
- PASS: All referenced files exist (or section is N/A)
- FAIL [ERROR]: Integration Points references non-existent file: `[path]`

### Check 3.2: Design Decision Rationale File References

**What to verify:**
- File paths mentioned in DD-# Rationale fields exist in the codebase

**How to verify:**
- Scan each DD-# Rationale field for backtick-wrapped file paths (pattern: `` `path/to/file.ts` `` or `` `path/to/file.ts:line` ``)
- For each path, extract the file portion (strip `:line` suffix if present)
- Use Glob to verify the file exists
- Line numbers are best-effort — verify file existence only

**Pass/Fail:**
- PASS: All rationale file references exist
- FAIL [WARNING]: DD-[N] Rationale references non-existent file: `[path]`

### Check 3.3: Meta Source Spec Path

**What to verify:**
- The Source Spec path in Meta section points to an existing file

**How to verify:**
- Extract the backtick-wrapped path from the Source Spec field
- Use Glob to verify the file exists

**Pass/Fail:**
- PASS: Source Spec file exists
- FAIL [ERROR]: Meta Source Spec references non-existent file: `[path]`

## Important Notes

- Use Glob for ALL file existence checks. Do not assume files exist.
- Relative paths should be checked from the project root.
- Component Architecture table contains component names and layers, not file paths — nothing to verify there.
- Interface Contracts section contains method signatures and DTOs, not file paths — nothing to verify there.

## When Complete

Record all findings with their severity levels. Proceed to step 04.
Read: `steps/04-consistency.md`
