# Canonical Data Sources

Reference used during Phase 2 (Data Collection) and whenever the same metric can be derived from multiple files. When a discrepancy is detected between the canonical source and a secondary source, report it in the Data Completeness section of the main report — do not silently pick one.

| Metric | Canonical Source | Reason |
|--------|-----------------|--------|
| Attempt counts (implementation, test-writing, CODE_BUG fixes, TEST_BUG fixes, handoff rebuilds) | Phase summary | State-manager aggregates from orchestrator counters — official record |
| Finding categories and severities | Code-review files | Code-reviewer is the author — primary source |
| Test pass/fail/skip counts and attribution | Test-results files | Test-runner is the author — primary source |
| Investigation severity, confidence, depth, attribution reclassification | Investigation files | Code-investigator is the author — primary source |
| Files created/modified per phase | Manifest | State-manager's append-only index — single source of truth for artifact inventory |
| Deviations and plan corrections | Phase summary | State-manager records from developer reports |

## Data Inconsistency Reporting

When a discrepancy is detected (e.g., phase summary says 2 implementation attempts but code-review file has 3 attempt sections), add an entry to the Data Completeness section of the report:

```
**Data Inconsistencies:**
- Phase [N]: implementation attempts — phase summary reports 2, code-review file has 3 attempt sections
```

This flags potential state-manager bugs and tells the user which number the report used (the canonical one).
