# Integration Checks

Rules for INTEGRATION_VERIFICATION mode only. Loaded alongside ALL type files.

Consult the project's CLAUDE.md for project-specific paths, module systems, and registration patterns referenced in the wiring tables below.

---

## 3-Level Methodology

Check each artifact sequentially. Short-circuit on failure — if an artifact fails Level 1, do not check Levels 2 or 3 for that artifact.

### Level 1: EXISTS

Verify the artifact file exists on disk.

- **Tool:** Glob for the expected file path
- **PASS:** File found
- **FAIL:** Category `MISSING`, Severity `CRITICAL`

### Level 2: SUBSTANTIVE

Verify the artifact contains real implementation, not a stub or placeholder.

- **Tool:** Read the file, then check against stub detection patterns below
- **PASS:** File contains meaningful implementation beyond boilerplate
- **FAIL:** Category `STUB`, Severity `ERROR`

### Level 3: WIRED

Verify the artifact is connected to the rest of the system — imported, registered, routed.

- **Tool:** Grep for the wiring evidence defined in the type-specific wiring tables below and in the loaded type files
- **PASS:** All expected wiring connections confirmed
- **FAIL:** Category `UNWIRED`, Severity `ERROR`

---

## Stub Detection Patterns

A file is a stub if ANY of these patterns match:

| Pattern | How to Detect |
|---------|---------------|
| Not-implemented throw | `throw new Error('Not implemented')` or `throw new NotImplementedException()` |
| TODO placeholder | `// TODO` or `/* TODO */` as the primary body content |
| Empty class body | Class declaration with no methods or only constructor |
| Null-return function | Function/method body is only `return null`, `return undefined`, or `return {}` |
| Trivially small | File has <10 lines of actual code (excluding imports, empty lines, comments) AND contains a class or function declaration |

**Important:** A file that imports dependencies and has real logic but also contains a TODO comment is NOT a stub. Stub detection targets files where the TODO/placeholder IS the implementation, not files with incidental TODOs alongside real code.

---

## Backend Wiring Table

Use these checks when the artifact is a backend file. Consult project CLAUDE.md for the specific module system, registration mechanism, and directory structure.

| Artifact Type | Wiring Check | Evidence |
|---------------|-------------|----------|
| Service | Registered in its module's providers/registry | Grep module file for service class name in the registration array |
| Service (cross-module) | Listed in module exports | Grep module file for service class name in exports |
| Controller | Registered in module controllers/routes | Grep module file for controller class name in the registration array |
| Repository | Registered with interface token (if DI uses tokens) | Grep infrastructure module for `provide:` token matching the repository interface |
| Repository | Implements domain interface | Read repository file, verify `implements` clause references the domain interface |
| Mapper | Has required mapping methods | Grep mapper file for the expected static method signatures (consult project CLAUDE.md) |
| Mapper | Registered in infrastructure module | Grep module file for mapper class name |
| Guard/Decorator | Applied to at least one controller | Grep controller directory for the guard/decorator name |

---

## Frontend Wiring Table

Use these checks when the artifact is a frontend file. Consult project CLAUDE.md for route groups, component conventions, and icon management.

| Artifact Type | Wiring Check | Evidence |
|---------------|-------------|----------|
| Route page | Located in correct route group | Path matches the expected route group directory (consult project CLAUDE.md for group definitions) |
| Route page | Has layout or parent route | Glob for layout file in same or parent directory |
| Component | Imported by at least one consumer | Grep source directory for the component file name in import statements |
| State file | Exported state is imported somewhere | Grep source directory for import from the state file path |
| Icon (if centralized) | Registered in centralized index | Grep centralized icon index for the icon name (consult project CLAUDE.md for index location) |
| Icon (if centralized) | Imported from centralized path, not library directly | Grep consumer files for import source |

---

## Infrastructure Wiring Table

Use these checks when the artifact is an infrastructure file. Consult project CLAUDE.md for schema location, migration directory, and data access patterns.

| Artifact Type | Wiring Check | Evidence |
|---------------|-------------|----------|
| Schema model | Defined in schema file | Grep schema file for model/table definition |
| Migration | Present in migrations directory | Glob migrations directory for the migration file |
| Mapper | Has required mapping methods | Grep mapper file for expected method signatures |
| Mapper | Registered in database/infrastructure module | Grep module file for mapper class name |
| Repository | Implements domain interface | Read file, verify `implements` clause |
| Repository | Interface exists in domain abstractions directory | Glob domain abstractions directory for the interface file |

---

## Cross-Cutting Checks

These apply regardless of artifact type:

1. **Import reachability** — For every new file, at least one other file must import it (exception: entry points like route pages, main module)
2. **No orphan exports** — If a file exports a symbol, at least one consumer imports it
3. **Configuration registration** — New modules must be imported in their parent module or root module (consult project CLAUDE.md for the root module name)
