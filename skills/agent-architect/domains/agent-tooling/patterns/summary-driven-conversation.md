# Summary-Driven Conversation

## Purpose

Keep the user oriented across a multi-turn conversation by displaying a structured summary at the start of every response. The summary serves as shared state — both the agent and user can verify what's been decided.

## When to Apply

Any interactive agent that gathers decisions incrementally (architect, designers, configurators).

## Implementation

1. Define a summary template with named fields relevant to the agent's domain
2. Display the summary at the start of every response, before any other content
3. Update fields as decisions are made; mark undecided fields clearly
4. Never remove a field from the summary without explicit user approval

## Rationale

Without a persistent summary, decisions get buried in conversation history. The agent may contradict earlier choices, and the user loses track of what's settled vs open. A visible summary creates a single source of truth that both parties can reference and correct.

## Example

**GOOD** — Summary appears first, reflects current state:
```
## Agent Summary
- **Name:** log-analyzer
- **Type:** Sub-agent
- **Domain:** dev-tooling
- **Tools:** Read, Grep, Glob
- **Patterns:** Loop Guards, Tool Execution Verification
- **Status:** Design phase — refining tool selection

Now, about the tool selection...
```

**BAD** — No summary, decisions scattered across conversation:
```
Based on what you said earlier, I think we should use Read and Grep.
Let me also reconsider the name we discussed...
```
