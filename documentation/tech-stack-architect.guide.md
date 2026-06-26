# Tech Stack Architect Guide

## What It Does

`/tech-stack-architect` is the conversational owner of your project's technology decisions.
It creates and maintains the **Tech Stack Charter** — the allowlist of approved frameworks,
libraries, and services — plus an append-only log of **Technology Decision Records (TDRs)**
that capture *why* each choice was made.

**Key points:**
- It **decides and records** technology choices; it never edits application code, runs
  installs, or drives a migration. Code changes flow through the normal
  spec → design → plan → developer pipeline.
- Every approved technology traces to a requirement and cites a TDR. The charter is the
  single source of truth for "is this dependency allowed?"
- It is **web-enabled** — it verifies current versions, maintenance health, license, and
  known security advisories before recommending anything.
- The charter is **main-canonical**: it lives on `main`, and downstream stages read it from
  there. Auditors reject technology that isn't on it.
- Think of it as the project's technology gatekeeper and historian — it doesn't build the
  house, it approves the materials and records why each was chosen.

## When It's Used

User-invoked only (`/tech-stack-architect`). It is never spawned automatically by another
agent. Five modes:

| Mode | When to use |
|------|-------------|
| `create` | Once, early — right after `/product-architect`, before spec work — to define the foundational stack from the PRD and existing code. |
| `update` | Add, remove, or upgrade (across a major version) a dependency. |
| `swap` | Replace an approved component with an alternative (e.g. one OCR provider for another). |
| `unblock` | A plan or developer hit a technology that isn't approved yet; evaluate and approve (or reject) it. |
| `consult` | Ask questions about the stack. Read-only — writes nothing. |

```
/tech-stack-architect create
/tech-stack-architect swap
/tech-stack-architect unblock
```

Invoking with no argument auto-detects: if no charter exists it starts `create`; otherwise
it asks which mode you want.

## How a Session Goes

1. **Loads context** — PRD, specs, architecture docs, and your real `package.json` files to
   see what's already in use.
2. **Shows a Coverage Tracker** every turn (language, frameworks, DB, auth, storage, jobs,
   OCR, payments, testing, observability, supporting libraries, infrastructure).
3. **Presents options** — for each decision, 2–3 candidates with pros/cons, a security
   posture, a web-sourced maintenance signal, and a single recommendation. You decide.
4. **STOP & WAIT** — it shows you the exact charter and TDR text and waits for your
   confirmation before writing anything.
5. **Writes + commits** — `.project/knowledge/tech-stack/charter.md` and one TDR per decision, then
   commits them to `main`.

In a `create` run, consequential tech (frameworks, services, anything touching
auth/payments/storage/crypto, and the build/test toolchain) gets a full option-comparison
TDR; minor dependencies are confirmed in a single batch under a shared `supporting-libraries`
TDR — so you're not answering ~60 separate questions.

## Understanding the Charter & TDRs

- **Charter** (`.project/knowledge/tech-stack/charter.md`) — the current-state allowlist. Every direct
  dependency appears as a row: `Category | Technology | Version constraint | Status | TDR`.
  The version constraint marks the approved **major** line (a guardrail); minor/patch moves
  are free, crossing a major needs a new decision.
- **TDRs** (`.project/knowledge/tech-stack/tdr/TDR-NNN-<slug>.md`) — the reasoning behind each row:
  options considered, the decision, why it won, and consequences. Append-only.

## Limitations

- **Decides, doesn't build.** It will never write code, edit specs/SDD/plans, or run
  `pnpm add`. A `swap` produces an impact analysis and hands the migration back to the
  pipeline; it does not perform it.
- **Authors, doesn't enforce.** `design-auditor` (primary) and `plan-auditor` (backstop)
  reject off-charter technology. This skill writes the allowlist; it doesn't police it.
- **Adoption policy, not a vulnerability scanner.** It governs *direct* dependencies. The
  transitive tree and CVE/version surveillance are owned by complementary tooling
  (`pnpm audit`, Dependabot-style updates), which is a separate track.
- **Worktree changes are warn-and-confirm.** If a charter change affects a live worktree it
  flags it and offers Amend or Revert-and-restart — but you carry out the resolution through
  the normal pipeline.

## Related

- Skill definition: `.claude/skills/tech-stack-architect/SKILL.md`
- Interface contract: `.claude/agents/interface-contracts/tech-stack-architect.contract.md`
- Reference templates: `.claude/skills/tech-stack-architect/reference/`
- Upstream: [Product Architect](product-architect.guide.md) hands off to the `create` run.
- Consumers: [Spec Architect](spec-architect.guide.md), [Design Architect](design-architect.guide.md),
  and plan-architect read the charter; design-auditor and plan-auditor enforce it.
- Commits via the `commit-to-git` skill.
