# Per-File Content Guidance for `context-specialist-impl-leaf` Step 4

This document is the per-file detail companion to Step 4: Populate Every File Exhaustively. The skill body keeps the principle and Quality Bar inline; this file documents what each generated `.context/` file should contain.

---

### `overview.md`

Customize the template with:
- What the system actually does (1–3 paragraphs, written for a new developer)
- Core business concepts with definitions
- System architecture: major modules, their roles, how they communicate
- Entry points for new feature work
- Key external dependencies (name, version, purpose) — especially non-obvious ones
- Deployment target and any critical deployment constraints
- Anything an agent must know to avoid making a wrong architectural decision

---

### `decisions/`

A folder of Architecture Decision Records (ADRs), one file per decision. Structure:

```
decisions/
├── README.md          # intro + naming convention + Decision Log table
└── NNN-kebab-slug.md  # one file per ADR, numbered sequentially
```

Populate from the template's `decisions/README.md`. For each significant decision, create a new `NNN-kebab-slug.md` following the ADR template (h1 `# ADR-NNN: Title`, **Date**, **Status**, `## Context`, `## Decision`, `## Consequences`, `## Alternatives Considered`).

Content to capture:
- Why this framework was chosen over alternatives
- Locked dependency versions and the reason they're locked
- Patterns that are intentionally *not* used (and why)
- Migrations in progress (e.g., "moving from X to Y; new code uses Y only")
- Known technical debt and its boundaries

---

### `rules-index.md`

A single on-demand router at `.context/rules-index.md` that gives `standards/`, `workflows/`, and `decisions/` the discoverability `domains/` already has. Three sections — `## Standards`, `## Workflows`, `## Decisions (ADRs)` — each a markdown table with columns `Rule | Applies when… | File` (`Decisions` keys the first column by ADR number).

- **Generate, don't template.** Build this file by scanning the three populated directories — see `SKILL.md` Step 4.5. Do not copy the template's sentinel rows.
- **One row per file**, with a single **parent row** for an indexed sub-directory (`standards/skill-decomposition/`, `workflows/task-plan/`) rather than one row per inner file. Skip helper scripts that are not rules.
- **"Applies when…" is a routing phrase, not a summary.** Each cell states a concrete situation that sends a reader to that file; it does not paraphrase the rule's content.

---

### `standards/code-style.md`

Document the *actual* style enforced in this codebase:
- Indentation, line length, encoding — and whether a linter/formatter enforces them
  (name the config file: `checkstyle.xml`, `.eslintrc`, `rustfmt.toml`, etc.)
- Dependency injection style (constructor/field/setter) — with a real code example
- Null handling conventions (`Optional`, null checks, `@NonNull`, etc.)
- Third-party annotation libraries in use and any that are explicitly banned
- Logging framework and the exact logger declaration pattern used
- Exception handling conventions: custom exception types, when to throw vs. catch
- Transaction boundary conventions (where `@Transactional` goes)
- Any class-level boilerplate patterns (base classes, required annotations)

Show a representative real code snippet for each non-obvious convention.

---

### `standards/naming-conventions.md`

Document the actual naming patterns observed in the codebase:
- Class naming table per layer (Controller, Service, ServiceImpl, Repository,
  Resource/DTO, Model, Assembler, Validator, etc.) with real examples
- Package/namespace structure with real paths
- Test class naming (`*UnitTest`, `*IT`, `*Test`, `*Spec`, etc.)
- File naming: SQL files, config files, migration files
- URL/route naming conventions
- Enum naming patterns

---

### `standards/error-handling.md`

- Custom exception hierarchy: names, when each is thrown, HTTP status mapping
- Where exceptions are caught and converted (global handler, middleware, etc.)
- Error response body format (real JSON example)
- Logging expectations at each severity level
- How validation errors are returned

---

### `architecture/patterns.md`

Describe the actual architectural patterns in use — not textbook definitions:
- The primary structural pattern (layered, hexagonal, CQRS, etc.)
- Each recurring pattern with: purpose, participants, real class names, code example
- Cross-cutting infrastructure: caching, scheduling, multi-tenancy, auth
- Any dual-architecture areas (legacy vs. modern) with explicit "do not cross-contaminate" rules
- Module dependency graph if multi-module

---

### `testing/unit-testing.md`

- Base test class name(s) and what each provides — with full class declaration
- Mocking framework: annotations, injection pattern, real example test class
- Any test data factories or builders (`PodamFactory`, `Fixture`, `Factory.build()`, etc.)
- Assertion style (Hamcrest, AssertJ, JUnit assertions, etc.)
- The canonical test method pattern: Arrange/Act/Assert with a real example
- Patterns for testing the specific layer types in this codebase
  (validators, assemblers, controllers, services, repositories, etc.)
- Common import block to paste verbatim

---

### `testing/integration-testing.md`

- Integration test base class(es) and what infrastructure they spin up
  (TestContainers, H2, WireMock, MockMvc, etc.)
- How to run integration tests separately from unit tests (command + flag)
- Database seeding approach (SQL scripts, Liquibase, Flyway test migrations, etc.)
- External service stubbing patterns
- Integration test naming and location conventions
- What not to test in integration tests (boundary with unit tests)

---

### `workflows/branching.md`

Populate from the analysis in Step 1a — do not guess:
- Primary integration branch name(s) (verified from `git branch -r`)
- Feature branch naming: exact format with real examples from the log
- Release/tag naming format with real examples from `git tag`
- Pull request workflow (squash? merge commit? rebase?)
- Whether linear history is enforced

---

### `workflows/commit-conventions.md`

Record the commit format exactly as observed in this repository's git log:
- The format pattern with a concrete example (e.g., `ABC-123: Brief description`)
- Ticket ID prefix(es) in use (e.g., `WSD-`, `CORE-`, `FE-`)
- Whether a body or footer is conventional (breaking changes, co-authors, etc.)
- Any commit types or scopes used (conventional commits, etc.)
- What a well-formed commit looks like — show 3–5 real examples from `git log`

This file is the authoritative source agents use when writing commit messages
for this repository.

---

### `workflows/ci-cd.md` *(if applicable)*

- CI system (GitHub Actions, Jenkins, etc.) and config file location
- Pipeline stages and what each does
- How to run the full pipeline locally (if possible)
- Deployment environments and how to trigger deploys
- Any manual gates or approvals required

---

### `domains/` — One File Per Domain

This is the highest-value section. **Every major domain should have its own
file.** Domains come in two types:

**Business domains** — application areas with real-world meaning:
`payments.md`, `loans-accounts.md`, `user-management.md`, `inventory.md`, etc.

**Technical domains** — cross-cutting infrastructure areas:
`routing.md`, `state-management.md`, `authentication.md`, `database-migrations.md`,
`caching.md`, etc.

#### Minimum content per domain file

1. **Domain overview** — what this area does in 2–5 sentences
2. **Key entities** — table with entity name, its ID field, backing table/collection,
   and key fields. For REST APIs, include the JSON root name.
3. **Lifecycle / workflow** — numbered steps or ASCII diagram showing how the
   main entity moves through states. Include actual method names and class names
   at each step.
4. **API endpoints** (REST domains) — table: method, URL, controller method,
   validator class, notes
5. **Business rules** — explicit rules from validators, service impls, or domain
   logic. State what is validated, what exception is thrown, and why.
6. **SQL patterns** (if JDBC/raw SQL) — table of SQL key names, file paths, purpose
7. **Important code paths** — table: task → entry point → key classes/methods
   traversed → package location
8. **Gotchas / non-obvious behaviour** — things that would surprise a developer
   new to this domain

#### What depth looks like

Do not write: *"Payments are processed through the payments service."*

Write: *"POST `/payment-advice` → `PaymentAdviceController.createPaymentAdvice`
→ `@ValidateRequest(PaymentAdvicePostValidator.class)` (enforces one open advice
per DAS user per customer) → `PaymentAdviceServiceImpl.createPaymentAdvice`
→ `PaymentAdviceRepository.insertPaymentAdvice` (SQL key: `createNewPaymentAdvice`
in `sql/paymentadvice/payment-advice-sql.xml`)"*

---

### `styling/` *(frontend projects only)*

- Design system or component library in use (MUI, Tailwind, Ant Design, etc.)
- How global styles are structured and where overrides live
- Spacing/sizing conventions (design tokens, CSS variables, Tailwind config)
- Component file structure conventions
- Responsive breakpoints used
- Dark mode / theming approach

---
