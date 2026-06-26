# Domain Registry

Domains provide **validation rules** specific to an agent's operating context. Unlike behavioral patterns (universal, defined in `agent-standards.md` Section 9), domain rules cover operational conventions and constraints unique to each domain.

---

## Available Domains

| Domain | Directory | Description |
|--------|-----------|-------------|
| `dev-tooling` | `domains/dev-tooling/` | Agents operating within Claude Code projects (`.claude/` structure conventions) — 9 checks |
| `web-automation` | `domains/web-automation/` | Agents performing web scraping, API consumption, or browser automation — 5 checks |
| `agent-tooling` | `domains/agent-tooling/` | Agents that create, audit, and maintain other agents, skills, and domains — 12 checks |

---

## Domain Detection Algorithm

1. Parse the artifact's YAML frontmatter
2. Look for the `domain` field
3. Handle result:

| Condition | Action |
|-----------|--------|
| `domain` present + matches a known domain | Load `domains/<domain>/domain.md`, apply its validation rules |
| `domain` present + unknown value | WARNING: unknown domain, skip domain-specific checks |
| `domain` absent | WARNING: no domain specified, skip domain-specific checks |

---

## Loading Sequence

1. Read this file (`_index.md`) to identify available domains
2. Read `domains/<domain>/domain.md` for validation rules
3. Apply domain-specific checks during step 7 (after behavioral pattern checks)

Domain checks are numbered by the base step they extend (e.g., `1.D1` extends structural validation, `9.D2` extends content hygiene). All domain checks execute during step 7 but their IDs indicate which base category they belong to.

---

## Adding New Domains

To add a new domain:

1. Create `domains/<domain-name>/domain.md`
2. Define: scope, convention checks, operational pattern checks, additional checklist count
3. Add the domain to the "Available Domains" table above
4. Ensure domain name matches Agent Architect's domain naming (if applicable)
