---
name: find-subagent-contract
description: Load this skill before invoking a subagent via the Agent tool when you do not yet know its interface contract. Provides a consistent, structured way for any agent or subagent to locate subagent contracts — gives the index and location of all available agent contracts so you can read the relevant one(s) before crafting the prompt. Invoke only once per session — after loading, the contract locations stay in context for all subsequent Agent calls.
domain: dev-tooling
user-invocable: false
---

# Find Subagent Contract

Interface contracts define the input a subagent expects and the output it produces. Reading the contract before spawning an agent ensures the prompt matches the agent's required inputs and that you parse its response correctly. This skill is the single, consistent entry point all agents use to find those contracts.

## Location

All contracts live at `.claude/agents/interface-contracts/<agent-name>.contract.md`.

## Protocol

1. Consult the index to find the contract for the agent you are about to spawn.
2. Read that contract file with the Read tool.
3. Craft the Agent prompt to satisfy the contract's Input section.
4. Parse the agent's response according to the contract's Output section.

If no contract exists for the target agent, the agent's own definition file (`.claude/agents/<name>/<name>.md`) is the source of truth — read that instead.

## Index

See `.claude/agents/interface-contracts/_index.md` for the list of available contracts with one-line descriptions.
