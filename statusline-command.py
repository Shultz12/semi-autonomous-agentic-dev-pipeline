#!/usr/bin/env python
"""Claude Code statusline script. Reads JSON from stdin, outputs a formatted status line."""

import json
import os
import subprocess
import sys


def format_tokens(count: int) -> str:
    if count >= 1_000_000:
        return f"{count / 1_000_000:.1f}M"
    if count >= 1_000:
        return f"{count / 1_000:.1f}k"
    return str(count)


def get_git_branch() -> str:
    try:
        result = subprocess.run(
            ["git", "--no-optional-locks", "branch", "--show-current"],
            capture_output=True, text=True, timeout=3
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return ""


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        return

    # Model name
    model = data.get("model", {}).get("display_name", "")
    if model.startswith("Claude "):
        model = model[7:]

    # Context window
    ctx = data.get("context_window", {})
    pct = ctx.get("used_percentage", 0)
    ctx_size = ctx.get("context_window_size", 0)
    input_tokens = ctx.get("total_input_tokens", 0)
    output_tokens = ctx.get("total_output_tokens", 0)

    # Progress bar (20 chars)
    filled = round(pct * 20 / 100)
    bar = "#" * filled + "-" * (20 - filled)

    # Color: green <51%, orange 51-74%, red 75%+
    if pct >= 75:
        color = "\033[31m"  # red
    elif pct >= 51:
        color = "\033[38;5;208m"  # orange
    else:
        color = "\033[32m"  # green
    reset = "\033[0m"

    used_tokens = round(pct * ctx_size / 100)
    tokens_str = f"I/O {format_tokens(input_tokens)}/{format_tokens(output_tokens)}"
    ctx_str = f"{color}[{bar}] {pct}% | {format_tokens(used_tokens)}/{format_tokens(ctx_size)}{reset} | {tokens_str}"

    # Project name
    project_dir = data.get("workspace", {}).get("project_dir", "")
    project = os.path.basename(project_dir) if project_dir else ""

    # Git branch
    branch = get_git_branch()
    branch_str = f"branch:{branch}" if branch else ""

    # Worktree (from workspace.git_worktree or worktree.name)
    worktree_name = (
        data.get("worktree", {}).get("name", "")
        or data.get("workspace", {}).get("git_worktree", "")
    )
    worktree_str = f"worktree:{worktree_name}" if worktree_name else ""

    # Combine branch and worktree
    git_str = "  ".join(p for p in [branch_str, worktree_str] if p)

    # Assemble parts
    parts = [p for p in [model, ctx_str, project, git_str] if p]
    print(" | ".join(parts))


if __name__ == "__main__":
    main()
