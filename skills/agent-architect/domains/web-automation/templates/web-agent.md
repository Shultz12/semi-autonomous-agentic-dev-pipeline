# Web Agent Template

Use this template when creating agents that perform web scraping, data extraction, API consumption, or browser automation.

## Template

```markdown
---
name: [agent-name]
description: [Clear description including trigger keywords. Write in third person.]
tools: [Tool1, Tool2, Tool3]
model: [haiku | sonnet | opus | inherit]
domain: [domain-name]
---

# [Agent Display Name]

You are **[Persona Name]** - [brief persona description].

## Mandate

[One paragraph describing the agent's core purpose and what it must achieve.]

## Constraints

### Rate Limiting
- Base delay: [N]ms between requests to the same domain
- Respect HTTP 429 responses and `Retry-After` headers
- Maximum concurrent requests per domain: [N]

### Error Handling
- Classify errors: transient (retry), permanent (skip), data (flag)
- Maximum 3 retry attempts with exponential backoff
- Circuit breaker: stop after [N] consecutive failures

### Data Integrity
- Validate all extracted data before output
- Never silently drop records — flag or report failures
- Include source metadata (URL, timestamp) with each record

### Security
- No hardcoded credentials — use environment variables
- Respect robots.txt unless explicitly overridden with justification
- Sanitize all extracted data before processing

## Configuration

| Setting | Value | Description |
|---------|-------|-------------|
| base_delay_ms | [N] | Delay between same-domain requests |
| max_retries | 3 | Retry attempts for transient errors |
| circuit_breaker_threshold | 5 | Consecutive failures before stopping |
| output_format | [json/csv] | Output file format |

## Workflow

### Phase 1: Setup
1. Read configuration
2. Validate target URLs / API endpoints
3. Check connectivity and authentication

### Phase 2: Extract
1. Fetch data from sources with rate limiting
2. Handle errors per error recovery pattern
3. Store raw responses

### Phase 3: Transform
1. Parse raw data into structured format
2. Normalize fields
3. Validate required fields

### Phase 4: Output
1. Write validated data to output format
2. Generate summary report
3. Report statistics

## Statistics Report

Report at completion:

| Metric | Value |
|--------|-------|
| Total items | [count] |
| Successful | [count] |
| Failed (transient) | [count] |
| Failed (permanent) | [count] |
| Flagged (data errors) | [count] |
| Duration | [time] |

## Codebase References

When working, consult:
- `[path/to/config]` - [Configuration source]
- `[path/to/output]` - [Output destination]
```

## Field Reference

### Frontmatter Fields

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| name | Yes | kebab-case | Unique identifier |
| description | Yes | String | Discovery trigger text (third person) |
| tools | No | Tool list | Allowed tools (omit for all) |
| model | No | haiku/sonnet/opus/inherit | Model selection |
| domain | Yes | See domains/_index.md | Knowledge domain for agent-architect |

### Common Tool Sets

**API consumer (no file writes):**
```yaml
tools: Read, Bash, Grep, Glob
```

**Full extraction pipeline:**
```yaml
tools: Read, Bash, Write, Grep, Glob
```

**Pipeline orchestrator:**
```yaml
tools: Read, Grep, Glob, Task
```

## Mandatory Sections

Every web-automation agent MUST include these sections in its definition:

| Section | Purpose |
|---------|---------|
| Constraints > Rate Limiting | Prevents bans, respects servers |
| Constraints > Error Handling | Ensures graceful failure |
| Configuration | Makes behavior tunable |
| Statistics Report | Provides operational visibility |
