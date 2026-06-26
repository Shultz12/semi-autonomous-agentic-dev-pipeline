# Contract Writing Guide

How to create interface contracts for agents that communicate with other agents.

## What Is an Interface Contract

An interface contract is a specification for **other agents** (callers) that describes how to invoke an agent and what to expect back. It is NOT for the agent itself — it is for the LLMs that will construct prompts and parse responses.

**Location:** `.claude/agents/interface-contracts/<agent-name>.contract.md`

**Audience:** Other agents, orchestrators, and the main Claude Code session that spawn this agent via the Agent tool.

## Required Sections

Every contract MUST include these three sections:

### Input

Describes what the calling agent must provide in its prompt.

**Include:**
- Required fields and their format
- Optional fields with defaults
- Example invocation prompts (at least one)
- Multi-mode inputs if the agent has different invocation modes

**Format guidance:**
- Use code blocks for structured input formats
- Mark fields as Required or Optional
- Show realistic examples, not placeholders

### Output

Describes what the agent returns to the caller.

**Include:**
- Output structure (sections, tables, fields)
- Status values and what each means
- What is returned directly vs written to files (if applicable)
- Example output for each status/mode

**Format guidance:**
- Use code blocks for structured output formats
- Cover all possible output statuses (success, failure, blocked, etc.)
- Specify what the caller should do with each output type

### Guarantees

Lists invariants the calling agent can rely on.

**Include:**
- What is always true about the output (format, completeness, verification)
- Behavioral guarantees (e.g., "every file path has been verified by reading")
- Scope limitations (e.g., "advisory only — cannot block creation")
- Consistency guarantees (e.g., "output format is identical regardless of findings")

**Format guidance:**
- Use a bulleted list
- Each guarantee should be a single, testable statement
- Only include guarantees the agent actually upholds

## Optional Sections

Include these when they add caller-relevant information:

### Severity/Status Definitions

When the agent produces categorized findings (e.g., CRITICAL/ERROR/WARNING/INFO), define each level so callers can interpret results correctly.

### Special Modes

When the agent supports multiple invocation modes (e.g., standard mode vs fix mode, full review vs phase-only review), document each mode's input and output separately.

### Structure Descriptions

When the output includes structured data (tables, nested sections), describe the schema so callers can parse it programmatically.

## Content Rules

1. **Use imperative language.** "Provide the file path" not "The file path should be provided."
2. **Use forward slashes** in all file paths. Never use backslashes.
3. **Do not expose internal details.** Step files, internal state machines, and implementation specifics belong in the agent's own files, not in its contract.
4. **Do not duplicate** content from the agent's definition files. The contract describes the interface, not the implementation.
5. **Cover all modes.** If the agent supports multiple invocation modes, document each one.
6. **Include example invocations.** Show realistic prompts a caller would use.
7. **Be precise about output structure.** Callers need to know exactly what fields to expect and in what order.

## Initiative Rules

When writing a contract, you MAY include information beyond what is explicitly listed in the agent's definition, under these constraints:

### Allowed

- Caller-relevant behavioral nuances (e.g., "returns empty array on no results")
- Error conditions and how the agent surfaces them
- Edge case handling that callers need to account for
- Default values for optional parameters

### Not Allowed

- Internal implementation details (step files, internal state)
- Speculative capabilities the agent does not explicitly support
- Opinions or recommendations about when to use the agent (that belongs in the description)
- Information duplicated from the agent's own definition files
- Instructions directed at the agent itself

**Guiding principle:** Include only what a calling agent needs to format its request correctly and parse the response correctly. When in doubt, leave it out.

## Structural Patterns

Scan the project for existing contracts to use as structural examples:

```
Glob .claude/agents/interface-contracts/*.contract.md
```

Read 1-2 existing contracts to understand the project's conventions. Use the archetypes below to choose which to reference:

| Archetype | Characteristics | Look For |
|-----------|----------------|----------|
| Simple | Single mode, single output, short guarantees | Smallest contract file |
| Multi-Mode | Multiple invocation paths, multiple output statuses | Contract with mode/type sections |
| Dual-Output | Writes file AND returns direct summary | Contract mentioning handoff files |

If no contracts exist in the project, follow the Required Sections format above as the sole guide.

## After Creating the Contract

1. **Place it** at `.claude/agents/interface-contracts/<agent-name>.contract.md`
2. **Update CLAUDE.md** — If the project's CLAUDE.md has an "Available Contracts" list, add the new contract to it
3. **Notify the user** that a contract was created and where it lives
