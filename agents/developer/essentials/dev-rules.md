# Developer Rules (Universal)

Rules for ALL developer personas. Read this file before every implementation task.

---

## Development Principles

Default to the **simplest implementation that fully satisfies the task's Acceptance criterion** — not the most thorough one you can imagine. LLM-written code over-engineers by default; consciously counteract it. Add complexity only when a present requirement pulls it in, never in anticipation of one.

1. **KISS** — Write the simplest code that makes the Acceptance check pass: straightforward control flow over clever indirection, direct calls over layers of wrappers, plain data over premature class hierarchies. If a reviewer would ask "why is this here?", it shouldn't be.
2. **YAGNI** — Implement only what the task requires. No config options, parameters, hooks, generic handlers, or "just in case" branches for needs the plan does not state. A parameter with one caller and one value, or a branch no current path reaches, is over-engineering — cut it.
3. **Rule of Three** — Do not extract a shared helper or introduce an abstraction until **three** real call sites exist. With two or fewer, inline it; a little duplication is cheaper to maintain and undo than the wrong abstraction. Don't originate cross-file abstractions mid-task — choosing one soundly needs call-site analysis across the whole codebase, beyond a single task's scope.
4. **DRY** — Reuse existing utilities; search the codebase before creating new ones (see Search Before Code Protocol below). DRY means *don't duplicate what already exists* — it does not license speculative abstraction, which Rule of Three governs.
5. **SRP** — Each module/function has one clear responsibility. Don't mix concerns (validation + persistence + notification) in one function.
6. **Clean Architecture** — Dependencies flow ONE direction: higher layers import lower layers, never the reverse.
7. **Integration First** — Study existing patterns before writing new code; the Search Before Code Protocol below is the enforcement of this principle.
8. **No Technical Debt** — Only permanent, long-term solutions; do not ship "temporary" fixes or "to be cleaned up later" code. If a proper fix is not possible within the task, report BLOCKED rather than leaving debt behind.

Simplicity is also a security property: less speculative code means smaller attack surface and fewer untested paths. The simplest correct solution is usually the most secure and the most readable.

---

## Search Before Code Protocol

Before creating ANY new file, function, utility, or abstraction:

1. **Search** for existing implementations using Grep and Glob.
2. **Check** the shared utilities catalog in your persona file.
3. **Check** the per-type knowledge map (`essentials/<dev-type>/knowledge-map.md`) — its trigger rows route to user-level skills that often expose the canonical implementation.
4. **Check** the project-context `_index.md` rows for matching trigger phrases (e.g., a task that mentions Hebrew dates may map to a convention with the canonical formatter location).
5. **If found**: import and use the existing implementation.
6. **If not found**: create the new code, keeping it minimal.

---

## Deviation Rules

When you encounter something unexpected during implementation, apply the appropriate tier — do NOT default to BLOCKED for everything.

| Tier | Situation | Response | Scope |
|------|-----------|----------|-------|
| 1 | Bug found in-scope while implementing | Auto-fix, log as SILENT | Same file, no signature/export/name change |
| 2 | Plan assumes a small helper exists but it doesn't | Auto-create, log as NOTIFY | ALL 7 constraints must pass (see below) |
| 3 | Blocker resolvable via permitted command | Run command from allowlist, log as SILENT or NOTIFY | Only commands on Permitted Resolution Commands list |
| 4 | Architectural change or external constraint required | Escalate as BLOCKED with the appropriate `blocking-cause` | Any real-world constraint requiring human judgment |

### Tier 2 Constraints (ALL must be true)

1. The plan explicitly references the function/utility by name or describes its expected behavior.
2. It doesn't exist in the codebase (Search-Before-Code found nothing).
3. It's self-contained — no callers outside the current task.
4. It's small — under 20 lines of implementation logic.
5. It introduces no new dependencies (no imports that aren't already in the project).
6. It lives within the current task's file scope (same module/directory — not a new shared utility).
7. It doesn't create a new file — it's added to an existing file where it logically belongs.

**If ANY Tier 2 constraint fails → report BLOCKED, not Tier 2.**

### Tier 3 Rule

If a blocker requires a command not on the Permitted Resolution Commands list (see below), escalate as BLOCKED. Do not improvise commands.

### Tier 4 Blocking-Cause Mapping

When escalating Tier 4, select the `blocking-cause` that names the underlying constraint:

| Constraint hit | `blocking-cause` |
|---|---|
| A required package, credential, or service is missing from the environment | `dependency-missing` |
| The environment is in a broken state (DB unreachable, container down, build tooling broken structurally) | `environment-broken` |
| The plan or spec drifted relative to the codebase or a library API change makes the plan ambiguous | `spec-ambiguous` |
| A prior phase produced something the handoff doesn't surface | `handoff-insufficient` |

> For `dependency-missing`, distinguish the charter case: a technology **not Approved** in the Tech Stack Charter also maps to `dependency-missing`, with the `dependency-status: not-approved` frontmatter hint (see § Dependency Governance). A missing **Approved** dependency is not a blocker — install it as a Tier 3 resolution.

### Worked Examples

**Scenario:** While implementing a new endpoint, you notice a typo in an existing DTO field name in the same file.
**Classification:** Tier 1 — SILENT.
**Response:** Fix the typo, log deviation.

**Scenario:** A package is imported but the schema generation tool hasn't been run, causing type errors.
**Classification:** Tier 3 — check allowlist. If the generation command is on the Permitted Resolution Commands list, run it.
**Response:** Run the command, log deviation as SILENT.

**Scenario:** Plan references `calculateDiscount()` in pricing.service.ts:42, but the function doesn't exist.
**Classification:** BLOCKED — not Tier 2. The plan made a broken reference. This is a MISSING_REFERENCE Problem Report.
**Response:** Report BLOCKED with `blocking-cause: spec-ambiguous` and Problem Report.

**Scenario:** Plan task says "call formatAmount()" in the service you're building, but formatAmount doesn't exist anywhere. It's a 10-line pure function with no external dependencies.
**Classification:** Tier 2 — check all 7 constraints: (1) plan references it by name ✓ (2) doesn't exist ✓ (3) no callers outside current task ✓ (4) under 20 lines ✓ (5) no new deps ✓ (6) same file scope ✓ (7) no new file ✓.
**Response:** Create the helper inline, log deviation as NOTIFY.

**Scenario:** The plan says to use Redis for caching, but the Redis client isn't configured for this environment.
**Classification:** Tier 4 — BLOCKED with `blocking-cause: dependency-missing`. Infrastructure dependency beyond your authority.
**Response:** Report BLOCKED with description of the missing dependency.

**Scenario:** While implementing, you realize a function needs to accept an additional parameter not in the plan, changing its public signature.
**Classification:** Tier 1 (bug fix) with signature change — NOTIFY.
**Response:** Fix it, log deviation as NOTIFY (externally visible change).

### NOTIFY vs SILENT Classification

**SILENT conditions (ALL must be true):**
- Change is internal to the file (no export/signature/name changes visible to other files).
- No new code was created (only modified existing).
- OR: a permitted command was run with no lasting artifact.

**NOTIFY conditions (ANY is sufficient):**
- A function signature, export, or file name was changed.
- New code was created (Tier 2 helper).
- A Tier 3 command produced a lasting artifact (e.g., migration file).

**When in doubt, classify as NOTIFY.** Over-notifying is safe; under-notifying risks silent plan drift.

---

## Dependency Governance (Tech Stack Charter)

`.project/knowledge/tech-stack/charter.md` is the authoritative allowlist of approved third-party dependencies. Read it from the **main root** — the charter is main-canonical, never a worktree copy. Two rules govern adding or importing a runtime dependency:

- **Approved in the charter.** Using it is always fine. If it is Approved but missing from the workspace, installing it is a permitted Tier 3 resolution (see Permitted Resolution Commands): run the project's package-manager add command, log the deviation as NOTIFY, and continue. The install is isolated to the worktree and reviewed at merge — no BLOCK, no user involvement. (If the install itself fails for environmental reasons, that is `environment-broken`, not this case.)
- **Not Approved in the charter.** Adding, installing, or importing it is never a permitted resolution. Stop and report BLOCKED with `blocking-cause: dependency-missing`, set `dependency-status: not-approved` in the report frontmatter, and in the `## Problem Report` name the capability you need — the specific package if you know it, otherwise the capability (e.g., "a library to generate ZIP archives"). The user resolves it via `/tech-stack-architect unblock`, which amends the charter; the phase then re-runs.

If no charter exists at `.project/knowledge/tech-stack/charter.md`, treat the project as having no allowlist constraint — do not block on charter membership.

**Examples:**
- A task imports `archiver`, which IS Approved in the charter but not yet installed in the worktree → Tier 3: run the package-manager add command, log NOTIFY, continue. No BLOCK.
- A task needs to produce ZIP archives but no ZIP library is Approved (and none installed) → Tier 4: BLOCKED with `blocking-cause: dependency-missing` and `dependency-status: not-approved`; name the capability in the Problem Report.

---

## Resume Protocol

Only active when input contains `Resume: true`. If `Resume: true` is NOT in the input, skip this section entirely (zero token cost on normal path).

`Resume` is for crash recovery after a previous developer invocation died unexpectedly (process killed, environment lost). It is distinct from PARTIAL continuation, which uses `Residual Artifact:` and a fresh dispatch.

**For each task in the phase:**
1. Glob for the expected output file.
2. If the file exists: read first 50 lines to confirm it's substantive.
3. If substantive: mark task as completed, skip during implementation.

**"Substantive" means:** file is non-empty, contains implementation logic (not just imports or empty class), and has more than 5 lines of actual code.

**If a file exists but is partial:** overwrite from scratch (do not append).

**Log skipped tasks** in the completion report under a `Resumed Tasks` section:

```
Resumed Tasks:
- [N.M]: [task name] — skipped (artifact verified at [path])
- [N.M]: [task name] — re-implemented (artifact missing/partial)
```

**Always re-run verification** (Step 8) even if all tasks were skipped — the previous invocation may have died before verifying.

---

## Permitted Resolution Commands

These are the ONLY commands you may run to resolve Tier 3 blockers. If the resolution requires a command not on this list, escalate as BLOCKED. This list is enforced by a pre-tool hook — unauthorized commands will be rejected.

### Global (all personas)
- `npm run lint` — linting
- `npm run build` — build verification
- `pnpm add <package>` — install an Approved-but-missing dependency per § Dependency Governance; never use to add an un-Approved dependency

### Persona-specific
Consult your persona dev-rules file and project CLAUDE.md for permitted commands specific to your persona (e.g., schema generation, type synchronization, validation commands).

### Savepoint git commands (all personas)
These commands are permitted ONLY as part of the savepoint commit pattern in Step 8 (Verify), the partial commit rule before PARTIAL or BLOCKED, the report commit at the end of Step 9, and the restore/clear commits in Step 2 (Reset & Cleanup). They are not general-purpose — do not use them outside these workflows.

Every fresh-message commit goes through the `commit-to-git` skill: Read `.claude/skills/commit-to-git/SKILL.md` before your first commit in a phase and follow its form, passing `Agent: developer`, the staged path(s), and one of these subjects:
- `wip: Phase N - [phase name]` — savepoint commit (Step 8, after implementation, before verification)
- `wip: Phase N - partial (tasks 1-M)` — partial savepoint before BLOCKED
- `wip: Phase N - partial (tasks 1-M, residual <path>)` — partial savepoint before PARTIAL (the residual artifact is among the staged paths so a continuation developer resumes from a stable HEAD)
- `report: Phase N - [phase name] (<status>)` — the report commit at the end of Step 9 (always present; path-scoped to the active report path and the archive path if a prior run was moved this invocation)
- `chore: restore phase artifacts after revert` — Step 2 restore commit (only when `Reset To Commit` is present AND the `git checkout "$PRE" -- .project/` introduced changes)
- `chore: clear prior report after plan revision` — Step 2 deletion commit (only when `Plan Revised: true` removed previously-committed files)

The supporting commands:
- `git add <specific files>` — stage implementation files (and the residual artifact on PARTIAL) ahead of the commit
- `git commit --amend --no-edit` — fold a successful verification fix into the savepoint; it reuses the existing message, so it does not re-add the `Agent` trailer
- `git checkout -- .` — revert tracked files to savepoint state after failed fix
- `git clean -fd` — remove untracked files created during failed fix attempt
- `git rev-parse HEAD` — retrieve commit hash for status report

### Read-only git (all personas)
- `git log` — view commit history for context
- `git diff` — view changes for context
- `git status` — view working tree status

### Reset commands (all personas)
These commands are permitted ONLY in Step 2 (Reset & Cleanup) of `developer.md` when input includes `Reset To Commit: [hash]`. They are not general-purpose — do not use them outside that step.

- `git reset --hard <hash>` — revert all tracked files to the named commit; the first step of the code-scoped revert
- `git checkout <hash> -- <path>` — restore specific paths from another commit; used to bring `.project/**` artifacts back after the reset so pipeline state (prior developer report, code-reviews, test-results, investigations) survives a code revert

### NEVER permitted (any persona)
- The test suite — test execution is a dedicated downstream step; the developer's verification gate is lint + build
- Adding or installing a third-party dependency **not Approved** in the Tech Stack Charter, and any dependency removal (`pnpm remove` / `npm uninstall`) — see § Dependency Governance. Installing an **Approved-but-missing** dependency is permitted there as a Tier 3 resolution.
- `docker` commands — infrastructure changes are orchestrator-controlled
- `git push` — orchestrator-controlled
- `git reset` outside the Step 2 reset window — for savepoint reverts use `git checkout -- .` + `git clean -fd` instead (savepoint pattern, Step 8 of `developer.md`)
- `find-call-sites.ts` (the script at `.project/pipeline/scripts/codemods/find-call-sites.ts`) — the call-site enumeration is upstream-owned; in ABSTRACT migration phases, read it from the cited approved finding rather than re-running the script
- Any command not explicitly listed above

---

## Ambiguity Protocol

When you encounter unclear, contradictory, or missing information in the plan:

### When to Report BLOCKED

- Plan instruction has multiple valid interpretations.
- Referenced file/function/pattern doesn't exist in the codebase (and isn't marked "to create").
- Plan contradicts the actual codebase state.
- Plan contradicts itself between phases or tasks.
- A prior phase's artifact is missing from the handoff and you cannot find it in the codebase.

### How to Report BLOCKED

Return status BLOCKED with a Problem Report. Classify `blocking-cause:` per the BLOCKED Blocking Cause Classification table in `developer.md`.

The Problem Report format (for `blocking-cause: spec-ambiguous`) is defined in the plan-architect interface contract at `.claude/agents/interface-contracts/plan-architect.contract.md`. The format is reproduced here for convenience:

```
**Reporter:** developer
**Target:** [path to plan file]
**Phase:** [N]: [phase-name]
**Task:** [N.M] | "Phase-level"
**Type:** AMBIGUITY | MISSING_REFERENCE | CONTRADICTION | INVALID_STRUCTURE
**Severity:** BLOCKING | NON_BLOCKING

### Problem
[1-2 sentences: what exactly is wrong]

### Evidence
- [specific references: file paths, line numbers, plan task numbers]
- [what was found vs what was expected]

### Attempted Resolution
[What you tried before escalating]
```

For `blocking-cause: handoff-insufficient`, the Problem Report is a free-form description of what's missing from the handoff — what artifact, from which phase, and what detail is needed.

For `blocking-cause: dependency-missing`, the Problem Report names the missing package/credential/service and where the plan or environment expected it. When the cause is a technology not Approved in the Tech Stack Charter, also set `dependency-status: not-approved` in the report frontmatter and name the capability needed (specific package if known, else the capability).

For `blocking-cause: environment-broken`, the Problem Report includes the broken component, what was attempted, what failed, and the ORIGINAL error output where applicable.

**Type definitions (for `spec-ambiguous` Problem Reports):**
- `AMBIGUITY` — Instruction unclear or has multiple interpretations.
- `MISSING_REFERENCE` — Referenced file/function/pattern doesn't exist in codebase.
- `CONTRADICTION` — Plan conflicts with codebase state or with itself.
- `INVALID_STRUCTURE` — Plan structure doesn't follow expected format.

**Severity:**
- `BLOCKING` — Cannot proceed, must fix before continuing.
- `NON_BLOCKING` — Completed but flagging concern for awareness.

---

## Loop Guard Rules

### Implementation Fixes
When you encounter an issue during implementation:
- **Max 2 fix attempts** before escalating.
- If 2 attempts fail, report BLOCKED with a Problem Report describing what you tried.

### Verification Fixes
When lint/build fails after implementation:
- **Max 2 fix attempts** using the savepoint revert pattern.
- Each attempt: revert to savepoint, apply fix, re-run verification.
- If 2 attempts fail, follow Step 8 of `developer.md` — it walks the savepoint pattern, the fix-1/fix-2 sequence, and the first-invocation-vs-continuation discrimination that decides PARTIAL vs BLOCKED.

---

## Code Review Report Handling

When the orchestrator provides a Code Review Report (from code-reviewer), follow these steps:

1. Read the entire report before making any changes.
2. Address fixes in order of severity: CRITICAL first, then ERROR, then WARNING.
3. Apply each fix as described — the code-reviewer provides exact file, line, and instruction.
4. After all fixes applied, run verification (lint + build).
5. Report COMPLETED if verification passes; PARTIAL with `reason: partial-build-failure` if it fails on the first invocation; BLOCKED with `blocking-cause: environment-broken` if it fails on a continuation (continuation detected by `Residual Artifact:` present in input).

---

## Code Standards

### TypeScript
- Strict mode enabled — no `any` types.
- Explicit return types on all functions.
- Prefix unused variables with `_`.
- Use interfaces over types for object shapes (when appropriate).

### Error Handling
Consult project CLAUDE.md for the project's error handling pattern (Result pattern, exceptions, etc.) and apply it consistently.

### Language Convention
Consult project CLAUDE.md for language conventions (e.g., which language for logs vs user-facing messages).

### Defense-in-Depth
Validate at ALL layers:
- Frontend: input validation before API call.
- Controller: parameter validation, auth checks.
- Business logic: domain rule enforcement.
- Domain: entity invariant checks.

---

## Completion Reminder

After implementation and verification, execute all three final actions in order:
1. Write the report file (Step 9) — follow the archive-and-write sequence; write partial content if low on turns rather than returning with nothing.
2. Commit the report (Step 9) — path-scoped to the active report path and (if the mv ran this invocation) the archive path, via `commit-to-git` with subject `report: Phase N - [phase name] (<status>)`. The hash becomes the `Commit:` field in your return message.
3. Return the complete structured message (Step 10) — include every field required by your status; do not truncate.

If running low on turns, prioritize writing the report over additional verification — a partial file still satisfies the SubagentStop hook (which checks file presence, not the commit). If the commit fails or is interrupted, the orchestrator detects the missing `Commit:` field on return and re-dispatches the same invocation. Hook behavior on missing output is described in `developer.md` § Completion Gate.
