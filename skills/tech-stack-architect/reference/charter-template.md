# Tech Stack Charter Template

Use this template when generating `.project/knowledge/tech-stack/charter.md`. The charter is the
**current-state allowlist**; the *why and history* live in TDRs. Every Approved row MUST
cite a TDR (a shared one is fine for minor deps).

## Template

```markdown
# Tech Stack Charter: [Product Name]

**Last Updated:** [YYYY-MM-DD]
**Owned by:** `/tech-stack-architect`

## Governing Rule

Adding, removing, upgrading (major), or replacing any runtime dependency, framework, or
external service is an ASK-FIRST action. It is decided only via `/tech-stack-architect`
and recorded as a TDR. Technology not listed here as `Approved` is rejected by
`design-auditor` and `plan-auditor`. Plan-architect and developers must escalate (BLOCKED)
when they need anything not on this list.

## Approved Stack

Every direct dependency from `backend/package.json` and `frontend/package.json`
(`dependencies` + `devDependencies`) appears as a row, grouped by category. One table per
category.

### [Category — e.g. Authentication]

| Category | Technology | Version constraint | Status | TDR |
|---|---|---|---|---|
| Authentication | SuperTokens | `^x.y` | Approved | TDR-005 |

(Repeat one table per category from `reference/tech-categories.md`.)

## Explicitly Rejected / Not Permitted

| Technology | Considered for | Rejected by TDR |
|---|---|---|
| [name] | [category/need] | TDR-### |

## Pending / Escalated

Open needs awaiting a decision (populated when an `unblock` escalation is logged but not
yet resolved). Empty when nothing is pending.

| Need | Raised by | Date | Status |
|---|---|---|---|
| [capability or named dep] | [plan-architect / developer / user] | [YYYY-MM-DD] | Open |
```

## Field Guidance

| Field | Notes |
|---|---|
| **Version constraint** | Guardrail only — marks the approved **major** line (e.g. `^2`). Crossing a major (→ `^3`) is a re-decision needing `/tech-stack-architect update` + a new TDR. Minor/patch moves within the constraint are free and need no TDR. The charter does NOT track the exact installed version — that is the lockfile's job. |
| **Status** | `Approved` \| `Superseded` \| `Deprecated` (being removed). No `Trial` state — provisional adoption is a note in the TDR Reasoning. |
| **TDR** | Every Approved row cites a TDR. Consequential deps cite their own full TDR; minor deps may share one `supporting-libraries` TDR. |

## Coverage & Scope

- **Coverage is complete and deterministic.** Every *direct* dependency is a row, so
  "is X allowed?" is answerable from the charter alone via a Glob/Grep — no "trivial vs
  significant" judgment for auditors to make.
- **Documentation depth is tiered, not coverage.** Consequential deps (frameworks,
  external services, anything touching auth / payments / storage / file handling / crypto;
  plus the build/test toolchain) get a full option-comparison TDR. Minor deps get a row +
  a one-line rationale under a shared `supporting-libraries` TDR.
- **devDependencies are listed too** (build-time deps are a real supply-chain vector) but
  default to the minor tier — except the build/test toolchain (bundler, test runner, TS
  compiler, CI-gating linter), which is consequential.

### Out of charter scope

The charter is an **adoption-policy** control, not a vulnerability scanner. Explicitly OUT:

- **Transitive dependencies** — governed by the lockfile, not the charter.
- **CVE / vulnerability surveillance and version currency** — owned by complementary
  automated tooling (`pnpm audit`, Dependabot-style updates, optional SBOM), a separate
  track from this charter.

### Main-canonical

The charter is a main-owned artifact (same class as `ROADMAP.md`). Worktree-side consumers
read it from the main root, never a worktree copy; on any merge conflict on
`.project/knowledge/tech-stack/**`, take main unconditionally — a worktree never legitimately holds a
different charter than main.
