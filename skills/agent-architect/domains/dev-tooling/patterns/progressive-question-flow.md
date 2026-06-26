# Progressive Question Flow

**Purpose**: Gather information systematically without overwhelming.

## When to Apply

- Interactive agents
- Design/planning conversations
- Requirements gathering

## Implementation

```markdown
## Question Tiers

**Tier 1 - Core** (ask first)
Questions that define the fundamental nature of the task.

**Tier 2 - Behavior** (after Tier 1)
Questions about how it should work.

**Tier 3 - Technical** (after Tier 2)
Questions about implementation details.

**Tier 4 - Refinement** (after Tier 3)
Questions about edge cases and polish.

**Rules**:
- Ask 1-2 questions at a time
- Wait for answers before next tier
- Offer recommendations with questions
- Counter-suggest when appropriate
```

## Example Tier Progression

**Tier 1**: "What is the primary purpose of this agent?"
**Tier 2**: "What should trigger this agent - manual or automatic?"
**Tier 3**: "What tools does it need access to?"
**Tier 4**: "Any specific constraints or edge cases to handle?"

## Rationale

Asking all questions at once overwhelms the user and produces shallow answers. Tiered questioning lets each answer inform the next question, surfacing more relevant and specific details than a flat questionnaire would. A Tier 1 answer like "this is a code reviewer" makes Tier 2 questions about trigger conditions meaningful — questions that would have been premature without knowing the agent's purpose.

## Example

**GOOD** — Progressive flow surfaces relevant details:
```
Tier 1: "What is this agent's purpose?" → "Review PR code quality."
Tier 2: "Should it run automatically on PR creation or on-demand?" → "Automatic."
Tier 3: "What checks should it run — lint, types, tests, or all?" → "Lint and types only."
→ Each question is informed by the previous answer. No wasted questions about manual triggers.
```

**BAD** — All questions at once:
```
"What is the purpose? What triggers it? What tools does it need?
What checks should it run? Any edge cases? What model should it use?
Should it write files? What's the output format?"
→ User gives brief, shallow answers to 8 questions.
→ Agent misses that "automatic on PR" implies it needs GitHub webhook context.
```
