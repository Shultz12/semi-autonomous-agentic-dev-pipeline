# Example Convention File

A complete sample convention file demonstrating every rule the `context-curation` skill prescribes: structure, `created-during` frontmatter, code references, examples, anti-patterns, `## See also`, and backtick-scoped symbol citations.

Use this as a copy-paste seed when authoring a new convention from scratch. Replace the placeholder content with the real convention; preserve the shape.

## Sample file

The sample below would live at `.project/knowledge/backend/format/hebrew-date.md`. The trigger row in `.project/knowledge/backend/_index.md` would be:

```markdown
- format Hebrew date → format/hebrew-date.md
```

The file body (between the horizontal rules below) is the convention itself:

---

````markdown
---
created-during: pdf-extraction
---

# Hebrew date formatting

## Purpose

All user-facing Hebrew dates render through `formatHebrewDate` in the shared format module. The function applies the project's RTL-safe date template, Hebrew month names, and the optional Gregorian-equivalent suffix. Bypassing it and concatenating strings inline breaks both RTL alignment and locale consistency.

## Code references

- `backend/src/shared/format/hebrew-date.ts:14` — `formatHebrewDate` definition.
- `backend/src/shared/format/hebrew-date.ts:42` — `HebrewDateOptions` type.
- `backend/src/extraction/render/date-block.ts:88` — canonical call site.

## Examples

A render-time call returning the full Hebrew form with Gregorian suffix:

```ts
import { formatHebrewDate } from '@/shared/format/hebrew-date';

const label = formatHebrewDate(parcel.recordedAt, { gregorianSuffix: true });
// → "כ״ה בניסן ה׳תשפ״ו (2026-04-13)"
```

A render-time call returning the Hebrew form only:

```ts
const label = formatHebrewDate(parcel.recordedAt);
// → "כ״ה בניסן ה׳תשפ״ו"
```

## Anti-patterns

Inline string concatenation — bypasses RTL handling and the project's Hebrew month name table:

```ts
const label = `${day} ${monthName}, ${year}`;
// → wrong: month names diverge from formatHebrewDate's table
```

Using `Intl.DateTimeFormat` with `he-IL` directly — locale data varies across Node versions and does not match the project's expected output:

```ts
const label = new Intl.DateTimeFormat('he-IL').format(parcel.recordedAt);
// → wrong: output differs from formatHebrewDate; tests asserting one will fail against the other
```

## See also

- `../tests/format-snapshot-tests.md` — tests that assert `formatHebrewDate` output stability.
- `../frontend/_index.md` → `frontend/render/date-block.md` — frontend rendering of the same value (Pattern A cross-reference: primary home is frontend for rendering concerns).
````

---

## Why this shape

Each section of the sample maps to a rule in the parent `SKILL.md`:

- **Frontmatter `created-during: pdf-extraction`** — the rule from "Mandatory frontmatter". The slug names the feature whose merge introduced the convention.
- **Title** — "Hebrew date formatting": noun phrase, no verbs, no implementation detail.
- **Purpose** — three sentences. States the rule (route through `formatHebrewDate`), the canonical location (shared format module), and what breaks if bypassed.
- **Code references** — three citations: definition, type, canonical call site. Each line number is real (verified per the self-verification protocol).
- **Examples** — two positive examples covering the documented option (`gregorianSuffix: true`) and the default. Both compile against the cited definition.
- **Anti-patterns** — two violations: inline concatenation and `Intl.DateTimeFormat` misuse. Each carries one sentence on why it is wrong.
- **`## See also`** — two cross-references. The frontend row demonstrates Pattern A: the rendering concern's primary home is frontend, with a cross-reference row in backend pointing there.

## Backtick discipline in this sample

Every code symbol in the sample is enclosed in backticks: `formatHebrewDate`, `HebrewDateOptions`, `parcel.recordedAt`, `gregorianSuffix`, `Intl.DateTimeFormat`, `he-IL`. Each one is grep-resolvable in the cited source file (per the mechanical symbol-resolution check). Prose nouns ("the function", "the convention", "the rendering concern") are not in backticks and are exempt from the check.

## Trigger phrase mapping

The `_index.md` row uses `- format Hebrew date → format/hebrew-date.md`. Plan tasks targeting this concern say "format Hebrew date" — verb-noun against the domain entity. A row phrased as `- Hebrew dates → format/hebrew-date.md` would also work, but would miss the routing fit with plan task language. The verb-noun shape is what makes the developer's task-text match the trigger phrase mechanically.
