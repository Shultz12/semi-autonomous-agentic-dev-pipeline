# Error Recovery Pattern

## Purpose

Classify web request errors, apply appropriate recovery strategies, and prevent cascading failures through circuit breaking.

## When to Apply

Apply to any agent that makes HTTP requests or processes web-sourced data where partial failure is acceptable and total failure must be reported cleanly.

## Implementation

### Error Classification

```markdown
## Error Handling

Classify every error before deciding how to handle it:

| Category | Examples | Action |
|----------|----------|--------|
| Transient | HTTP 429, 500, 502, 503, 504, timeout, DNS failure | Retry with backoff |
| Permanent | HTTP 400, 401, 403, 404, 410 | Log and skip |
| Data | Parse error, missing expected field, invalid format | Flag for review |
```

### Retry Strategy

```markdown
## Retry Strategy

For transient errors:
1. Wait: delay = base_delay * (backoff_multiplier ^ attempt)
2. Retry the request
3. Maximum 3 attempts per request
4. After 3 failures: classify as permanent, log, and skip

**Retry log format:**
> [timestamp] RETRY attempt [N]/3 for [URL]: [error] — waiting [delay]ms
```

### Circuit Breaker

```markdown
## Circuit Breaker

Track consecutive failures across all requests:

- **Threshold:** 5 consecutive failures
- **Action:** Stop all processing, report status

When circuit breaks:
1. Stop making new requests
2. Report statistics (total processed, successful, failed, remaining)
3. Present the user with options:
   - Resume from last successful point
   - Skip problematic items and continue
   - Abort entirely

**Circuit breaker resets** after a successful request.
```

### Statistics Reporting

```markdown
## Error Statistics

Track and report at completion:

| Metric | Value |
|--------|-------|
| Total items | [count] |
| Successful | [count] |
| Transient failures (retried) | [count] |
| Permanent failures (skipped) | [count] |
| Data errors (flagged) | [count] |
| Circuit breaks triggered | [count] |
```
