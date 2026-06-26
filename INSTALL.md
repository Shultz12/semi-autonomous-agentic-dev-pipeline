# Installing the Agentic Development Pipeline

The pipeline is a set of Claude Code **agents**, **skills**, and **hooks**. You install
it either into a **single project** (scoped to one repo) or into your **user-level**
Claude Code config (shared across every project). Both modes produce an identical
`.claude/` layout, so every internal reference resolves the same way either way.

The install is **additive**: it never overwrites or deletes a file you already have, and
it stops with an alert if it finds `agents/` or `skills/` directories that could collide.

---

## Requirements

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** — the pipeline runs
  entirely through it.
- **git** — used to clone the pipeline and (in the orchestrator) to manage worktrees.
- **bash** — `install.sh` is a POSIX `sh` script; Git Bash on Windows works.
- **jq _or_ python3** *(recommended, not required)* — used to merge the hooks into your
  `settings.json` cleanly. Without either, the installer prints the hook block for you to
  paste by hand; it never corrupts an existing `settings.json`.

Your **project must be a git repository with an `origin` remote and a `main` branch** —
see [The `origin/main` requirement](#the-originmain-requirement) below.

---

## Project-level install (recommended)

Scopes the pipeline to one repository. From your project root:

```bash
git clone <repo-url> .claude        # vendors the pipeline into .claude/
bash .claude/install.sh --project   # merges in the hooks, gitignores .claude/
```

`git clone <repo-url> .claude` makes the clone **target** `.claude/`, so `agents/`,
`skills/`, and `hooks/` land directly inside `<project>/.claude/`. (If `.claude/` already
exists and is non-empty, the clone refuses — which is also your collision protection here.)

What `install.sh --project` does:

1. Merges the three pipeline hooks into `<project>/.claude/settings.json`, using the
   project-scoped command base `${CLAUDE_PROJECT_DIR}/.claude/hooks/<script>.sh`.
2. Appends `.claude/` to your project `.gitignore` (and prints an alert) so the vendored
   clone is not committed into your repo. Skipped if it is already ignored.

It does **not** copy any files in project mode — the clone already placed them at
`<project>/.claude/`.

Then restart Claude Code (or run `/hooks`) so it picks up the hooks.

---

## User-level install

Applies the pipeline to **every** project you open with Claude Code. Clone to a throwaway
directory, then merge into `~/.claude`:

```bash
git clone <repo-url> /tmp/pipeline
bash /tmp/pipeline/install.sh --user   # merges into ~/.claude
```

What `install.sh --user` does:

1. **Collision guard** — if `~/.claude/agents/` or `~/.claude/skills/` already contains
   directories that are **not** part of this pipeline, it aborts and names them, changing
   nothing (see [Collisions](#collisions)).
2. **Additive merge** — copies `agents/ skills/ hooks/ documentation/ docs/` into
   `~/.claude/` with `cp -Rn` (no-clobber). Any same-named file you already have is kept,
   and an existing `~/.claude/.git` is preserved.
3. Merges the three hooks into `~/.claude/settings.json`, using the user-scoped command
   base `$HOME/.claude/hooks/<script>.sh` (`${CLAUDE_PROJECT_DIR}` is **not** used here —
   user settings apply across all projects).

There is **no gitignore step** for `--user`.

After it finishes you can delete the throwaway clone (`/tmp/pipeline`); update later by
re-cloning, or keep it and `git -C /tmp/pipeline pull` then re-run the installer.

---

## The hooks

The installer wires three hooks (it merges them in; it never replaces your `hooks` block):

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| `validate-bash-command.sh` | PreToolUse | `Bash` | Allowlists the Bash commands agents may run. |
| `protect-env-files.sh` | PreToolUse | `Read\|Edit\|Write\|NotebookEdit\|Grep\|Bash` | Blocks reads of secret `.env` files. |
| `enforce-subagent-output.sh` | SubagentStop | *(all)* | Blocks output-producing agents from returning without writing their file. |

Each script self-locates its support files from its own path (`$0`), so only the command
path in `settings.json` has to match your install level. `settings.template.json` (at the
repo root) shows the exact block for both levels for reference.

The wiring is **idempotent**: re-running the installer detects hooks already present (by
matching the resolved hooks path + script name) and adds nothing.

---

## The `origin/main` requirement

The orchestrator builds each feature inside a throwaway **git worktree** created from
`origin/main`:

```
git worktree add -b <slug> .worktrees/<leaf>/ origin/main
```

So your project needs:

- to be a **git repository** (`git init` if it is not),
- an **`origin` remote** with a **`main` branch** pushed to it.

For a brand-new project:

```bash
git init && git add -A && git commit -m "initial commit"
git remote add origin <your-remote-url>
git push -u origin main
```

You commit and push **your own work** to `main` normally; the pipeline only ever *reads*
`origin/main` to spin up worktrees and merges finished work back via `/accept-feature`.

---

## Updating

The pipeline is a vendored clone — update it in place with a `git pull`:

```bash
# project-level
git -C .claude pull

# user-level (from your throwaway clone, then re-run the installer)
git -C /tmp/pipeline pull && bash /tmp/pipeline/install.sh --user
```

Re-running `install.sh` after an update is safe and idempotent — it only adds hooks that
are missing.

---

## Collisions

The pipeline ships its own `agents/` and `skills/` directories. If you install at
`--user` level into a `~/.claude` that already has `agents/` or `skills/` of your **own**,
two things can go wrong: the no-clobber merge could leave a directory half-merged, or your
same-named files could shadow the pipeline's. To prevent that, the installer **stops with
an alert** and changes nothing when it finds non-pipeline directories under `agents/` or
`skills/`.

**Recommended:** install into a `.claude/` that has **no `agents/` or `skills/` of your
own**. Project-level install sidesteps this entirely (the clone goes into a fresh
`.claude/`). If you hit the alert at `--user` level, move your custom agents/skills aside,
re-run, then restore them under different names.

---

## Opting out of the gitignore (project level)

The project installer adds `.claude/` to your project `.gitignore` so the vendored clone
is not committed. If you would rather vendor the pipeline **into** your repo (commit it),
delete the `.claude/` line the installer added to `.gitignore`. Note that you then own
updates manually and lose the clean `git -C .claude pull` update path.

---

## Uninstalling

- **Hooks:** remove the three pipeline hook entries from your `settings.json`.
- **Project-level:** delete the `.claude/` directory and the `.claude/` line from
  `.gitignore`.
- **User-level:** remove the pipeline's `agents/`, `skills/`, and `hooks/` files from
  `~/.claude/` (the merge was additive, so anything you had before is still there).
