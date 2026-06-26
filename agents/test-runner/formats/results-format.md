# Results File Format

Write to the provided `Results Output Path`. The per-mode results filename and the file's top-level title/header are defined by the active mode's results-file convention (see the mode file); this format defines the run-section structure they share.

## File Lifecycle

- **First run for an output path:** Create the file with the mode's header and Run 1
- **Subsequent runs (after fix attempts):** Append a new run section, increment the run number
- This creates a chronological record that code-investigator and quality-analyst read

## Structure

The file's top-level title and per-run header text come from the active mode's results-file convention. The run-section structure below is common to every mode:

```markdown
## Run [M] — [YYYY-MM-DD HH:mm]
**Command:** [exact command run]
**Duration:** [seconds]

### Summary
| Total | Pass | Fail | Skip |
|-------|------|------|------|
| [N]   | [N]  | [N]  | [N]  |

### Overall: PASS | FAIL

### Failures
| # | Test | Suite | Attribution | Evidence |
|---|------|-------|-------------|----------|
| 1 | [test name] | [file path] | CODE_BUG | [1-2 sentence evidence] |
| 2 | [test name] | [file path] | TEST_BUG | [1-2 sentence evidence] |

---

## Run [M+1] — [YYYY-MM-DD HH:mm] (after fix)
**Command:** [exact command run]
**Duration:** [seconds]

### Summary
| Total | Pass | Fail | Skip |
|-------|------|------|------|
| [N]   | [N]  | [N]  | [N]  |

### Overall: PASS | FAIL

### Failures
...
```

## BLOCKED Run Shape

When the test command itself fails to execute (not test failures; the command errored before producing test output), the run records only the attempted command and the error:

```markdown
## Run [M] — [YYYY-MM-DD HH:mm] (BLOCKED)
**Command:** [exact command attempted]
**Reason:** [error message from the failed command]

### Overall: BLOCKED
```

## Phase Prefix Rule

A dispatch may name the phase as a numeric value with a descriptive sub-step suffix, e.g. `Phase: 0: bugfix-reproduce`. When it does:

- The results frontmatter `phase:` field and the commit subject's `phase <N>` token take the **numeric prefix only** (`0`).
- The descriptive sub-step name (`bugfix-reproduce`) appears only in the human-readable run/section header — never in the `phase:` field.

Downstream consumers parse `phase:` exactly as for any other run, with no special-casing.

## Rules

1. The `---` separator between runs is required — downstream agents use it to split run sections
2. Omit the Failures section entirely when all tests pass (Overall: PASS)
3. When Overall is BLOCKED, omit the Summary and Failures sections — record only the Command and Reason
4. The run number increments monotonically — read the existing file to determine the next number
5. Timestamp format: `YYYY-MM-DD HH:mm` (24-hour)
6. Duration: wall-clock seconds from the Bash output, rounded to nearest integer (omit for BLOCKED runs)
7. Test names and suite paths must match the test runner's output exactly — do not paraphrase
8. Evidence in the table should be concise (1-2 sentences). The attribution guide defines what constitutes good evidence.
