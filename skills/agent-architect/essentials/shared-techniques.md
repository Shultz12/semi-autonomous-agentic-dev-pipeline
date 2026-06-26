# Shared Techniques

Reusable techniques referenced by both create and update mode workflows.

## Question Techniques

**Lead with context:**
> "Since this is a code reviewer, it typically needs read-only access. Should I configure it with Read, Grep, and Glob tools only?"

**Offer recommendations:**
> "For validation tasks, I recommend the STOP & WAIT pattern to ensure you review findings before any action. Should I apply this?"

**Counter when appropriate:**
> "You mentioned using Opus, but for read-only review tasks, Sonnet provides sufficient capability at lower cost. Would you prefer Sonnet instead?"

## Pattern Selection

After understanding the agent's purpose, recommend patterns:

```
Based on what you've described, I recommend these patterns:

**Recommended:**
- STOP & WAIT - [reason specific to this agent]
- Search Before Code - [reason]

**Optional (let me know if you want these):**
- Loop Guards - [when this would help]
- Pre-computational Logic - [when this would help]

**Not applicable:**
- [Pattern] - [why it doesn't fit]
```

## File Loading Strategy

If the agent reads multiple files, determine strategy:

1. Is input scope known at start? (fixed path vs dynamic discovery)
2. Must check relationships between files?
3. Does agent delegate file reading to skills?

Based on answers, recommend:
- **Upfront**: Glob → Read all → Process (for fixed scope with cross-file checks)
- **Progressive**: Load as needed (for dynamic scope or independent files)
- **Delegated**: Skills load their own context (for orchestrators)

Document the chosen strategy in the agent's workflow.

## Model Selection

Always explain your model recommendation:

```
**Model Recommendation: sonnet**

Rationale: This agent performs [task type] which requires [capability].
Sonnet provides sufficient capability while being cost-effective.

Alternative considerations:
- Haiku would be faster but may miss nuanced [X]
- Opus would be overkill for this scope
```

## File Structure Planning

Propose the file structure:

```
**Proposed File Structure:**

.claude/
├── agents/
│   └── [agent-name]/
│       └── [agent-name].md
└── skills/
    └── [agent-name]/
        └── [skill-name]/
            └── SKILL.md

Should I add any supporting files (essentials, reference materials)?
```

## Domain Selection

After identifying the agent's primary purpose, determine the applicable domain:

1. Read [../domains/_index.md](../domains/_index.md) for the domain registry and decision matrix
2. Match the agent's purpose to a domain using the matrix criteria
3. If the purpose spans multiple domains, ask the user which is primary
4. If no domain fits:
   - Inform the user that no existing domain matches
   - Recommend creating a new domain
   - Suggest 3 candidate domain names and recommend one with rationale
   - Use AskUserQuestion to let the user pick a name or provide their own
   - Proceed without domain-specific resources for now; note the new domain in the summary's Pending Decisions

Once selected:
- Load the domain's `domain.md` for conventions and project scanning instructions
- Use the domain's patterns, templates, and examples during design
- Record the domain in the Agent Summary

## Iterative Refinement

Each response should:
1. Show updated summary
2. Acknowledge changes made
3. Ask clarifying questions OR suggest proceeding

**Acknowledge changes:**
> "I've added the Loop Guards pattern and updated the tool list. The summary now reflects these changes."

**Ask follow-ups:**
> "One thing we haven't covered: should this agent write its findings to a handoff file for other agents?"

## Instructional Consistency Check

Before finalizing agent files, verify:
- **Emphasis calibration**: Are NEVER/ALWAYS/MUST reserved for genuine safety constraints? If a constraint prevents data loss, unauthorized modification, or system damage, safety-level emphasis is appropriate. For design principles and process guidelines, use natural language instead.
- **Rationale presence**: Does each constraint explain why it exists? A constraint without rationale is a bare mandate — readers follow it less reliably because they can't judge its importance or adapt it to edge cases.
- **Self-demonstration**: Do the agent's own instructions follow any principles it teaches in its reference files? If a reference file says "explain the why," the agent's own constraints should have rationale.

If any constraint uses safety-level emphasis for a non-safety concern, suggest recalibrating to the user before proceeding to file creation.

## Readiness Check

When no pending decisions remain, proactively suggest proceeding:

```
The agent design looks complete:
- All required fields are defined
- Patterns are selected and justified
- File structure is determined
- No pending decisions remain
- Instructional consistency verified

Would you like me to proceed with validation and show you the final files for review?
```

## Behavioral Testing

After structural review (auditor), behavioral testing verifies the agent performs its stated purpose well.

**When to suggest:** After create/update completion, or on-demand via test mode.

**Key scripts** (in `scripts/` directory):
- `aggregate_benchmark.py` — Aggregates grading results into benchmark statistics
- `generate_review.py` — Generates browser-based review interface for human evaluation

**Key agents** (in `agents/` directory):
- `behavior-grader.md` — Evaluates behavioral assertions against agent outputs
- `behavior-analyzer.md` — Surfaces patterns across multiple test runs

**Workspace convention:** `.claude/agent-evals/<agent-name>/`, organized by iteration (`iteration-1/`, `iteration-2/`).

**Platform note:** Always use `--static` flag with `generate_review.py` to generate standalone HTML instead of starting a server.

## Behavioral Testing Offer

After announcing completion of create or update, offer behavioral testing:

> "Would you like to run behavioral tests on this agent? This spawns the agent with
> realistic test prompts and evaluates its output quality.
> (You can also do this later with `/agent-architect test [name]`)"

If user accepts, transition to test mode by reading `modes/test-agent.md` and following
its workflow from Phase 1.

## Review Integration

After files are created (or updated), follow this workflow:

### Step 1: Present Review Options

Use `AskUserQuestion` with 3 options:

- **question:** "Files created successfully. How would you like to handle the Agent Auditor review?"
- **header:** "Review mode"
- **options:**
  1. **label:** "Autonomous (Recommended)" — **description:** "Run auditor and apply all fixes automatically, then show summary"
  2. **label:** "User-guided" — **description:** "Run auditor, then let me pick which fixes to apply and provide custom instructions for others"
  3. **label:** "Skip review" — **description:** "Don't run auditor. You can run it manually later"

### Step 2: Execute Chosen Path

#### Path 1 — Autonomous

1. Spawn the `agent-auditor` sub-agent via the Agent tool:
   ```typescript
   Agent({
     subagent_type: "agent-auditor",
     prompt: "Review the agent definition at: .claude/agents/[name]/[name].md",
     description: "Review [name] agent"
   })
   ```
2. Parse results.
3. **If PASS:** Announce completion (see Completion Message below).
4. **If issues found:**
   - Apply ALL recommended fixes from the review.
   - Show a brief summary table of what was changed:
     ```
     | File | Issue | Fix Applied |
     |------|-------|-------------|
     | ... | ... | ... |
     ```
   - Inform user the full report is in the handoff file.
   - Announce completion.

#### Path 2 — User-Guided

1. Spawn the `agent-auditor` sub-agent (same Agent call as Path 1).
2. Parse results.
3. **If PASS:** Announce completion (see Completion Message below).
4. **If issues found:**
   - Present findings using `AskUserQuestion` with `multiSelect: true`:
     - **question:** "Select which issues to auto-fix per the auditor's recommendation. Use 'Other' to provide custom instructions for remaining items (e.g., 'For issue #3, do X instead' or 'What exactly is wrong with #5?')."
     - **header:** "Fix issues"
     - Each **option** = one finding:
       - **label:** `[SEVERITY] Brief title` (e.g., "WARNING Missing tool justification")
       - **description:** The auditor's recommended fix for that finding
     - If there are more than 4 findings, group by severity into batches of up to 4 and present sequentially.
   - Apply the toggled-on fixes using the auditor's recommendations.
   - If "Other" text contains custom instructions, follow them (apply alternative fixes, explain issues, etc.).
   - If "Other" text contains questions, answer them and re-present any remaining unresolved items.
   - Show summary of what was applied.
   - Inform user the full report is in the handoff file.
   - Announce completion.

#### Path 3 — Skip Review

Announce completion without running the auditor. Include a note that the user can run the Agent Auditor manually later.

### Completion Message

```
**Agent "[name]" is ready to use.**

Invoke it with:
- Sub-agent: Claude will delegate automatically based on task matching
- Skill: /[skill-name] (if skill was created)
```
