# Web-Automation Patterns

Behavioral patterns specific to web scraping, data extraction, and browser automation agents.

## Available Patterns

| Pattern | Purpose | File |
|---------|---------|------|
| Rate Limiting | Control request frequency to avoid bans and respect server limits | [rate-limiting.md](rate-limiting.md) |
| Error Recovery | Classify, retry, and circuit-break on web request failures | [error-recovery.md](error-recovery.md) |
| Data Extraction Pipeline | Structured ETL flow from raw web data to validated output | [data-extraction-pipeline.md](data-extraction-pipeline.md) |

## Pattern Selection Guide

| Agent Type | Recommended Patterns |
|------------|---------------------|
| API consumer | Rate Limiting, Error Recovery |
| Web scraper | Rate Limiting, Error Recovery, Data Extraction Pipeline |
| Browser automator | Rate Limiting, Error Recovery |
| Data pipeline | Data Extraction Pipeline, Error Recovery |

## Cross-Domain Patterns

These patterns from other domains are also useful for web-automation agents:

- **Loop Guards** — prevent infinite retry or pagination loops
- **STOP & WAIT** — require user approval before large-scale scraping operations

Refer to the dev-tooling domain's [patterns library](../dev-tooling/patterns/_index.md) for these patterns.

---

## Adding New Patterns

When adding a new pattern:
1. Determine where it belongs:
   - **Domain-specific**: create in the relevant domain's `patterns/` directory
   - **Generic** (applicable across domains): create in `references/patterns/`
2. Create a new file: `<pattern-name>.md`
3. Follow the structure of existing pattern files (Purpose, When to Apply, Implementation)
4. **Add the pattern to the "Available Patterns" table** in the appropriate `_index.md`
5. Add to "Pattern Selection Guide" if applicable to specific agent types
