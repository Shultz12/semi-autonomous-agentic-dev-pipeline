# tech-stack-architect Interface Contract

`tech-stack-architect` is a user-invoked skill (`disable-model-invocation: true`) — it is
never spawned via the Agent tool. This contract documents its modes, the files each reads
and writes, and the guarantees its artifacts uphold, so downstream consumers
(`plan-architect`, `plan-auditor`, `design-auditor`, `spec-architect`, `design-architect`)
know what to expect from `.project/knowledge/tech-stack/`.

## Input

Invoked as `/tech-stack-architect [mode]`. Five modes:

### `create` — greenfield charter

```
/tech-stack-architect create
```

Reads (each optional, skip-with-note if absent): `.project/product/PRD.md`, `VISION.md`,
all `.project/cycles/*/specs/SRS.md`, `.project/knowledge/architecture.md` + `overview.md`,
`.project/knowledge/domain.md`, `backend/package.json`, `frontend/package.json`,
`docker-compose*`, `.env.example`, project `CLAUDE.md`. Seeds the charter from real
dependencies.

### `update` — general amendment

```
/tech-stack-architect update
```

Reads the charter + relevant TDRs. Adds/removes/upgrades a dependency or crosses a major
version.

### `swap` — replace an approved component

```
/tech-stack-architect swap
```

Reads the charter + the incumbent's originating TDR + `architecture.md`; Greps the codebase
(read-only) for the incumbent's usage to produce an impact analysis.

### `unblock` — resolve an escalation

```
/tech-stack-architect unblock
```

Input may be a specific named dependency ("need `archiver`") or a vague capability ("need
ZIP archive generation") surfaced by `plan-architect` (`TECH_NOT_IN_CHARTER`) or a developer
(`dependency-status: not-approved`). Reads the charter + TDRs.

### `consult` — read-only Q&A

```
/tech-stack-architect consult
```

Reads the charter + TDRs + (as needed) the codebase. Writes nothing.

### No argument

Globs `.project/knowledge/tech-stack/charter.md`: missing → `create`; present → asks the user to pick
consult / update / swap / unblock.

## Output

### Success

```
Charter: .project/knowledge/tech-stack/charter.md (created | amended)
TDRs written:
- .project/knowledge/tech-stack/tdr/TDR-NNN-<slug>.md
- ...
```

- `create` → charter + one TDR per consequential decision + one shared
  `TDR-NNN-supporting-libraries.md` for the batched minor deps.
- `update` / `unblock` → charter amended + one new TDR.
- `swap` → charter row superseded + new row + new TDR (`Supersedes: TDR-<old>`); old TDR set
  to `Status: superseded` / `Superseded-by: TDR-<new>`.
- `consult` → answer in chat only; no files written.

### Error / proceed-with-warning

```
Warning: PRD not found at .project/product/PRD.md — proceeding from detected codebase
reality and any SRS files; foundational class-level choices may be incomplete.
```

- Missing PRD on `create` → proceed with warning (codebase + SRS suffice for class-level
  choices); do not stop.
- `unblock` with an unresolvable or contradictory need → stops and reports rather than
  guessing; the need stays in the charter's Pending / Escalated table.

## Charter & TDR Structure

| Artifact | Path | Purpose for consumers |
|---|---|---|
| Charter | `.project/knowledge/tech-stack/charter.md` | The Approved allowlist — Glob the file, Grep the technology to test membership |
| TDR | `.project/knowledge/tech-stack/tdr/TDR-NNN-<slug>.md` | The reasoning + options + security posture behind one charter row |

Charter Approved-row columns: `Category | Technology | Version constraint | Status | TDR`.
`Status` ∈ `Approved | Superseded | Deprecated`. The version constraint marks the approved
**major** line (a guardrail), not the exact installed version.

## Guarantees

- Every Approved charter row cites a TDR (a shared `supporting-libraries` TDR is valid for
  minor deps).
- Every TDR records the options considered, the reasoning, and a security posture for the
  chosen technology.
- Coverage is complete and deterministic: every *direct* dependency in either `package.json`
  appears as a charter row — membership is a Glob/Grep check, not a judgment call.
- The skill never modifies application code, specs, SDDs, or plans, and never runs installs.
- Charter drift versus `package.json` is surfaced explicitly, never silently reconciled.
- The charter is main-canonical: consumers read it from the main root, and on any conflict
  on `.project/knowledge/tech-stack/**` the main version wins.
- A change affecting a live worktree is flagged with a recorded resolution path
  (Amend / Revert-and-restart); the skill never performs the reconciliation itself.
