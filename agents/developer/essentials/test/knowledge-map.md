# Test Knowledge Map

## Stack triggers → user-level skills

## Project-level context (always read)
- .project/knowledge/test/_index.md

## BDD scenarios (read for in-scope scenarios)

The feature's Gherkin scenarios live at `<cycle-path>/specs/bdd/` — derive `<cycle-path>` from the `Report Directory` input (`<cycle-path>/execution/developer-reports/`). For each test task, read the `.feature` file named in its `Scenario:` field before writing the test; every in-scope scenario maps to at least one test.

A bugfix reproduction task carries `Bug-Expectation:` instead of `Scenario:` — a single declarative sentence (the bug report's `## Expected Behavior`, verbatim). Assert it directly; there is no `.feature` file to read. Name the test for the behavior and co-locate it with the affected module so it persists as a standing regression guard.

## Per-task dev-type derivation

Test tasks span multiple dev-types. After reading the always-read `.project/knowledge/test/_index.md`, derive each task's dev-type from its `Target file(s)` path and read the matching `_index.md` (plus feature-slug `_index.md` if present). Read only the dev-types appearing in the current phase — never pre-emptively read all four.

| Conventional path pattern | Dev-type |
|---|---|
| Server / API code — e.g. `backend/`, `server/`, `api/`, `src/server/`, language-specific roots holding HTTP / domain / persistence code | backend |
| Client / UI code — e.g. `frontend/`, `client/`, `web/`, `app/`, `ui/`, `src/client/` | frontend |
| Deployment, CI/CD, container, orchestration — e.g. `infra/`, `infrastructure/`, `terraform/`, `k8s/`, `Dockerfile`, `docker-compose.yml`, `.github/workflows/`, deploy scripts | infrastructure |

**Cross-cutting test** (integration / e2e exercising multiple layers): derive dev-type from the production code under test, not the test file's location. If multiple layers, read multiple `_index.md` files.
