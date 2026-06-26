# Frontend Feature Discovery Prompts

This document contains essential questions to ask when gathering requirements for frontend features. Use these prompts to ensure comprehensive specifications.

## Core Identity

**Ask first:**

1. **What is the feature called?**
   - User-facing name (localized if applicable per project)
   - Internal code name
   - How will users refer to this feature?

2. **What user problem does this solve?**
   - Current pain point
   - Desired outcome
   - Success criteria
   - User story format: "As a [role], I want to [action], so that [benefit]"

3. **Is this a new page or an enhancement to existing functionality?**
   - New standalone page
   - New section on existing page
   - Enhancement/modification to current feature
   - Replacement of existing functionality

4. **Who are the target users?**
   - Roles: consult project CLAUDE.md for user role definitions
   - Technical proficiency level
   - Device preferences (mobile/desktop)
   - Accessibility needs

## Routing & Navigation

**Essential questions:**

1. **Which route group does this belong to?**
   - Consult project routing conventions (e.g., protected vs public route groups)
   - Which group and why?

2. **What is the exact route path?**
   - Full path with any dynamic segments
   - Route parameters
   - Query parameters
   - Route naming convention

3. **Where in the page hierarchy does this fit?**
   - Top-level page
   - Nested under existing page
   - Modal/dialog (no route change)
   - Drawer/sidebar panel

4. **How do users navigate to this page?**
   - Main navigation menu
   - Sidebar link
   - Button/action from another page
   - Direct link in email/notification
   - Breadcrumb trail

5. **What navigation changes are needed?**
   - Add menu item to main navigation
   - Add to sidebar navigation
   - Update breadcrumbs
   - Add to user dropdown menu
   - Update footer links

6. **Does this route have any parameters?**
   - Dynamic segments
   - Optional segments
   - Rest parameters
   - How are parameters validated?

7. **What happens on navigation?**
   - Save unsaved changes prompt
   - Confirmation dialog
   - Animation/transition
   - Loading state

## UI Components

**Key questions:**

1. **What components are needed?**
   - Check existing component library (consult codebase exploration results for component paths)
   - Can existing components be reused?
   - What modifications to existing components?
   - What truly new components are required?

2. **What is the layout pattern?**
   - Single column
   - Two-column sidebar
   - Grid layout (2-col, 3-col, 4-col)
   - Master-detail
   - Dashboard with cards
   - List with filters

3. **How should this behave responsively?**
   - Mobile (< 768px): Layout and behavior
   - Tablet (768px - 1024px): Layout and behavior
   - Desktop (> 1024px): Layout and behavior
   - Does layout completely change or just adjust?

4. **What are the different states?**
   - **Initial/Default**: First render
   - **Loading**: Data being fetched
   - **Empty**: No data to display (first-time user, search no results)
   - **Error**: Network error, permission denied, 404, 500
   - **Success**: Data loaded and displayed
   - **Partial**: Some data failed to load
   - Any other states?

5. **What loading states are needed?**
   - Skeleton loaders
   - Spinner/loading indicator
   - Progress bar
   - Streaming/partial content
   - Optimistic updates

6. **What empty states are needed?**
   - First-time user (onboarding prompt)
   - No search results
   - No items created yet
   - Filtered list returns nothing
   - Call-to-action for empty state?

7. **What error states are needed?**
   - Network error (offline, timeout)
   - Permission denied (403)
   - Not found (404)
   - Server error (500)
   - Validation error
   - Recovery actions for each error?

## State & Data

**Critical questions:**

1. **What state approach is needed?**
   - **Global state** (shared across multiple routes, persists across navigation):
     - Examples: session, theme, cart, notifications
     - Consult project CLAUDE.md for state management patterns
   - **Component state** (local UI state):
     - Form inputs, toggles, modals, dropdowns
   - **Server state** (API data):
     - Fetched from backend, cached and synchronized, loading/error handling

2. **What data needs to be fetched?**
   - API endpoints and methods
   - Request parameters: query params, path params, body
   - Response format: JSON shape
   - When to fetch: on mount, on user action, on interval

3. **How should API integration work?**
   - Existing API client patterns (consult codebase exploration results)
   - New endpoints needed
   - Authentication headers (consult project auth setup)
   - Error handling
   - Retry logic

4. **What loading states are needed?**
   - Initial page load
   - Infinite scroll pagination
   - Button loading (submit, save, delete)
   - Background refresh
   - Skeleton UI vs spinner

5. **Should there be optimistic updates?**
   - Update UI before API confirms
   - Roll back on error
   - Show pending state
   - Examples: like button, item deletion, form submission

6. **Is caching needed?**
   - Cache API responses
   - Cache duration
   - Invalidation strategy
   - Stale-while-revalidate pattern

7. **What derived state is needed?**
   - Computed from other state (per project's reactivity model)
   - Examples: filtered lists, totals, validation status
   - Performance considerations

## Forms & Validation

**Essential questions:**

1. **What input fields are required?**
   - Field name, type (text, email, number, select, checkbox, textarea)
   - Label (localized if applicable)
   - Placeholder (localized if applicable)
   - Help text
   - Required vs optional
   - Default values

2. **What validation rules apply?**
   - Required fields
   - Format validation: email, phone, URL, text patterns
   - Length constraints: min/max characters
   - Range constraints: min/max numbers
   - Pattern matching: regex
   - Custom business rules
   - Async validation: username availability, email uniqueness

3. **When should validation occur?**
   - On blur: First validation when user leaves field
   - On change: Revalidate after initial blur
   - On submit: Final validation before submission
   - Real-time: As user types (debounced)

4. **What are the error messages?**
   - Localize per project requirements (check CLAUDE.md for localization needs)
   - Required field message
   - Invalid format messages
   - Length constraint messages
   - Custom messages for business rules

5. **What is the submission flow?**
   - Submit button text (localized if applicable)
   - Loading state during submission
   - Success feedback: toast, redirect, inline message
   - Error handling: field errors, global errors
   - Disable form during submission

6. **Should validation align with backend?**
   - Check backend DTOs and validation decorators
   - Match validation rules exactly
   - Consistent error messages
   - Consult codebase exploration results for backend DTO paths

7. **Are there multi-step forms?**
   - Number of steps
   - Step titles
   - Progress indicator
   - Can user go back?
   - Save draft between steps?

8. **Auto-save or manual save?**
   - Auto-save on change (debounced)
   - Manual save with submit button
   - Unsaved changes warning

## Accessibility

**Required questions:**

1. **What are the screen reader requirements?**
   - Announcements for dynamic content (aria-live)
   - Labels for all inputs
   - Descriptive button text
   - Landmarks: header, nav, main, aside, footer
   - Heading hierarchy: h1 → h2 → h3

2. **How should keyboard navigation work?**
   - Tab order (logical flow)
   - Enter/Space for buttons
   - Arrow keys for lists, menus, tabs
   - Escape to close dialogs/menus
   - Keyboard shortcuts (if any)

3. **What focus management is needed?**
   - Focus on first input when page loads
   - Return focus after modal closes
   - Focus trap in dialogs
   - Visible focus indicator (2px outline, 3:1 contrast)
   - Skip links for long navigation

4. **What ARIA roles/attributes are required?**
   - Dialog: `role="dialog"`, `aria-modal="true"`, `aria-labelledby`
   - Menu: `role="menu"`, `role="menuitem"`, `aria-haspopup`, `aria-expanded`
   - Tabs: `role="tablist"`, `role="tab"`, `role="tabpanel"`, `aria-selected`
   - Forms: `aria-required`, `aria-invalid`, `aria-describedby`
   - Alerts: `role="alert"`, `aria-live="polite"`

5. **What are the color contrast requirements?**
   - Text: 4.5:1 minimum (normal), 3:1 (large text 18pt+)
   - Interactive elements: 3:1 minimum
   - Focus indicators: 3:1 minimum
   - Test with WebAIM contrast checker

6. **Are there any WCAG 2.2 AA specific needs?**
   - Perceivable: Text alternatives, captions, adaptable layouts
   - Operable: Keyboard access, timing controls, navigation
   - Understandable: Readable text, predictable behavior, input assistance
   - Robust: Valid HTML, ARIA compliance

## Localization

**Conditional — ask only if project CLAUDE.md specifies localization or RTL requirements.**

1. **What localization needs exist?**
   - Entire page is localized
   - Mixed-language content
   - Forms with localized inputs
   - Tables with localized headers
   - Navigation menus

2. **Are there bidirectional text challenges?**
   - Primary language text with embedded secondary language (brand names, technical terms)
   - Numbers in localized context
   - Punctuation handling

3. **What content should NOT change direction in RTL layouts?**
   - Phone numbers
   - URLs
   - Email addresses
   - Dates (ISO format)
   - Code snippets
   - Latin abbreviations

4. **Does localized input need validation?**
   - Accept only specific character sets
   - Accept mixed character sets
   - Regex patterns for character validation

5. **What CSS logical properties are needed for RTL?**
   - Replace `margin-left/right` with `margin-inline-start/end`
   - Replace `padding-left/right` with `padding-inline-start/end`
   - Replace `border-left/right` with `border-inline-start/end`
   - Replace `left/right` with `inset-inline-start/end`

6. **Are directional icons used?**
   - Arrows, chevrons: flip in RTL
   - Back/forward buttons: flip direction
   - Non-directional icons: no flip (close, check, etc.)

7. **What fonts with localized character support are required?**
   - System fonts with appropriate character set support
   - Test special character rendering if needed
   - Ensure consistent weight between character sets

## Styling

**Important questions:**

1. **What design tokens are needed?**
   - Colors: consult project design token source (check codebase exploration results for CSS variables / theme config)
   - Never use hardcoded hex/rgb colors
   - Check existing variables before requesting new ones

2. **Is dark mode support required?**
   - Yes (automatic via CSS variables)
   - Any dark-mode-specific adjustments?
   - Test in both themes

3. **What responsive breakpoints are needed?**
   - Mobile (< 640px)
   - Small tablet (640px - 768px)
   - Tablet (768px - 1024px)
   - Desktop (1024px - 1280px)
   - Large desktop (> 1280px)
   - Which breakpoints matter for this feature?

4. **Are animations needed?**
   - Transitions: fade, slide, scale
   - Duration: 150ms (fast), 300ms (medium), 500ms (slow)
   - Easing: ease-in-out, ease-out, spring
   - Respect `prefers-reduced-motion`
   - Examples: page transitions, modal open/close, notifications

5. **What spacing/sizing is needed?**
   - Container width
   - Padding
   - Gap between elements
   - Consistent with existing patterns?

6. **Any custom CSS required?**
   - Utility framework insufficient for this need
   - Component-scoped styles
   - CSS animations/keyframes
   - Complex grid layouts

## Icons

**Quick questions:**

1. **What icons are needed?**
   - List icon names
   - Check existing icon registry (consult codebase exploration results for icon system)
   - Can existing icons be reused?

2. **Any new icons to add?**
   - Not in existing icon registry
   - Add to centralized icon system per project conventions

3. **Icon usage patterns?**
   - Button icons (with text or icon-only)
   - Status indicators
   - Navigation icons
   - Decorative vs functional

4. **Icon sizing?**
   - Small: `h-4 w-4`
   - Medium: `h-5 w-5` (default)
   - Large: `h-6 w-6`
   - Extra large: `h-8 w-8`
   - Responsive sizing needed?

## Quality

**Final questions:**

1. **What browsers must be supported?**
   - Modern browsers (last 2 versions): Chrome, Firefox, Safari, Edge
   - Mobile browsers: Safari iOS, Chrome Android
   - Any legacy browser requirements?

2. **What are the performance targets?**
   - LCP (Largest Contentful Paint): ≤ 2.5s
   - INP (Interaction to Next Paint): ≤ 200ms
   - CLS (Cumulative Layout Shift): ≤ 0.1
   - JavaScript bundle: ≤ 200KB gzipped

3. **What test scenarios are needed?**
   - **Unit tests**: Utility functions, business logic
   - **Component tests**: User interactions, accessibility
   - **E2E tests**: Critical user flows
   - **Accessibility tests**: Automated checks (e.g., axe-core)
   - **Manual tests**: Screen reader, keyboard, RTL (if applicable)

4. **Are visual regression tests needed?**
   - Capture screenshots of key states
   - Compare before/after changes
   - Which pages/components?

5. **What are the critical user flows?**
   - Must-work scenarios
   - E2E test priorities
   - Happy path and error paths
   - Edge cases

6. **Any specific device testing needed?**
   - iPhone (Safari)
   - Android (Chrome)
   - iPad (Safari)
   - Desktop (Windows, macOS, Linux)
   - Screen sizes to test

## Integration Questions

**Additional context:**

1. **Are there backend dependencies?**
   - New API endpoints needed
   - Existing endpoints to modify
   - Backend spec written or pending?
   - API contract defined?

2. **Any third-party integrations?**
   - External APIs
   - Libraries/packages
   - Payment gateways
   - Analytics/tracking

3. **What permissions/roles are involved?**
   - Consult project CLAUDE.md for role definitions
   - Map each role to feature access level

4. **Is this related to existing features?**
   - Extends current functionality
   - Replaces old feature
   - Migrates from legacy
   - Standalone new feature

5. **What documentation is needed?**
   - User-facing help text
   - Tooltips/hints
   - In-app onboarding
   - External documentation
   - Developer documentation

## Discovery Process

**How to use these prompts:**

1. **Start with Core Identity**: Understand the "what" and "why"
2. **Map the Navigation**: Define routes and hierarchy
3. **Design the UI**: Components, layout, states
4. **Plan the State**: Data flow and management
5. **Specify Forms**: If applicable, detailed validation
6. **Ensure Accessibility**: WCAG compliance from the start
7. **Localization**: Address localization needs (if applicable per project)
8. **Style & Icons**: Design system integration
9. **Quality**: Testing and performance requirements
10. **Integration**: Dependencies and relationships

**Tips:**
- Not all sections apply to every feature
- Ask relevant questions based on feature type
- Clarify unknowns before writing spec
- Reference existing patterns and components
- Validate assumptions with stakeholders
- Document decisions and rationale

**Anti-patterns:**
- Don't assume answers without asking
- Don't skip accessibility questions
- Don't skip localization questions when the project requires them
- Don't forget to check existing components
- Don't ignore performance implications
- Don't spec in isolation (check dependencies)
