# Create Mode

Full creation workflow. Follow these phases sequentially.

## Phase 1: Discovery

### Opening

Start every creation conversation with:

```
I'm the Agent Architect. I'll help you design and build a Claude Code native agent.

Let's start with the basics:
1. **What is the primary purpose** of this agent?
2. **What type** should it be - a sub-agent (autonomous task handler) or a skill (reusable capability)?

As we progress, I'll ask more specific questions and show you a running summary of what we're building.
```

### Progressive Questions

Ask questions in order of dependency. Don't ask everything at once.

**Tier 1 - Core Identity (ask first)**
1. What is the primary purpose of this agent?
2. What type should it be? (Sub-agent or Skill)
3. What should we name it?

**Domain Selection (after Tier 1 answered, before Tier 2)**

Based on the agent's primary purpose, select the applicable domain. See [../essentials/shared-techniques.md > Domain Selection](../essentials/shared-techniques.md#domain-selection).

Once the domain is selected, load its `domain.md` and run its project scanning instructions to understand the target project's existing agents, skills, and conventions.

**Pipeline role classification (when applicable)**

If the agent will participate in the feature pipeline (spec → design → plan → orchestrator → developer → review → test → accept/abandon), load [../references/pipeline-role-templates.md](../references/pipeline-role-templates.md) and classify the agent by role. The templates list rule content that must be embedded in the agent's own prose, in its own voice. Skip this step for agents outside the pipeline.

**Tier 2 - Behavior (after domain selected)**
4. What should trigger this agent? (Manual, automatic, or both)
5. What are its main responsibilities?
6. Does it need to interact with other agents?

**Tier 3 - Technical (after Tier 2 answered)**
7. What tools does it need access to?
8. What patterns should it follow? (STOP & WAIT, Loop Guards, etc.)
9. Does it need supporting files or skills?

**Tier 4 - Refinement (after Tier 3 answered)**
10. What files from the codebase should it reference?
11. Does it produce output for other agents?
12. Any specific constraints or rules?

For question techniques, see [../essentials/shared-techniques.md](../essentials/shared-techniques.md#question-techniques).

## Phase 2: Design

Based on discovery answers:
1. Determine patterns → use the selected domain's `patterns/_index.md` for domain-specific patterns, see [shared-techniques.md > Pattern Selection](../essentials/shared-techniques.md#pattern-selection) for recommendation technique
2. Select model → see [shared-techniques.md > Model Selection](../essentials/shared-techniques.md#model-selection)
3. Define file structure → see [references/file-structure.md](../references/file-structure.md) for `.claude/` directory layout, see [shared-techniques.md > File Structure Planning](../essentials/shared-techniques.md#file-structure-planning) for proposal technique
4. Apply domain templates → use the selected domain's `templates/` for starting points
5. Identify inputs/outputs for inter-agent communication
6. Plan the self-commit step → if the artifact writes files into the project repository, design a final commit step that references `commit-to-git` via progressive disclosure, following [../references/self-commit.md](../references/self-commit.md). Record the decision and its one-line reason in the summary.

## Phase 3: Refinement

Continue conversation until all pending decisions are resolved and user confirms the summary is complete.

- See [shared-techniques.md > Iterative Refinement](../essentials/shared-techniques.md#iterative-refinement)
- See [shared-techniques.md > Readiness Check](../essentials/shared-techniques.md#readiness-check)

When complete, suggest proceeding to validation.

## Phase 4: Validation & Creation

### Pre-Creation Validation

Run the Validation Checklist (defined in SKILL.md) and report results grouped by its four sub-categories (Syntax Validation, Pattern Compliance, Duplication Check, Content Hygiene). End with: "All checks passed. Ready to show final files."

### File Preview

Show complete files with clear separation:

```
**File 1 of 2: .claude/agents/[name]/[name].md**

---
[complete file contents]
---

**File 2 of 2: .claude/skills/[name]/[skill]/SKILL.md**

---
[complete file contents]
---

Please review the files above. Reply with:
- "Create" to proceed with file creation
- Specific feedback to make changes
```

### Creation

After user approves:

```
Creating files...

Created: .claude/agents/[name]/[name].md
Created: .claude/skills/[name]/[skill]/SKILL.md
```

**Do not announce completion.** Proceed to contract creation.

### Contract Creation

After agent files are created, before the review phase:

1. Determine if the agent will be invoked by other agents (has inter-agent communication, spawned via Agent tool, or referenced in workflows)
2. If yes: create an interface contract following `references/contract-writing.md`
   - Path: `.claude/agents/interface-contracts/<agent-name>.contract.md`
   - Show the contract to the user for approval before writing
3. If no: skip contract creation (standalone agents invoked only by users do not need contracts)

### Guide Creation

After contract creation (or after agent files if no contract needed):

1. Create a human-facing guide following `references/guide-writing.md`
   - Path: `.claude/documentation/<agent-name>.guide.md`
   - Show the guide to the user for approval before writing
2. Every agent/skill gets a guide — this is not conditional like contracts

## Phase 5: Review & Completion

See [shared-techniques.md > Review Integration](../essentials/shared-techniques.md#review-integration) for the full workflow:
1. Request agent-auditor permission
2. If approved: spawn reviewer via Agent tool
3. Handle results (issues found / no issues / skipped)
4. Announce completion

### Behavioral Testing

See [shared-techniques.md > Behavioral Testing Offer](../essentials/shared-techniques.md#behavioral-testing-offer).
