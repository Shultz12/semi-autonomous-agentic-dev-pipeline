# Rate Limiting Pattern

## Purpose

Control request frequency to avoid IP bans, respect server rate limits, and maintain reliable data extraction over extended operations.

## When to Apply

Apply to any agent that makes HTTP requests to external servers. This pattern is **mandatory** for all web-automation agents.

## Implementation

### Basic Rate Limiting

Insert a configurable delay between requests to the same domain:

```markdown
## Rate Limiting

**Default delay:** [N] ms between requests to the same domain.

Before each request:
1. Check time since last request to this domain
2. If elapsed < delay, wait for the remainder
3. Execute request
4. Record timestamp
```

### Adaptive Rate Limiting

Adjust delay based on server responses:

```markdown
## Adaptive Rate Limiting

- On HTTP 429 (Too Many Requests): double the delay, respect `Retry-After` header if present
- On HTTP 503 (Service Unavailable): apply exponential backoff (2s, 4s, 8s, 16s)
- On 3 consecutive successful responses: reduce delay by 10% (minimum: base delay)
- Log all rate limit adjustments
```

### Per-Domain Limits

Maintain separate rate limit state per domain:

```markdown
## Per-Domain Configuration

| Domain | Base Delay | Max Concurrent |
|--------|-----------|----------------|
| [domain] | [delay]ms | [count] |

Each domain has independent:
- Request timestamp tracking
- Adaptive delay state
- Concurrent request counting
```

## Configuration Table

Include in the agent definition:

```markdown
| Setting | Default | Description |
|---------|---------|-------------|
| base_delay_ms | 1000 | Minimum delay between same-domain requests |
| max_retries_on_429 | 3 | Retries before giving up on rate-limited endpoint |
| backoff_multiplier | 2 | Exponential backoff factor |
| max_delay_ms | 30000 | Upper bound on adaptive delay |
```
