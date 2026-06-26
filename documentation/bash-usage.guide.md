# Bash Usage Guide

## What It Does

Enforces a consistent set of rules for how all agents use the Bash tool in Claude Code projects.

**Key Points:**
- Keeps agents working from the project root — no unnecessary `cd` commands
- Requires relative paths to reduce token waste and improve portability
- Blocks unsolicited diagnostic commands (`git status`, `npm run build`, etc.) that create noise
- Directs agents to prefer dedicated tools (Read, Edit, Grep, Glob) over shell equivalents

## When It's Used

This skill is loaded automatically by the model when an agent uses the Bash tool. It is not user-invocable — there's no slash command for it.

It applies to every agent that runs shell commands: developer, test-runner, code-investigator, and any other agent with Bash access.

## The Rules

| # | Rule | Why |
|---|------|-----|
| 1 | Stay in the working directory | The shell starts in the project root — no need for `cd <root> &&` prefixes |
| 2 | Use relative paths | Absolute paths waste tokens and break portability across machines |
| 3 | No diagnostic commands unless instructed | Unsolicited output (git log, npm build) consumes context and creates noise |
| 4 | Fix paths, don't retry with absolutes | Falling back to absolute paths masks the real path error |
| 5 | Prefer dedicated tools over Bash | Read/Edit/Grep/Glob are purpose-built and produce better output than cat/sed/grep/find |

## Limitations

- Does not restrict which Bash commands agents can run — it provides behavioral guidance, not enforcement
- Cannot prevent an agent from ignoring the rules if its own instructions conflict
- Only covers Bash tool usage, not other tools

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/bash-usage/SKILL.md` | Skill definition (the rules themselves) |
