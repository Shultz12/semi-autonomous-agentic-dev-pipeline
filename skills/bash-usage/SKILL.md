---
name: bash-usage
description: Enforces Bash tool usage rules for agents — path discipline, no unnecessary diagnostics. Apply to any agent that uses the Bash tool.
domain: dev-tooling
user-invocable: false
---

# Bash Usage Rules

These rules govern how agents invoke the Bash tool. Following them reduces token waste, avoids noisy output, and keeps commands portable across environments.

1. **Stay in the working directory.** Never prefix commands with `cd <project-root> &&`. The shell starts in the project root — run commands from there.
2. **Use relative paths** for all project files. Absolute paths waste tokens and break portability.
3. **No diagnostic commands unless instructed.** Never run `git log`, `git diff`, `git status`, `git show`, `npm run build`, `npm run lint`, or similar unless your task instructions explicitly require it or the user asks — unsolicited diagnostic output consumes context tokens and creates noise in agent responses.
4. **Fix paths, don't retry with absolutes.** If a command fails due to a path issue, correct the relative path — falling back to absolute paths masks the underlying error rather than fixing it.
5. **Prefer dedicated tools over Bash.** Use Read (not `cat`), Edit (not `sed`), Grep (not `grep`/`rg`), Glob (not `find`/`ls`) — reserve Bash for commands that genuinely require shell execution.
