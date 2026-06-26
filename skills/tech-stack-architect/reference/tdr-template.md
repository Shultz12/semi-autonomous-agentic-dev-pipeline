# TDR Template — Technology Decision Record

**Location:** `.project/knowledge/tech-stack/tdr/TDR-NNN-<kebab-slug>.md` (zero-padded sequential,
e.g. `TDR-001-backend-framework.md`). Append-only — never edit a TDR's decision
retroactively except to set `Status` / `Superseded-by`.

**When a TDR is required:** adopting a new direct dependency, swapping one, removing one, or
crossing a major version. Minor/patch bumps within the charter constraint need no TDR.
Minor direct deps may share one `TDR-NNN-supporting-libraries.md`; consequential deps each
get a full option-comparison TDR.

## Template

```markdown
# TDR-NNN: [title]

- Status: proposed | accepted | superseded | rejected
- Date: [YYYY-MM-DD]
- Category: [charter category]
- Supersedes: TDR-[n] | none
- Superseded-by: TDR-[n] | none
- Drives: [REQ-# / FR-# / NFR-# / domain constraint]

## Context / Need

What prompted this decision — greenfield, swap, or escalation. If an escalation, name the
escalating agent and the BLOCKED report.

## Options Considered

### Option A — [name] (chosen | rejected)
- Pros: ...
- Cons: ...
- Security: [auth / data handling / supply-chain / license]
- Maintenance: [web-sourced facts — current major version, last release, cadence,
  community size — + date checked]

### Option B — [name] (chosen | rejected)
- Pros: ...
- Cons: ...
- Security: ...
- Maintenance: ...

### Option C — [name] (chosen | rejected)   *(optional)*
...

## Decision

[Chosen technology + version constraint, e.g. `archiver ^7`.]

## Reasoning

Why this option won, tied to the driving requirement and its security posture.

## Consequences / Affected Areas

Layers, integration points, env vars, and migration notes (for a swap). For a change that
affects a live worktree, record the chosen resolution path (Amend / Revert-and-restart).
```

## Notes

- **Supporting-libraries TDR.** For the batched minor-tier deps, one shared
  `TDR-NNN-supporting-libraries.md` lists each dep with a one-line rationale instead of a
  full option comparison. Consequential deps never share — each gets its own.
- **Provisional adoption.** There is no `Trial` charter status; if a dependency is adopted
  provisionally, say so in the Reasoning section.
- **Supersession.** A `swap` writes a new TDR with `Supersedes: TDR-<old>` and updates the
  old TDR's front matter to `Status: superseded` / `Superseded-by: TDR-<new>`. The old TDR
  body is left intact — it remains the historical record of why that choice was once made.
