# Domain: web-automation

## Scope

Agents and skills that perform web scraping, API consumption, browser automation, or any HTTP-based data retrieval and processing. Includes scrapers, crawlers, API integrators, and data extraction pipelines.

---

## Domain Checks

Checks are numbered by the base step they extend: `<step>.D<n>`.

### Step 7 Extensions: Patterns

#### Check 7.D1: Rate Limiting

**What to verify:**
- Agent that makes HTTP requests MUST implement rate limiting
- Implementation should include at least 2 of these 3 markers:
  - Delay/wait mechanism between requests
  - Backoff strategy (linear or exponential)
  - Max concurrent request limit

**Implementation markers:**
- "delay", "wait between", "rate limit", "throttle"
- "backoff", "exponential backoff", "retry delay"
- "max concurrent", "concurrency limit", "parallel limit"

**Pass/Fail:**
- PASS: Rate limiting documented with at least 2 of 3 markers
- FAIL [ERROR]: HTTP-making agent without rate limiting
- FAIL [WARNING]: Rate limiting mentioned but fewer than 2 markers present

#### Check 7.D2: Error Recovery with Classification

**What to verify:**
- Agent classifies errors into categories (e.g., transient/permanent/data) with distinct recovery strategies
- Implementation should include at least 2 of these 3 markers:
  - Error classification (transient/permanent/data)
  - Retry logic with limits
  - Circuit breaker or escalation mechanism

**Implementation markers:**
- "transient", "permanent", "data error"
- "retry", "skip", "fail", "circuit breaker"
- "error classification", "error handling"

**Pass/Fail:**
- PASS: Error recovery with classification and at least 2 of 3 markers
- FAIL [WARNING]: No error classification strategy or fewer than 2 markers

#### Check 7.D3: Structured Output Validation

**What to verify:**
- If agent extracts or transforms data, validation of output structure is mentioned
- Data quality checks documented

**Pass/Fail:**
- PASS: Not a data extraction agent, OR output validation mentioned
- FAIL [WARNING]: Data extraction agent without output validation

### Step 9 Extensions: Content Hygiene

#### Check 9.D1: No Hardcoded Credentials

**What to verify:**
- Agent content does not contain hardcoded API keys, tokens, passwords, or secrets
- Credentials are referenced via environment variables or configuration, not inline

**How to verify:**
- Scan content for patterns: API keys, bearer tokens, passwords, secret strings
- Look for inline credential values vs environment variable references

**Pass/Fail:**
- PASS: No hardcoded credentials found
- FAIL [CRITICAL]: Hardcoded credentials detected in agent content

#### Check 9.D2: Robots.txt Compliance (if scraping agent)

**What to verify:**
- If agent performs web scraping (not just API consumption)
- Then robots.txt compliance should be mentioned

**How to detect need:**
- Agent scrapes web pages, crawls sites, or extracts data from HTML
- NOT needed for pure API consumption agents

**Pass/Fail:**
- PASS: Not a scraper, OR robots.txt compliance mentioned
- FAIL [WARNING]: Scraping agent without robots.txt mention

---

## Additional Checklist Count

**5 additional checks** (7.D1, 7.D2, 7.D3, 9.D1, 9.D2)

---

## Alignment

Domain name `web-automation` and pattern names (Rate Limiting, Error Recovery) align with Agent Architect's web-automation domain.
