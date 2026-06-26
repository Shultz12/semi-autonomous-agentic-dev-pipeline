# Interface Contracts Index

Each contract defines the input a subagent expects and the output it produces. Read the relevant contract before spawning the agent via the Agent tool.

| Contract | Purpose |
|---|---|
| `accept-feature.contract.md` | Promoting completed cycles (feature/refactor/primitives/bugfix), merging to main, signalling milestone follow-up |
| `agent-auditor.contract.md` | Reviewing agent/skill definitions against standards |
| `code-investigator.contract.md` | Investigating root causes of code and test failures, including standalone bug diagnosis (investigation + resolution modes) |
| `code-reviewer.contract.md` | Validating code quality across PHASE_REVIEW, VERIFICATION_FAILURE, TEST_REVIEW, CYCLE_REVIEW, INTEGRATION_VERIFICATION, ABSTRACT_MIGRATION_REVIEW modes |
| `design-architect.contract.md` | Producing the SDD from SRS + BDD |
| `design-auditor.contract.md` | Validating SDD structure, completeness, and SRS consistency |
| `developer.contract.md` | Implementing plan/test-plan phases (standard + fix modes) |
| `domain-auditor.contract.md` | Reviewing domain knowledge packs against standards |
| `knowledge-curator.contract.md` | Producing knowledge-cleanup proposals classifying dead-weight, gaps, and redundancy across `.project/knowledge/**` into project-level vs user-level items (single mode; consumer-agnostic output) |
| `milestone-archivist.contract.md` | Archiving a completed milestone (copy artifacts, synthesize CHANGELOG, tag) |
| `pattern-analyst-auditor.contract.md` | Verifying every `pattern-analyst` finding (citations, ABSTRACT-matrix re-application, structured-field completeness) and emitting a single combined audit per cycle |
| `pattern-analyst.contract.md` | Detecting refactor opportunities and curating per-cycle approved findings (convergence-scout, divergence-scout, primitives-scout, curate modes); sole owner of ABSTRACT decisions |
| `plan-architect.contract.md` | Producing implementation/test/refactor/bug-fix plans, dispatched by action (create \| update) and target (feature-draft \| feature-final \| test-plan \| refactor-plan \| bugfix-reproduction \| bugfix-draft \| bugfix-final \| deviation; deviation is update-only) |
| `plan-auditor.contract.md` | Validating plan structure and quality across feature-draft, feature-final, test-plan, refactor-plan, bugfix-reproduction, bugfix-draft, and bugfix-final targets (full-audit + phase-audit modes) |
| `product-architect.contract.md` | Output formats for product vision, PRD, and state; ROADMAP hand-off to progress-tracker |
| `progress-tracker.contract.md` | Owning ROADMAP/progress files — creation + transitions (init, start, update, ship, close modes) |
| `quality-analyst.contract.md` | Analyzing quality data (`agent` + `skill` scoped modes, one Target per cycle; `synthesis` rolls up scoped reports for a cycle or milestone and emits the milestone knowledge-usage report) |
| `spec-architect.contract.md` | Producing SRS and BDD specifications |
| `spec-auditor.contract.md` | Validating SRS and BDD specs for quality and consistency |
| `state-manager.contract.md` | Distilling phase results and curating project-level conventions (cycle-phase, cycle-close, rebuild, refactor-curation modes) |
| `tech-stack-architect.contract.md` | Owning the Tech Stack Charter and TDR log; interactive technology selection, swaps, and BLOCKED-escalation resolution (create \| update \| consult \| swap \| unblock modes) |
| `test-runner.contract.md` | Executing tests (phase \| reproduction \| full-suite \| targeted modes), capturing results, preliminary fault attribution |
