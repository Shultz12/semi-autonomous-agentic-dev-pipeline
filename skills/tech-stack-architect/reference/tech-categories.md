# Tech Categories

The canonical category list for the Coverage Tracker and the charter's Approved-Stack
grouping. Each category covers a class of decision; mark a category `N/A` when the product
genuinely doesn't need it (the "Typically N/A when" column shows the common cases).

| Category | Covers | Example sub-decisions | Typically N/A when |
|---|---|---|---|
| **Language / Runtime** | The programming language(s) and runtime version | TypeScript target, Node.js LTS line | — (always applies) |
| **Backend framework** | HTTP/server framework and its core ecosystem | NestJS, Express, Fastify; validation lib | Frontend-only product |
| **Frontend framework** | UI framework, meta-framework, build target | SvelteKit + Svelte 5, Next.js + React | Backend-only product / API |
| **Database / ORM** | Persistent datastore and data-access layer | PostgreSQL + Prisma, MySQL + Drizzle | No persistence (stateless tool) |
| **Authentication** | Identity, sessions, authz approach | SuperTokens, Auth.js, custom JWT; RBAC | No user accounts |
| **File storage** | Where uploaded/generated files live | Local disk, S3-compatible object store | No file handling |
| **Background jobs / scheduling** | Async work, queues, cron | BullMQ, cron, in-process queue | Fully synchronous request/response |
| **OCR / document processing** | Extracting/transforming documents | Google Vision, Amazon Textract, pdf libs | No document ingestion |
| **Payments** | Charging, checkout, billing | Grow/Meshulam, Stripe | No monetization |
| **Testing** | Test runner + assertion/mocking + e2e | Vitest, Jest, Playwright | — (always applies if code is tested) |
| **Observability / logging** | Logs, metrics, tracing, error reporting | pino, Sentry, OpenTelemetry | Throwaway / prototype |
| **Key supporting libraries** | Consequential libs not in another category | date/i18n, crypto, ZIP/archive, HTTP client | — |
| **Infrastructure / deployment** | How the app runs and ships | Docker, container host, CI provider | — |

## How to use this list

- In `create` mode, every category becomes a Coverage Tracker row. Walk them in roughly the
  order above — foundational categories (language, frameworks, DB) first, because later
  choices often depend on them.
- The build/test **toolchain** within *Testing* and *Infrastructure* (bundler, test runner,
  TS compiler, CI-gating linter) is **consequential** and gets a full TDR even though most
  `devDependencies` are minor-tier.
- A category can hold more than one approved technology (e.g. *Testing* may list both a unit
  runner and an e2e tool). Each distinct technology is its own charter row.
