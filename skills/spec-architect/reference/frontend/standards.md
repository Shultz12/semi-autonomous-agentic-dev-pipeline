# Frontend Specification Standards

This document defines comprehensive standards for writing frontend specifications.

---

## Table of Contents

| Section | Line | Description |
|---------|------|-------------|
| [Accessibility (WCAG 2.2 AA)](#accessibility-wcag-22-aa-compliance) | 24 | Four principles, ARIA patterns, accessibility checklist |
| [Localization / RTL Support](#localization--rtl-support) | 131 | CSS logical properties, bidirectional text, locale requirements |
| [Components](#components) | 228 | Framework patterns, component spec format, existing UI components |
| [State Management](#state-management) | 333 | Global state, component state, derived state |
| [Forms](#forms) | 407 | Validation timing, schemas, localized error messages |
| [Performance](#performance) | 510 | Core Web Vitals, JS budget, image optimization, lazy loading |
| [Responsive Design](#responsive-design) | 597 | Breakpoints, mobile-first, touch targets |
| [Styling](#styling) | 662 | CSS methodology, design tokens, conditional classes |
| [Icons](#icons) | 740 | Centralized icon system, adding new icons |
| [Testing](#testing) | 792 | Unit, component, E2E, accessibility testing |
| [Security](#security) | 915 | XSS prevention, CSRF, role-based UI |
| [Authentication](#authentication) | 975 | Client setup, session state, guards, route groups |
| [Specification Checklist](#specification-checklist) | 1093 | Final validation checklist for all frontend specs |

---

## Accessibility (WCAG 2.2 AA Compliance)

### Four Principles

#### 1. Perceivable
- **Text Alternatives**: All non-text content must have text alternatives
- **Time-based Media**: Provide captions and transcripts
- **Adaptable**: Content can be presented in different ways without losing information
- **Distinguishable**: Make it easy to see and hear content (minimum contrast 4.5:1 for normal text, 3:1 for large text)

#### 2. Operable
- **Keyboard Accessible**: All functionality available via keyboard
- **Enough Time**: Users have enough time to read and use content
- **Seizures**: Nothing that flashes more than 3 times per second
- **Navigable**: Ways to help users navigate and find content
- **Input Modalities**: Functionality available through various inputs beyond keyboard

#### 3. Understandable
- **Readable**: Text content is readable and understandable
- **Predictable**: Web pages appear and operate in predictable ways
- **Input Assistance**: Help users avoid and correct mistakes

#### 4. Robust
- **Compatible**: Maximize compatibility with current and future user agents (browsers, assistive technologies)
- **Valid HTML**: Use semantic HTML elements correctly
- **ARIA**: Use ARIA attributes only when native HTML is insufficient

### Common ARIA Patterns

#### Dialog (Modal)
```html
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="dialog-title"
  aria-describedby="dialog-description"
>
  <h2 id="dialog-title">Dialog Title</h2>
  <p id="dialog-description">Description of the dialog content</p>
  <!-- Focus trap implementation required -->
  <!-- ESC to close required -->
  <!-- Focus return to trigger element on close -->
</div>
```

#### Menu (Dropdown)
```html
<button
  aria-haspopup="true"
  aria-expanded="false"
  aria-controls="menu-id"
>
  Menu Button
</button>
<ul id="menu-id" role="menu" aria-labelledby="menu-button">
  <li role="menuitem">
    <button>Menu Item</button>
  </li>
</ul>
```

#### Tabs
```html
<div role="tablist" aria-label="Tab group label">
  <button
    role="tab"
    aria-selected="true"
    aria-controls="panel-id"
    id="tab-id"
    tabindex="0"
  >
    Tab Label
  </button>
</div>
<div id="panel-id" role="tabpanel" aria-labelledby="tab-id" tabindex="0">
  Panel content
</div>
```

#### Forms
```html
<label for="field-id">
  Field Label
  <span aria-label="required">*</span>
</label>
<input
  id="field-id"
  aria-required="true"
  aria-invalid="false"
  aria-describedby="error-id"
/>
<div id="error-id" role="alert" aria-live="polite">
  Error message here
</div>
```

### Accessibility Checklist
- [ ] All interactive elements are keyboard accessible (Tab, Enter, Space, Arrow keys)
- [ ] Focus is visible with clear outline (min 2px, contrast 3:1)
- [ ] Focus order is logical (follows visual order)
- [ ] Skip links provided for navigation
- [ ] All images have alt text (decorative images: alt="")
- [ ] Color is not the only means of conveying information
- [ ] Text can be resized up to 200% without loss of functionality
- [ ] Form inputs have associated labels
- [ ] Error messages are announced to screen readers (aria-live)
- [ ] Interactive elements have minimum 44x44px touch target
- [ ] Page has descriptive title (changes on route changes)
- [ ] Language is declared (lang attribute on html element)
- [ ] Headings form a logical outline (h1 → h2 → h3, no skipping)

## Localization / RTL Support

> **Applicability**: This section applies when the project requires RTL layout support or localization. Check project CLAUDE.md for locale requirements. Even for LTR-only projects, CSS logical properties are recommended as a best practice.

### CSS Logical Properties
**Use logical properties instead of directional ones for layout resilience:**

```css
/* Recommended (works in both LTR and RTL) */
margin-inline-start: 1rem;  /* replaces margin-left */
margin-inline-end: 1rem;    /* replaces margin-right */
padding-inline-start: 1rem; /* replaces padding-left */
padding-inline-end: 1rem;   /* replaces padding-right */
border-inline-start: 1px;   /* replaces border-left */
border-inline-end: 1px;     /* replaces border-right */
inset-inline-start: 0;      /* replaces left */
inset-inline-end: 0;        /* replaces right */

/* Avoid for RTL-aware layouts */
margin-left: 1rem;
padding-right: 1rem;
```

**Tailwind RTL Utilities (if using Tailwind):**
```html
<div class="ms-4 me-2 ps-6 pe-4">
  <!-- ms = margin-inline-start, me = margin-inline-end -->
  <!-- ps = padding-inline-start, pe = padding-inline-end -->
</div>
```

### Elements That Don't Flip (LTR in RTL Context)

Certain content must remain LTR even in RTL layouts:

```html
<!-- Phone numbers -->
<span dir="ltr">+1-555-123-4567</span>

<!-- URLs -->
<a href="..." dir="ltr">https://example.com</a>

<!-- Email addresses -->
<span dir="ltr">user@example.com</span>

<!-- Code snippets -->
<code dir="ltr">const x = 10;</code>

<!-- Numbers with Latin digits -->
<span dir="ltr">1,234.56</span>
```

### Font Requirements
- Include locale-appropriate fonts in the font stack
- System fonts provide good coverage on modern OS
- Test all fonts for proper diacritical mark rendering if needed
- Ensure consistent font weight between different scripts
<!-- Consult project CLAUDE.md for locale-specific font requirements -->

### Bidirectional Text Handling
```html
<!-- Explicit direction setting -->
<html lang="[locale]" dir="[rtl|ltr]">

<!-- Mixed content -->
<p dir="rtl">
  Right-to-left text with <span dir="ltr">embedded LTR</span> content
</p>

<!-- Auto direction detection (use sparingly) -->
<p dir="auto">{userGeneratedContent}</p>
```

### RTL Layout Patterns
```html
<!-- Flexbox: row reverses automatically in RTL -->
<div style="display: flex; flex-direction: row; gap: 1rem;">
  <!-- Items appear right-to-left in RTL -->
</div>

<!-- Absolute positioning with logical properties -->
<div style="position: absolute; inset-inline-start: 0;">
  <!-- Positioned at right edge in RTL, left in LTR -->
</div>

<!-- Icons: use transform for directional icons -->
<!-- Directional icons (arrows, chevrons) should flip in RTL -->
<!-- Non-directional icons (close, check) should NOT flip -->
```

### Localization Checklist
- [ ] All spacing uses logical properties (ms-, me-, ps-, pe- or inline-start/end)
- [ ] Layout tested in target locale direction
- [ ] Phone numbers, URLs, emails marked with dir="ltr" (if RTL project)
- [ ] Icons that indicate direction are flipped (arrows, chevrons)
- [ ] Icons that don't indicate direction remain unchanged (close, check)
- [ ] Forms align correctly in target locale
- [ ] Tooltips and popovers positioned correctly
- [ ] Animations respect directionality

## Components

### Framework Patterns

Follow the project's frontend framework patterns and conventions. Key principles:

- **Use the latest framework syntax** — avoid deprecated or legacy patterns
- **Typed props** — define explicit TypeScript interfaces for component props
- **Reactive state** — use the framework's reactive state primitives
- **Derived/computed values** — use framework-provided computed patterns for calculated state

<!-- Consult project CLAUDE.md for framework-specific syntax rules, runes, hooks, or composition patterns -->

### Component Specification Format

Every component spec must include:

```markdown
## ComponentName

### Purpose
[One sentence describing what this component does]

### Props
| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| title | string | Yes | - | The component title |
| variant | 'primary' \| 'secondary' | No | 'primary' | Visual variant |

### States
- **Default**: Initial render state
- **Loading**: Data is being fetched
- **Error**: An error occurred
- **Empty**: No data to display
- **Success**: Data loaded successfully

### Events
| Event | Payload | Description |
|-------|---------|-------------|
| submit | { value: string } | Emitted when form is submitted |

### Accessibility
- Keyboard navigation: [Describe expected keyboard behavior]
- Screen reader: [Describe announcements]
- ARIA: [List required ARIA attributes]
- Focus management: [Describe focus behavior]

### Responsive Behavior
- **Mobile (< 768px)**: [Behavior]
- **Tablet (768px - 1024px)**: [Behavior]
- **Desktop (> 1024px)**: [Behavior]

### Localization Considerations
- [List any locale-specific requirements]

### Dependencies
- [List any required components from the project's component library]
```

### Existing UI Components

Before creating new components:
1. Check the project's existing component library
2. Check if existing component can be extended with props
3. Only create new component if truly needed

<!-- Consult project CLAUDE.md for component library location and available components -->

### Component Creation Pattern

Components should:
- Accept a `class` prop for external styling
- Use a conditional class utility for merging default and custom classes
- Extend native HTML element attributes where appropriate
- Use composition patterns (slots/children) for flexible content

### Checkpoint Questions
- [ ] Does the component follow the project's framework patterns?
- [ ] Are all props typed with TypeScript interfaces?
- [ ] Does it reuse existing components from the project library?
- [ ] Is the component specification complete (purpose, props, states, events, a11y)?

## State Management

### Global State

- Store global state in dedicated files following the project's state management pattern
- Examples of global state: theme, user session, feature flags

<!-- Consult project CLAUDE.md for state management approach (e.g., .svelte.ts, Pinia, Zustand, Redux) -->

### Component State

- Use local reactive state for UI-only concerns (open/closed, loading, form values)
- Keep state as close to where it's used as possible

### Server State (API Client)

Pattern for managing async data:
```typescript
// Conceptual pattern — adapt to project's framework
let data = reactive(null);
let loading = reactive(false);
let error = reactive(null);

async function fetchData() {
  loading = true;
  error = null;
  try {
    data = await apiClient.getData();
  } catch (err) {
    error = err.message;
  } finally {
    loading = false;
  }
}
```

### Derived State

- Use the framework's computed/derived state primitive for calculated values
- Derived state automatically updates when dependencies change
- Prefer derived state over manual synchronization

### State Management Rules

**DO:**
- Use dedicated state files for global state shared across routes
- Use component-level state for local UI state
- Use derived/computed values for calculated state
- Keep state as close to where it's used as possible

**DON'T:**
- Use deprecated/legacy state management patterns
- Mix state management approaches without good reason
- Mutate props directly (props should be readonly)
- Duplicate state that can be derived

## Forms

### Validation Timing

**Three-stage validation:**
1. **On Blur**: Validate individual field when user leaves it
2. **On Change**: Once field has been validated, revalidate on every change
3. **On Submit**: Validate entire form before submission

### Schema Validation

Define validation schemas with localized error messages:

```typescript
// Conceptual pattern — adapt to project's validation library
const loginSchema = {
  email: required('[localized: required field]')
    .email('[localized: invalid email]'),
  password: required('[localized: required field]')
    .min(8, '[localized: password min length]')
};
```

<!-- Consult project CLAUDE.md for the frontend validation library (e.g., Zod, Yup, VeeValidate) -->

### Localized Error Messages

Standard error message patterns (localize per project):
- Required field
- Invalid email
- Invalid phone number
- Minimum length
- Maximum length
- Invalid format
- Password mismatch
- Already exists
- Not found

<!-- Consult project CLAUDE.md for localization approach and error message catalog -->

### Accessible Form Pattern

```html
<form>
  <fieldset>
    <legend>[Form section title]</legend>

    <div class="form-field">
      <label for="email">
        [Email label]
        <span aria-label="required">*</span>
      </label>
      <input
        id="email"
        type="email"
        aria-required="true"
        aria-invalid="false"
        aria-describedby="email-error"
      />
      <div id="email-error" role="alert">
        [Error message]
      </div>
    </div>

    <div class="form-actions">
      <button type="submit" disabled>
        [Submit label]
      </button>
    </div>
  </fieldset>
</form>
```

### Backend Alignment

Frontend and backend validation must validate the same shape:
- Field names must match between frontend schemas and backend DTOs
- Validation rules must be equivalent (min length, max length, patterns)
- Error messages can differ in wording but must cover the same validations

<!-- Consult project CLAUDE.md for backend validation library to ensure alignment -->

## Performance

### Core Web Vitals Targets

**Must meet these thresholds:**
- **LCP (Largest Contentful Paint)**: ≤ 2.5 seconds
- **INP (Interaction to Next Paint)**: ≤ 200 milliseconds
- **CLS (Cumulative Layout Shift)**: ≤ 0.1

### JavaScript Budget

**Maximum bundle size: 200KB gzipped**

**Strategies:**
- Code splitting by route (most frameworks support this)
- Lazy load heavy components
- Defer non-critical JavaScript
- Use dynamic imports for large libraries

### Image Optimization

```html
<!-- Lazy loading and dimension hints -->
<img
  src="image.jpg"
  alt="Description"
  loading="lazy"
  decoding="async"
  width="800"
  height="600"
/>

<!-- Responsive images -->
<img
  src="image.jpg"
  srcset="image-400.jpg 400w, image-800.jpg 800w"
  sizes="(max-width: 768px) 100vw, 800px"
  alt="Description"
  loading="lazy"
/>
```

### Lazy Loading

- Use Intersection Observer for lazy loading heavy components
- Show skeleton/placeholder while loading
- Pre-load content slightly before it enters viewport (rootMargin)

### Performance Checklist
- [ ] Route-based code splitting enabled
- [ ] Images optimized and lazy loaded
- [ ] Heavy components loaded on demand
- [ ] Critical CSS inlined
- [ ] JavaScript bundle under 200KB gzipped
- [ ] Core Web Vitals measured and meet targets
- [ ] No unnecessary reactivity
- [ ] Lists use keyed rendering for efficient updates

## Responsive Design

### Breakpoints

Follow the project's CSS framework breakpoints. Common pattern:

| Breakpoint | Width | Description |
|-----------|-------|-------------|
| Default | < 640px | Mobile |
| sm | ≥ 640px | Small tablet |
| md | ≥ 768px | Tablet |
| lg | ≥ 1024px | Desktop |
| xl | ≥ 1280px | Large desktop |
| 2xl | ≥ 1536px | Extra large |

### Mobile-First Approach

**Design mobile first, then enhance for larger screens:**
- Start with mobile layout as the default
- Add complexity with breakpoint utilities
- Test on mobile viewports first

### Touch Target Minimum

**All interactive elements: 44x44px minimum**
- Buttons, links, and interactive elements must meet minimum touch target
- Use padding to increase touch area without changing visual size

### Responsive Specification Format

```markdown
### Responsive Behavior

**Mobile (< 768px)**
- Single column layout
- Bottom navigation
- Full-width cards
- Stacked form fields

**Tablet (768px - 1024px)**
- Two-column layout
- Side navigation
- 50% width cards (2 per row)
- Horizontal form fields

**Desktop (> 1024px)**
- Three-column layout
- Persistent sidebar
- 33% width cards (3 per row)
- Multi-column forms
```

## Styling

### CSS Methodology

Follow the project's styling approach:

<!-- Consult project CLAUDE.md for CSS methodology (Tailwind, CSS Modules, styled-components, etc.) -->

### Design Tokens / CSS Variables

**Never use hardcoded colors. Use design tokens/CSS variables:**

Common design token categories:
- `--background`, `--foreground`
- `--primary`, `--primary-foreground`
- `--secondary`, `--secondary-foreground`
- `--muted`, `--muted-foreground`
- `--accent`, `--accent-foreground`
- `--destructive`, `--destructive-foreground`
- `--border`, `--input`, `--ring`

<!-- Consult project CLAUDE.md for design token source file and available variables -->

### Conditional Class Utility

Use a conditional class merging utility for combining default and override classes:
- Handles class conflicts correctly (e.g., later class wins)
- Supports conditional classes (boolean → class name)
- Accepts user-provided class overrides

<!-- Consult project CLAUDE.md for the class utility (e.g., cn/clsx, classnames, cva) -->

### Styling Rules
- [ ] No hardcoded colors (hex, rgb) — use design tokens
- [ ] Use the project's CSS framework utilities for spacing, sizing, layout
- [ ] Use conditional class utility for class merging
- [ ] Custom CSS only when framework utilities are insufficient
- [ ] Component styles scoped when needed
- [ ] Dark mode support via design tokens (if applicable)

## Icons

### Centralized Icon System

Use the project's centralized icon approach:
- Import icons from the project's icon re-export file, not directly from the icon library
- This enables tree-shaking and consistent naming

<!-- Consult project CLAUDE.md for icon library and centralized export location -->

### Adding New Icons

If an icon is not available in the project's icon exports:
1. Add the icon export to the centralized icon file
2. Import from the centralized location in components

### Icon Sizing

Follow consistent sizing conventions:
- Small: 16x16
- Medium: 20x20 (default)
- Large: 24x24
- Extra large: 32x32

### Directional Icon Handling

- **Directional icons** (arrows, chevrons): Flip in RTL layouts
- **Non-directional icons** (close, check, search): Do NOT flip

### Icon Checklist
- [ ] Icons imported from centralized location (not directly from library)
- [ ] Missing icons added to centralized export file
- [ ] Directional icons flip in RTL (if applicable)
- [ ] Icon sizes consistent with project conventions

## Testing

### Unit Tests

**Test utilities, functions, business logic:**

```typescript
import { describe, it, expect } from '[test-framework]';
import { formatCurrency } from './utils';

describe('formatCurrency', () => {
  it('formats number as currency', () => {
    expect(formatCurrency(1234.56)).toBe('$1,234.56');
  });

  it('handles zero', () => {
    expect(formatCurrency(0)).toBe('$0.00');
  });

  it('handles negative numbers', () => {
    expect(formatCurrency(-100)).toBe('-$100.00');
  });
});
```

<!-- Consult project CLAUDE.md for test framework (Vitest, Jest) and currency format -->

### Component Tests

**Test component behavior and accessibility:**

```typescript
import { render, screen, fireEvent } from '[testing-library]';
import { describe, it, expect, vi } from '[test-framework]';
import Button from './Button';

describe('Button', () => {
  it('renders with text', () => {
    render(Button, { props: { children: 'Click Me' } });
    expect(screen.getByRole('button')).toHaveTextContent('Click Me');
  });

  it('calls click handler', async () => {
    const handleClick = vi.fn();
    render(Button, { props: { onClick: handleClick } });

    await fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledOnce();
  });

  it('is keyboard accessible', async () => {
    const handleClick = vi.fn();
    render(Button, { props: { onClick: handleClick } });

    const button = screen.getByRole('button');
    button.focus();
    await fireEvent.keyDown(button, { key: 'Enter' });

    expect(handleClick).toHaveBeenCalled();
  });

  it('shows loading state', () => {
    render(Button, { props: { loading: true } });
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

### E2E Tests

**Test user flows and integration:**

```typescript
import { test, expect } from '@playwright/test';

test.describe('Login Flow', () => {
  test('successful login redirects to dashboard', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[type="email"]', 'user@example.com');
    await page.fill('input[type="password"]', 'password123');
    await page.click('button[type="submit"]');

    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('Dashboard')).toBeVisible();
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login');

    await page.fill('input[type="email"]', 'wrong@example.com');
    await page.fill('input[type="password"]', 'wrongpass');
    await page.click('button[type="submit"]');

    await expect(page.getByRole('alert')).toBeVisible();
  });

  test('is keyboard accessible', async ({ page }) => {
    await page.goto('/login');

    await page.keyboard.press('Tab'); // Focus email
    await page.keyboard.type('user@example.com');
    await page.keyboard.press('Tab'); // Focus password
    await page.keyboard.type('password123');
    await page.keyboard.press('Tab'); // Focus submit button
    await page.keyboard.press('Enter'); // Submit

    await expect(page).toHaveURL('/dashboard');
  });
});
```

### Accessibility Tests

**Automated accessibility testing:**

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test.describe('Accessibility', () => {
  test('homepage has no accessibility violations', async ({ page }) => {
    await page.goto('/');

    const accessibilityScanResults = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
      .analyze();

    expect(accessibilityScanResults.violations).toEqual([]);
  });
});
```

### Testing Checklist
- [ ] Unit tests for utilities and business logic
- [ ] Component tests for user interactions
- [ ] E2E tests for critical user flows
- [ ] Accessibility tests with axe-core
- [ ] Locale-specific layout tested (if applicable)
- [ ] Keyboard navigation tested
- [ ] Screen reader tested
- [ ] Mobile viewport tested

## Security

### XSS Prevention

**NEVER render unsanitized user input as HTML:**

```html
<!-- Dangerous -->
<div innerHTML={userGeneratedContent}></div>

<!-- Safe — framework escapes by default -->
<div>{userGeneratedContent}</div>

<!-- Safe — sanitize if HTML is required -->
<div innerHTML={sanitize(userGeneratedContent)}></div>
```

### CSRF Protection

- Use the project's auth provider's CSRF protection
- Framework form actions may have built-in CSRF protection
- No additional configuration needed in most cases

### HttpOnly Cookies

- Session cookies should be HttpOnly (handled by auth provider)
- Frontend cannot access session tokens directly
- Prevents XSS attacks from stealing tokens
- Refresh tokens stored securely

### Role-Based UI Hiding

```typescript
// Conceptual pattern — adapt to project's framework
const isAdmin = derived(() => session.user?.role === 'admin');

// In template:
// {#if isAdmin} <button>Admin Action</button> {/if}
```

**Important:** UI hiding is NOT security. Always enforce permissions on backend.

### Security Checklist
- [ ] No unsanitized HTML rendering with user input
- [ ] User input sanitized if HTML rendering is required
- [ ] CSRF protection enabled
- [ ] Sensitive data not in client state
- [ ] Role checks on UI elements
- [ ] Backend enforces all permissions
- [ ] No API keys in frontend code
- [ ] Environment variables for configuration

## Authentication

### Auth Provider Client

Initialize the project's auth provider on the frontend:
- Configure API domain and base path
- Initialize session management recipe
- Set up automatic token refresh

<!-- Consult project CLAUDE.md for auth provider and initialization pattern -->

### Session State

Maintain client-side session state:
- User identity (id, email, role)
- Tenant context (if multi-tenant)
- Tenant role (if applicable)

Provide functions to load, refresh, and clear session state.

### Guards

Implement route guards for access control:

```typescript
// Conceptual patterns — adapt to project's framework and router

// Require authentication
function requireAuth() {
  if (!session.user) {
    redirect('/login');
  }
}

// Require specific tenant/organization
function requireTenant() {
  if (!session.tenantId) {
    redirect('/select-tenant');
  }
}

// Require specific role
function requireAdmin() {
  if (session.user?.role !== 'admin') {
    redirect('/forbidden');
  }
}
```

### Route Groups

Organize routes by access level:

- **Protected Routes**: Require authentication, use auth guard in layout
- **Public Routes**: No authentication required (landing, login, signup)

<!-- Consult project CLAUDE.md for route group structure and conventions -->

### Authentication Flow

Key flows to specify:
1. **Login**: Form submission → API call → Load session → Redirect to dashboard
2. **Logout**: API call → Clear session → Redirect to home
3. **Session Refresh**: Detect 401 → Refresh token → Retry request → Redirect to login if refresh fails
4. **Registration**: Form submission → API call → Auto-login or redirect to login

### Auth Checklist
- [ ] Protected routes use auth guard
- [ ] Public routes accessible without authentication
- [ ] Session state loaded on app initialization
- [ ] Guards redirect unauthenticated users
- [ ] Logout clears session state
- [ ] Auth provider initialized before app render
- [ ] Session refresh handled automatically
- [ ] Role-based UI elements hidden appropriately

## Specification Checklist

Every frontend specification must address:

- [ ] **Accessibility**: WCAG compliance, ARIA patterns, keyboard navigation
- [ ] **Localization**: Logical properties, locale-specific text handling (if applicable)
- [ ] **Components**: Follow framework patterns, reuse existing UI components
- [ ] **State**: Global vs component state, derived state, server state
- [ ] **Forms**: Validation timing, schemas, localized error messages
- [ ] **Performance**: Core Web Vitals, bundle size, lazy loading
- [ ] **Responsive**: Mobile-first, touch targets, breakpoints
- [ ] **Styling**: Design tokens, conditional class utility, no hardcoded colors
- [ ] **Icons**: Centralized system, add missing icons
- [ ] **Testing**: Unit, component, E2E, accessibility
- [ ] **Security**: XSS prevention, CSRF, role-based UI
- [ ] **Auth**: Route protection, session management, guards
