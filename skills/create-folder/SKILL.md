---
name: create-folder
description: Enforces directory creation rules for agents — portable mkdir -p discipline, no redundant existence checks. Apply to any agent that creates directories or writes files to new paths.
domain: dev-tooling
user-invocable: false
---

# Directory Creation Rules

These rules govern how agents create directories. Following them ensures portability across tools and eliminates redundant shell calls.

## Steps

1. **Determine the target directory** from your output path or task instructions.
2. **Run `mkdir -p <path>`** via Bash before writing any files to the directory.
3. **Write files** to the directory using the Write tool.

## Rules

1. **Always `mkdir -p` before writing.** Run `mkdir -p` on the target directory before every Write call to a potentially new path. This ensures the directory exists regardless of which tool handles the write.
2. **Never check existence first.** Do not run `ls`, Glob, or any existence check before `mkdir -p`. The `-p` flag is idempotent — it succeeds whether the directory exists or not and never modifies existing contents. Checking first doubles tool calls for zero benefit.
3. **One command, multiple paths.** If you need several directories, combine them: `mkdir -p path/a path/b path/c`.
