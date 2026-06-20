# Architecture Overview

> **Note:** This documentation serves both **human developers** and **AI agents**. It is designed to support an AI agent delegation model where a manager agent coordinates specialized agents to accomplish tasks efficiently.

## Purpose of This Documentation

This `.context` directory provides comprehensive project-specific knowledge that enables:

### For Human Developers
- Quick onboarding to project patterns and conventions
- Reference for making consistent technical decisions
- Understanding of architectural choices and their rationale
- Clear guidelines for common development tasks

### For AI Agents
- **Primary knowledge base** for code generation and task execution
- **Pattern library** for recognizing and replicating project patterns
- **Context recovery source** after conversation compaction
- **Delegation guide** for the manager agent workflow

---

## AI Agent Delegation Model

This documentation is designed for a **"manager of engineers"** model where a manager agent coordinates specialized agents:

### Available Agent Roles

**@researcher** - Research current library patterns and documentation  
**@planner** - Break down complex tasks into manageable steps  
**@architect** - Validate architectural decisions before implementation  
**@coder** - Implement features following documented patterns  
**@tester** - Write and validate tests according to project standards  
**@reviewer** - Quality check implementations for pattern adherence  

### When to Use Each Agent

The manager loads phase-specific guidance on demand from `workflows/task-plan/`:

1. **Task Initiation** - Gather context, assess complexity
2. **Research** (conditional) - @researcher fetches current library documentation
3. **Planning** - @planner breaks down the work (`task-plan/phase-investigation.md`)
4. **Architecture Review** - @architect validates approach (`task-plan/phase-architecture.md`)
5. **Implementation** - @coder builds following patterns (`task-plan/phase-implementation.md`)
6. **Testing** - @tester validates implementation (`task-plan/phase-testing.md`)
7. **Review** - @reviewer checks quality
8. **Completion** - Document lessons learned (`task-plan/phase-completion.md`)

### Context Recovery After Compaction

When AI context window compacts, the manager agent must:

1. **Re-read core documentation:**
   - `.claude/claude.md` (or `.github/copilot-instructions.md` as legacy fallback) (big-picture project conventions)
   - Relevant `.context/` files for the current task (domain docs, standards, architecture)

2. **Rebuild task context:**
   - Review `.context/tasks/[task-name]/plan.md`
   - Identify current progress and next step

3. **Continue work** from documented checkpoint

See `META.md` for the detailed context recovery protocol.

---

## System Context

[Brief description of what this system does and its place in the broader ecosystem]

### External Dependencies
| System | Purpose | Protocol |
|--------|---------|----------|
| [External System 1] | [What it provides] | REST/gRPC/etc |
| [External System 2] | [What it provides] | [Protocol] |
| [Database] | Data persistence | SQL/NoSQL |

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Clients                               │
│            (Web App, Mobile App, API Consumers)              │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                             │
│              (Authentication, Rate Limiting)                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ Service  │   │ Service  │   │ Service  │
    │    A     │   │    B     │   │    C     │
    └────┬─────┘   └────┬─────┘   └────┬─────┘
         │              │              │
         └──────────────┼──────────────┘
                        ▼
              ┌──────────────────┐
              │    Database(s)   │
              └──────────────────┘
```

## Application Layers

### Layer Diagram
```
┌─────────────────────────────────────────┐
│         Presentation Layer              │  Controllers, Views, DTOs
├─────────────────────────────────────────┤
│         Application Layer               │  Use Cases, Services
├─────────────────────────────────────────┤
│           Domain Layer                  │  Entities, Business Rules
├─────────────────────────────────────────┤
│        Infrastructure Layer             │  Database, APIs, Framework
└─────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Examples |
|-------|----------------|----------|
| Presentation | Handle HTTP requests, validate input, format responses | Controllers, API endpoints, DTOs |
| Application | Orchestrate use cases, coordinate domain objects | Services, Command handlers |
| Domain | Business logic, entities, rules | Entities, Value objects, Domain services |
| Infrastructure | External concerns, persistence, integration | Repositories, API clients, ORM |

### Dependency Rules
- Dependencies point inward (toward domain)
- Domain layer has no external dependencies
- Infrastructure implements interfaces defined in application/domain

## Module Structure

```
src/
├── [module-1]/
│   ├── api/                 # Controllers, routes
│   ├── application/         # Use cases, services
│   ├── domain/              # Entities, interfaces
│   ├── infrastructure/      # Implementations
│   └── index.ts             # Public exports
├── [module-2]/
│   └── ...
├── shared/                  # Cross-cutting concerns
│   ├── auth/
│   ├── logging/
│   └── errors/
└── main.ts                  # Entry point
```

## Key Design Decisions

### [Decision Area 1: e.g., State Management]
**Decision**: [What was decided]
**Rationale**: [Why this approach]
**Consequences**: [Trade-offs accepted]

### [Decision Area 2: e.g., API Design]
**Decision**: [What was decided]
**Rationale**: [Why this approach]
**Consequences**: [Trade-offs accepted]

## Data Flow

### [Main Flow: e.g., Request Processing]
```
1. Client sends HTTP request
2. API Gateway authenticates and routes
3. Controller validates input, creates command
4. Service executes business logic
5. Repository persists changes
6. Events published (if applicable)
7. Response returned to client
```

### Sequence Diagram
```
Client    Controller    Service    Repository    Database
   │          │            │           │            │
   │──request─▶│            │           │            │
   │          │──command───▶│           │            │
   │          │            │──query────▶│            │
   │          │            │           │──SQL───────▶│
   │          │            │           │◀──result────│
   │          │            │◀──entity──│            │
   │          │◀──result───│           │            │
   │◀─response─│            │           │            │
```

## Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Runtime | [Node.js/JVM/.NET/etc.] | [Version] |
| Framework | [Express/Spring/ASP.NET/etc.] | [Version] |
| Database | [PostgreSQL/MongoDB/etc.] | [Version] |
| Cache | [Redis/Memcached/etc.] | [Version] |
| Message Queue | [RabbitMQ/Kafka/etc.] | [Version] |

## Cross-Cutting Concerns

### Authentication
[How authentication works in this system]

### Authorization
[How authorization/permissions work]

### Logging
[Logging approach and standards]

### Error Handling
[How errors are handled and reported]

### Monitoring
[What is monitored and how]

## Future Considerations

- [Planned architectural changes]
- [Known limitations to address]
- [Scalability considerations]
