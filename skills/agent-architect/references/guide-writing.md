# Guide Writing Reference

How to create human-facing guides for agents and skills.

## What Is a Guide

A guide is documentation for **humans** (users, maintainers) that explains what an agent or skill does, when to use it, and how it works at a high level. It is NOT for the agent itself — it is for the people who will interact with or manage the agent.

**Location:** `.claude/documentation/<name>.guide.md`

**Audience:** Humans who need to understand, use, or troubleshoot an agent or skill.

## Required Sections

Every guide MUST include these sections:

### Header

`# [Name] - User Guide` or `# [Name] Guide`

Establishes the document identity. Use the agent's display name (e.g., "Agent Auditor", "Plan Architect").

### What It Does

Overview of the agent's purpose and capabilities.

**Include:**
- A one-sentence summary of what the agent does
- "Key Points" list with 3-5 bullet points covering the most important things to know
- Use analogies if helpful ("Think of it as a quality control inspector")

### When It's Used (or close variant)

Describes when and how the agent is invoked.

**Include:**
- What triggers the agent (manual, automatic, pipeline position)
- Common scenarios as a bulleted list or table
- Invocation examples if user-invocable

### Main Content Sections

The middle sections are flexible and adapt to the agent type. See [Flexibility Guidance](#flexibility-guidance) for how to choose.

### Limitations

What the agent cannot do or where it falls short.

**Include:**
- Scope boundaries (e.g., "Advisory only - cannot prevent creation")
- Known limitations of the approach (e.g., "Pattern detection is heuristic")
- What users should NOT expect from this agent

### Related Files / Related Documentation

Links to related agents, contracts, source files, and other guides.

**Include:**
- Path to the agent's definition file
- Path to the interface contract (if one exists)
- Paths to key supporting files
- Links to related guides (use relative links between guides)

## Optional Sections

Include these when they add value for the reader:

### Common Scenarios

Worked examples showing typical interactions. Useful for interactive or user-invoked agents.

### Troubleshooting

Common problems and their solutions. Best for agents with complex behavior or common failure modes.

### Output Guarantees / Understanding the Report

When the agent produces structured output that users need to interpret. Explain the format, status values, and how to act on results.

### Tips for Success / Tips for Best Results

Practical advice for getting the most out of the agent.

## Content Rules

1. **Write for humans, not agents.** Use plain language. Avoid internal implementation jargon.
2. **No internal implementation details.** Step files, internal state machines, and validation logic belong in the agent's own files, not in its guide.
3. **Use tables and code blocks** for structured information. Tables for comparisons and mappings, code blocks for file trees and examples.
4. **Use relative links** between guides (e.g., `[Agent Auditor](agent-auditor.guide.md)`).
5. **Keep it practical.** Focus on what users need to know to use the agent effectively.
6. **Use forward slashes** in all file paths. Never use backslashes.
7. **Match the depth to the complexity.** Simple agents get short guides. Complex interactive agents get detailed guides with scenarios and troubleshooting.

## Flexibility Guidance

The middle content sections adapt to the agent type. Choose based on what the agent does:

| Agent Type | Typical Middle Sections |
|------------|------------------------|
| Reviewer/Validator | "What It Checks" (categorized checks), "Understanding the Report" (output format), "Tips for Passing Review" |
| Interactive/Conversational | Phase-by-phase process, "Understanding the Summary", "Common Scenarios", "Troubleshooting" |
| Pipeline/Automated | "Input" and "Output" sections, "Understanding [Feature]" for key concepts, "Error Handling" |
| Developer/Implementer | "Personas" or "Modes", "Understanding [Loop/Process]", "Tips for Best Results" |

**Guiding principle:** Include what helps a human understand and use the agent. When in doubt, ask: "Would a user need to know this?"

## Structural Patterns

Scan the project for existing guides to use as structural examples:

```
Glob .claude/documentation/*.guide.md
```

Read 1-2 existing guides to understand the project's conventions. Use the archetypes below to choose which to reference:

| Archetype | Characteristics | Look For |
|-----------|----------------|----------|
| Simple | Short, focused on personas/modes/tips | Shortest guide file |
| Complex Interactive | Detailed phases, scenarios, troubleshooting | Guide for user-invoked agents |
| Pipeline | Input/output focus, multiple modes, structured I/O | Guide for automated/pipeline agents |

If no guides exist in the project, follow the Required Sections format above as the sole guide.

## After Creating the Guide

1. **Place it** at `.claude/documentation/<agent-name>.guide.md`
2. **Notify the user** that a guide was created and where it lives
