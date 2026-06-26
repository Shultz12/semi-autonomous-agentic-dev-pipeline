# Update Mode

Full update workflow. Follow these phases sequentially.

## Phase 1: Target Identification

### If agent name provided in args

(e.g., `/agent-architect update code-reviewer`)

1. Glob for the agent in `.claude/agents/[name]/` and `.claude/skills/[name]/`
2. If found → proceed to Phase 2
3. If not found → report error, show available agents/skills list

### If no agent name provided

1. Glob `.claude/agents/*/` and `.claude/skills/*/`
2. Present list via AskUserQuestion: "Which agent would you like to update?"
3. User selects target

### Validation

- Confirm target exists
- Identify type (sub-agent or skill)
- Identify main definition file path

## Phase 2: Current State Loading

1. **Read main definition file:**
   - Sub-agent: `.claude/agents/[name]/[name].md`
   - Skill: `.claude/skills/[name]/SKILL.md`

2. **Discover and read ALL supporting files:**
   - Glob `[agent-dir]/**/*.md` for docs, modes, essentials, references
   - Glob `[agent-dir]/**/*.sh` for scripts
   - Glob `[agent-dir]/**/*.json` for configs
   - Read each file to understand full structure

3. **Read domain from agent definition:**
   - Check the YAML frontmatter for a `domain` field
   - If present: load the matched domain's `domain.md` for conventions
   - If missing: alert the user, recommend adding a domain field, and recommend a domain (or suggest creating a new one per [../essentials/shared-techniques.md > Domain Selection](../essentials/shared-techniques.md#domain-selection))
   - Record in summary's Domain field

4. **Parse into Agent Summary format:**
   - Extract: name, type, model, description, persona, mandate
   - Extract: responsibilities (numbered list)
   - Extract: patterns applied (with reasons)
   - Extract: tools allowed/disallowed
   - Extract: complete file tree with purposes
   - Extract: inter-agent communication (if any)
   - Set "Pending Decisions" to empty (existing agent is complete)
   - Set "Recent Changes" to empty (no changes yet)

4. **Present loaded summary:**

   > "Here's the current state of **[agent-name]**:"
   >
   > [Full Agent Summary]
   >
   > "What changes would you like to make?"

## Phase 3: Change Discovery

1. **Open-ended first:** Ask what the user wants to change

2. **Targeted follow-ups:** Based on response, use progressive questioning
   (see [shared-techniques.md > Question Techniques](../essentials/shared-techniques.md#question-techniques))

3. **Track changes in summary:**
   - `[~] Modified:` for changes to existing items
   - `[+] Added:` for new items
   - `[-] Removed:` for deletions (require explicit user approval first)

4. **Scope awareness table** — maintain and show:

   | File | Change Type | Description |
   |------|-------------|-------------|
   | [path] | Modified | [what changes] |
   | [path] | New | [why needed] |
   | [path] | Deleted | [why, with approval] |

5. **Domain changes:** If the update changes the agent's fundamental purpose such that a different domain applies, re-select the domain and reload domain-specific resources

6. **Impact analysis:** If a change cascades (e.g., adding tools → update validation
   script, adding patterns → update supporting files), identify and note all impacts

7. **Pipeline role check:** If the agent under update participates in the feature pipeline, load [../references/pipeline-role-templates.md](../references/pipeline-role-templates.md) and verify every applicable role's rule content is still present in the agent's prose. Add, reword, or section any missing content in the host's voice. Do not replace existing embedded rule content with a cross-reference to the templates file — the templates exist to guide authoring, not as a runtime dependency of the agent being updated.

8. **Self-commit check:** If the agent writes files into the project repository, verify it has a final commit step referencing `commit-to-git` via progressive disclosure; add one if missing, following [../references/self-commit.md](../references/self-commit.md). If it writes only user-level files, no commit step is needed. Record the decision in the summary.

## Phase 4: Refinement

Same iterative loop as create mode:
- Show updated summary every response (with Recent Changes tracking)
- Acknowledge changes made
- Ask clarifying questions OR suggest proceeding
- **Wording rule:** Write all content — new or modified — as if it was always part of the agent. No language implying content was "added" or "changed from" something. The agent's next instance has no awareness of prior versions.
- **Deduplication rule:** When removing duplicated content, check the agent's file loading order (workflow Step 1 or equivalent). If the source file is already loaded before the point where the duplicate existed, delete the duplicate entirely — do not replace it with a cross-reference. LLM agents retain loaded files in context; "See X" pointing to something already in context is redundant.
- See [shared-techniques.md > Iterative Refinement](../essentials/shared-techniques.md#iterative-refinement)
- See [shared-techniques.md > Readiness Check](../essentials/shared-techniques.md#readiness-check)

When all changes captured and no pending decisions remain → suggest proceeding.

## Phase 5: Validation & Update

### Validation

Run standard checklist (from SKILL.md) PLUS update-specific checks:
- [ ] No unintended changes to files outside modification scope
- [ ] All existing functionality preserved unless explicitly changed
- [ ] File tree reflects additions/removals accurately
- [ ] If updating agent-architect itself: check whether agent-auditor needs a corresponding update (they are coupled counterparts — architect produces what auditor validates)

### File Preview

Show COMPLETE file contents for ALL modified and new files:
- Full file content (not diffs) — consistent with create mode
- For deleted files: list with confirmation
- Format: "File N of M: [path] (Modified|New|Deleted)"
- Clear separation between files

```
**File 1 of 3: .claude/agents/[name]/[name].md (Modified)**

---
[complete file contents]
---

**File 2 of 3: .claude/agents/[name]/essentials/new-file.md (New)**

---
[complete file contents]
---

**File 3 of 3: .claude/agents/[name]/essentials/old-file.md (Deleted)**

Confirm deletion of this file? [Yes / No]

---

Please review the files above. Reply with:
- "Update" to proceed with changes
- Specific feedback to make adjustments
```

### Approval & Write

- Wait for explicit approval
- Write/edit files only after approval
- Do NOT announce completion — proceed to Phase 6

## Phase 6: Review & Completion

See [shared-techniques.md > Review Integration](../essentials/shared-techniques.md#review-integration) for the full workflow:
1. Request agent-auditor permission
2. If approved: spawn reviewer via Agent tool
3. Handle results (issues found / no issues / skipped)
4. Announce completion

### Behavioral Testing

See [shared-techniques.md > Behavioral Testing Offer](../essentials/shared-techniques.md#behavioral-testing-offer).
