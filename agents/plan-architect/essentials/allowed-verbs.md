# Allowed Verbs

The closed-vocabulary list of action verbs `plan-architect` may use in task headers. Additions arrive via `/agent-architect process-vocabulary` after review against vocabulary discipline criteria; until then, an unlisted verb is admissible only when accompanied by a corresponding extension-request file at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md` (see `vocabulary-extension.md`).

## Closed list

`validate`, `format`, `parse`, `serialize`, `query`, `mutate`, `render`, `wrap`, `guard`, `emit`, `persist`, `normalize`, `authorize`, `authenticate`, `dispatch`, `schedule`, `log`, `retry`, `paginate`, `sort`, `filter`, `aggregate`, `transform`, `build`, `migrate`, `seed`, `provision`.

## Structural verb scope

- `build` — construct a **new** code artifact (service, module, component, util). It is not a synonym for changing existing code: a behavior change to existing code takes the precise behavior verb (`validate`, `persist`, `transform`, `dispatch`, …) with no `new:` prefix, and a restructuring that changes no runtime behavior is not a feature-plan task at all.
- `provision` — bring an external dependency or infrastructure resource into existence (package dependency, environment variable, bucket, queue). Pairs with `Concern: infrastructure`.

## Noun discipline

Verbs are paired with named domain entities, types, or invariants — not generic placeholders. Allowed noun forms:

- `<domain entity>` — examples: `email`, `tenant-id`, `Hebrew date`, `Tabu PDF block`, `organization`, `role`.
- `<type>` — concrete type or interface names from the codebase or SDD.
- `<invariant>` — named architectural invariants (e.g., `tenant scope`, `auth context`).

### Accepted

- `validate email`
- `guard tenant scope`
- `format Hebrew date`
- `persist Tabu PDF block`
- `paginate organization list`
- `provision pdf-parse dependency`

### Rejected

- `implement user creation flow` — multiple responsibilities, free-form verb.
- `do the auth thing` — unspecified verb, generic noun.
- `handle input` — `handle` not in closed list; `input` is generic.
- `update data` — `update` not in closed list; `data` is generic.
