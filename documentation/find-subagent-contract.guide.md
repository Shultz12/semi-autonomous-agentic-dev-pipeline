# Find Subagent Contract Guide

## What It Does

Provides the main agent with the location and index of interface contracts for every subagent available via the Agent tool. When loaded, it tells the agent where to find the contract for whichever subagent it's about to spawn so it can read the Input/Output spec before crafting the prompt. It is the single, consistent entry point all agents and subagents use to discover those contracts.

**Key Points:**
- Points to the contracts directory (`.claude/agents/interface-contracts/`) and its `_index.md`
- Meant to be loaded once per session — after the main agent reads it, the contract locations stay in context
- Does not itself contain contract content; it directs the agent to the actual contract files
- Replaces the inline "Agent Contracts" section that previously lived in project `CLAUDE.md`

## When It's Used

Loaded automatically by the model the first time in a session that the main agent prepares to invoke a subagent via the Agent tool and does not already know that subagent's interface contract. It is not user-invocable — there is no slash command.

Subsequent Agent calls in the same session do not need to reload it, because the contract directory layout is already in context.

## The Protocol

| Step | Action |
|------|--------|
| 1 | Consult `.claude/agents/interface-contracts/_index.md` for the list of contracts |
| 2 | Read the specific contract file with the Read tool |
| 3 | Craft the Agent prompt to satisfy the contract's Input section |
| 4 | Parse the agent's response according to the contract's Output section |

If no contract exists for the target subagent, the agent's own definition file at `.claude/agents/<name>/<name>.md` is the source of truth.

## Limitations

- Does not enforce contract usage — it provides guidance, not a mechanism that blocks miswired Agent calls
- Does not describe individual contract content; readers must still open the specific contract file
- Index drift is possible if contracts are added or renamed without updating `_index.md`

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/find-subagent-contract/SKILL.md` | Skill definition (the protocol) |
| `.claude/agents/interface-contracts/_index.md` | One-line-per-contract index |
| `.claude/agents/interface-contracts/<name>.contract.md` | Individual agent contracts |
| `.claude/documentation/interface-contracts.guide.md` | Deeper background on what contracts are and why they exist |
