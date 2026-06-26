# Frontend Review Criteria

Frontend-specific validation. These rules supplement the universal rules in `essentials/review-rules.md`.

Read the project's CLAUDE.md before reviewing to load critical constraints and guardrails. If CLAUDE.md references separate context files for frontend conventions, read the frontend context file — it contains wiring verification patterns, forbidden syntax lists, and styling rules needed for review.

---

## What to Look For in Project Documentation

Before reviewing, locate and internalize these from the project's CLAUDE.md and frontend context:

### Framework Syntax
- Required syntax version/style (e.g., specific API, modern vs legacy patterns)
- Forbidden legacy patterns — list of patterns that must not appear in new code
- Scan modified files for any forbidden patterns listed in CLAUDE.md
- Any forbidden pattern in new/modified code is ERROR

### Component Conventions
- File naming conventions (PascalCase, kebab-case, etc.)
- Props typing requirements
- One-component-per-file rules
- Slot/children rendering patterns

### Icons & Assets
- Whether icons use a centralized index or direct imports
- Which icon library is used and the correct import path
- Direct imports bypassing the centralized system (if one exists) is ERROR

### Styling
- CSS variable system — search for hardcoded color values (hex codes, rgb values)
- Hardcoded colors that should use CSS variables are WARNING
- Conditional class composition utility (if any)
- String concatenation for conditional classes when a utility exists is WARNING

### State Management
- Global vs local state patterns and which primitives to use
- Forbidden legacy state patterns
- Misuse of state primitives (e.g., mutable state where derived is correct) is WARNING

### Route Organization
- Route groups and their purpose (protected, public, etc.)
- New routes placed in the wrong group is ERROR

### Shared Utilities Catalog
- UI components, utilities, auth helpers, and their locations
- Check these BEFORE flagging "missing utility"
- Recreating functionality that exists in shared utilities is WARNING

### Verification Command
- The lint + build command for frontend code
- Use this for Step 4 diagnostics
