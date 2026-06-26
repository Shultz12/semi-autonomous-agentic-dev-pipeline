# Web-Automation Domain

Conventions and scanning instructions for agents that perform web scraping, data extraction, API consumption, or browser automation.

## Scope

This domain applies to agents that:
- Scrape websites or extract structured data from web pages
- Consume REST, GraphQL, or other web APIs
- Automate browser interactions (form filling, navigation, screenshots)
- Process, transform, or pipeline web-sourced data

## Project Scanning

Run these scans to understand the target project before designing the agent.

### Required Scans

| Scan | Command | Purpose |
|------|---------|---------|
| Existing agents | `Glob .claude/agents/*/*.md` | Avoid duplication |
| Existing skills | `Glob .claude/skills/*/SKILL.md` and `Glob .claude/skills/*/*/SKILL.md` | Discover available capabilities |
| Project instructions | `Read CLAUDE.md` | Understand project rules |
| Config files | `Glob *.config.*` and `Glob .env*` | Understand project setup |

### Domain-Specific Scans

| Scan | Command | Purpose |
|------|---------|---------|
| HTTP clients | `Grep "fetch\|axios\|got\|node-fetch\|undici"` | Identify existing HTTP patterns |
| Browser tools | `Grep "puppeteer\|playwright\|cheerio\|jsdom"` | Identify browser automation libraries |
| Rate limiting | `Grep "rate.limit\|throttle\|delay\|backoff"` | Check for existing rate limiting code |
| API clients | `Grep "apiClient\|httpClient\|baseURL"` | Find existing API abstractions |

## Conventions

- **Rate limiting mandatory** — every agent that makes HTTP requests must implement rate limiting
- **Graceful error handling** — classify errors as transient (retry), permanent (skip), or data (flag)
- **Structured output** — all extracted data must be validated before output
- **No hardcoded credentials** — use environment variables or config files for API keys, tokens
- **Respect robots.txt** — check before scraping; document any overrides with justification
- **`domain` field required** in YAML frontmatter of all agents and skills

## Tool Recommendations

| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| API consumer | Read, Bash, Grep, Glob | HTTP via Bash/curl, read configs |
| Browser automator | Read, Bash, Write, Grep, Glob | Launch browser tools, write results |
| Data extractor | Read, Bash, Write, Grep, Glob | Fetch, parse, write structured output |
| Pipeline orchestrator | Read, Grep, Glob, Agent | Delegates extraction to sub-agents |

## Common Architecture Patterns

### Request Pipeline

```
Configure → Authenticate → Request → Rate Limit → Parse → Validate → Output
```

Each stage is a distinct responsibility. Agents should document which stages they own.

### Error Recovery Strategy

```
On error:
1. Classify: transient | permanent | data
2. Transient → retry with exponential backoff (max 3 attempts)
3. Permanent → log and skip
4. Data → flag for manual review
5. After 5 consecutive failures → circuit break, stop and report
```

## Domain Resources

- **Patterns**: [patterns/_index.md](patterns/_index.md) — Rate limiting, error recovery, data extraction pipeline
- **Web agent template**: [templates/web-agent.md](templates/web-agent.md) — Template with mandatory constraints
