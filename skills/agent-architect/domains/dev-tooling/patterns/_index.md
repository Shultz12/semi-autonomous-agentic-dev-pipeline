# Patterns Library

Reusable behavioral patterns for agents. Apply based on agent purpose and requirements.

## Available Patterns

| Pattern | Purpose | File |
|---------|---------|------|
| Search Before Code | Find existing patterns before creating new | [search-before-code.md](search-before-code.md) |
| Loop Guards | Prevent infinite iteration loops | [loop-guards.md](loop-guards.md) |
| Pre-Computational Logic | Validate assumptions before generating output | [pre-computational-logic.md](pre-computational-logic.md) |
| Tool Execution Verification | Back claims with actual tool output | [tool-execution-verification.md](tool-execution-verification.md) |
| Defense-in-Depth | Validate across multiple layers | [defense-in-depth.md](defense-in-depth.md) |
| Handoff Protocol | File-based inter-agent communication (custom pattern) | [handoff-protocol.md](handoff-protocol.md) |
| Feedback Loop | Iterate until quality threshold met | [feedback-loop.md](feedback-loop.md) |
| Progressive Question Flow | Gather information systematically | [progressive-question-flow.md](progressive-question-flow.md) |
| Output Enforcement | Block agent from returning until output file exists | [output-enforcement.md](output-enforcement.md) |
| Savepoint & Deterministic Revert | Controlled rollback when attempts fail | [savepoint-revert.md](savepoint-revert.md) |
| Self-Criticism & Disconfirmation | Challenge conclusions before returning findings | [self-criticism.md](self-criticism.md) |
| Severity + Confidence Pairing | Classify findings by impact AND certainty independently | [severity-confidence-pairing.md](severity-confidence-pairing.md) |
| Escalation Routing | Structured escalation to orchestrator instead of asking user | [escalation-routing.md](escalation-routing.md) |

## Pattern Selection Guide

| Agent Type | Recommended Patterns |
|------------|---------------------|
| Reviewer | [Tool Execution Verification](tool-execution-verification.md), [Loop Guards](loop-guards.md), [Output Enforcement](output-enforcement.md), [Self-Criticism](self-criticism.md), [Severity + Confidence Pairing](severity-confidence-pairing.md) |
| Developer | [Search Before Code](search-before-code.md), [Loop Guards](loop-guards.md), [Output Enforcement](output-enforcement.md), [Savepoint & Revert](savepoint-revert.md), [Escalation Routing](escalation-routing.md) |
| Planner | [Pre-Computational Logic](pre-computational-logic.md), [Output Enforcement](output-enforcement.md), [Escalation Routing](escalation-routing.md) |
| Pipeline Agent | [Handoff Protocol](handoff-protocol.md), [Feedback Loop](feedback-loop.md), [Output Enforcement](output-enforcement.md), [Escalation Routing](escalation-routing.md) |
| Interactive | [Progressive Question Flow](progressive-question-flow.md) |
| Validator | [Defense-in-Depth](defense-in-depth.md), [Tool Execution Verification](tool-execution-verification.md), [Output Enforcement](output-enforcement.md), [Severity + Confidence Pairing](severity-confidence-pairing.md) |
| Investigator | [Tool Execution Verification](tool-execution-verification.md), [Self-Criticism](self-criticism.md), [Severity + Confidence Pairing](severity-confidence-pairing.md), [Output Enforcement](output-enforcement.md) |
| Aggregator / Analyst | [Self-Criticism](self-criticism.md), [Severity + Confidence Pairing](severity-confidence-pairing.md), [Output Enforcement](output-enforcement.md) |

## Pattern Combinations

**Standard Developer**:
- Search Before Code
- Loop Guards
- Feedback Loop
- Output Enforcement
- Savepoint & Deterministic Revert
- Escalation Routing

**Standard Reviewer**:
- Tool Execution Verification
- Loop Guards
- Defense-in-Depth (optional)
- Output Enforcement
- Self-Criticism & Disconfirmation
- Severity + Confidence Pairing

**Standard Investigator**:
- Tool Execution Verification
- Self-Criticism & Disconfirmation
- Severity + Confidence Pairing
- Output Enforcement

**Standard Planner**:
- Pre-Computational Logic
- Progressive Question Flow (if interactive)
- Output Enforcement (if writes plan files)
- Escalation Routing

**Standard Pipeline Agent**:
- Handoff Protocol
- Feedback Loop
- Output Enforcement
- Escalation Routing
- Savepoint & Deterministic Revert (if modifies artifacts)

---

## Adding New Patterns

When adding a new pattern:
1. Determine where it belongs:
   - **Domain-specific**: create in the relevant domain's `patterns/` directory
   - **Generic** (applicable across domains): create in `references/patterns/`
2. Create a new file: `<pattern-name>.md`
3. Follow the required structure: Purpose, When to Apply, Implementation, Rationale, Example (GOOD/BAD contrast)
4. **Add the pattern to the "Available Patterns" table** in the appropriate `_index.md`
5. Add to "Pattern Selection Guide" if applicable to specific agent types
6. Update "Pattern Combinations" if the pattern fits common agent archetypes
