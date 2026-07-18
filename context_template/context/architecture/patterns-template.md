# Architectural Patterns Template

## Purpose

Captures project-specific architectural patterns to follow when implementing features or refactoring. These represent the team's agreed-upon approaches to common problems.

## How to Use This Template

1. **Replace [Placeholders]** with your project specifics
2. **Add real code examples** from your codebase
3. **Remove sections** that don't apply to your project
4. **Add new sections** for project-specific patterns

---

## Component/Module Patterns

### [Component Type 1: e.g., Smart Components, Controllers, Services]

**Purpose:** [What this type of component does]

**When to Use:**
- ✅ [Scenario 1]
- ✅ [Scenario 2]

**When NOT to Use:**
- ❌ [Scenario 1]
- ❌ [Scenario 2]

**Pattern:**

```[language]
// [Brief description of what this shows]
[Code example showing the pattern]

// Key characteristics:
// - [Characteristic 1]
// - [Characteristic 2]
// - [Characteristic 3]
```

**Real Example:**
- File: `[path/to/example/file]`
- Shows: [What pattern it demonstrates]

**Anti-Patterns to Avoid:**
```[language]
// ❌ DON'T do this:
[Bad example]

// ✅ DO this instead:
[Good example]
```

---

### [Component Type 2: e.g., Presentation Components, DTOs, Models]

**Purpose:** [What this type does]

**When to Use:**
- ✅ [Scenario 1]
- ✅ [Scenario 2]

**Pattern:**

```[language]
[Code example]
```

**Real Example:**
- File: `[path/to/example]`

---

## State Management Patterns

### [State Pattern: e.g., Redux, MobX, NGXS, Context API, Vuex]

> **Note:** Remove this section if your project doesn't have state management

**Philosophy:** [Your approach to state management]

**State Organization:**

```[language]
// [Description of state structure]
[Code showing state interface/model]
```

**State Updates:**

```[language]
// [Description of how state is updated]
[Code showing update pattern]
```

**State Selection:**

```[language]
// [Description of how state is selected/accessed]
[Code showing selector pattern]
```

**Real Examples:**
- State definition: `[path/to/state]`
- Actions: `[path/to/actions]`
- Selectors: `[path/to/selectors]`
- Usage: `[path/to/component]`

**Best Practices:**
1. [Best practice 1]
2. [Best practice 2]
3. [Best practice 3]

**Anti-Patterns:**
- ❌ [Anti-pattern 1]
- ❌ [Anti-pattern 2]

---

## Service Layer Patterns

### [Service Pattern: e.g., API Services, Domain Services, Business Logic Services]

**Purpose:** [What services do in your architecture]

**Service Structure:**

```[language]
// [Description]
[Code example]
```

**Dependency Injection:**

```[language]
// [How dependencies are injected]
[Code example]
```

**Error Handling:**

```[language]
// [How services handle errors]
[Code example]
```

**Real Example:**
- File: `[path/to/service]`
- Shows: [What it demonstrates]

**Testing Pattern:**

```[language]
// [How to test services]
[Test example]
```

---

## Data Flow Patterns

### [Flow Type 1: e.g., User Action to State Update]

**Sequence:**

```
1. [Step 1: e.g., User clicks button]
   ↓
2. [Step 2: e.g., Component dispatches action]
   ↓
3. [Step 3: e.g., Service makes API call]
   ↓
4. [Step 4: e.g., State updated]
   ↓
5. [Step 5: e.g., UI re-renders]
```

**Code Flow:**

```[language]
// Step 1: Component
[Code showing component trigger]

// Step 2: Action/Event
[Code showing action dispatch]

// Step 3: Service
[Code showing service call]

// Step 4: State Update
[Code showing state update]

// Step 5: Selector
[Code showing data selection]
```

**Real Example:**
- See `[path/to/example]` for complete flow

---

### [Flow Type 2: e.g., API Response to UI]

**Sequence:**

```
[Diagram or steps showing the flow]
```

**Code Example:**

```[language]
[Code showing this flow]
```

---

## Common Abstractions

### [Abstraction 1: e.g., Base Classes, Interfaces, Mixins]

**Purpose:** [Why this abstraction exists]

**Pattern:**

```[language]
// [Description]
[Code showing the abstraction]
```

**Usage:**

```[language]
// [How to use it]
[Code showing usage]
```

**Real Examples:**
- Definition: `[path/to/definition]`
- Usage: `[path/to/usage]`

**When to Extend:**
- ✅ [Scenario 1]
- ✅ [Scenario 2]

**When NOT to Extend:**
- ❌ [Scenario 1]
- ❌ [Scenario 2]

---

### [Abstraction 2: e.g., Utility Functions, Helpers]

**Purpose:** [What problem this solves]

**Pattern:**

```[language]
[Code example]
```

---

## Reusability Patterns

### [Reusable Pattern 1: e.g., Shared Components, Common Utilities]

**Guideline:** [When to create reusable elements]

**Creating Reusable Components:**

**Rule of Three:**
- If code is used 1-2 times: Keep it local
- If code is used 3+ times: Consider extraction
- If code is used across modules: Make it shared

**Pattern:**

```[language]
// [Location of shared code]
[Code showing shared component/utility]
```

**Importing Shared Code:**

```[language]
// [How to import]
[Import example]
```

**Real Examples:**
- `[path/to/shared/component1]`
- `[path/to/shared/component2]`

**Documentation Requirements:**
When creating shared code, include:
- [ ] JSDoc/docstring with description
- [ ] Parameter descriptions
- [ ] Return value description
- [ ] Usage examples
- [ ] Error cases

---

### [Reusable Pattern 2: e.g., HOCs, Decorators, Hooks]

**Purpose:** [What this pattern provides]

**Pattern:**

```[language]
[Code example]
```

---

## Module/Feature Organization

### [Organization Pattern: e.g., Feature Folders, Layer-First, Domain-Driven]

**Directory Structure:**

```
[project-root]/
├── [feature-1]/
│   ├── [file-type-1].[ext]
│   ├── [file-type-2].[ext]
│   └── [file-type-3].[ext]
├── [feature-2]/
│   └── ...
└── [shared]/
    └── ...
```

**Naming Conventions:**
- [Convention 1]: [Pattern]
- [Convention 2]: [Pattern]

**Real Example:**
- See `[path/to/feature]` for complete structure

---

## API Integration Patterns

### [API Pattern: e.g., REST, GraphQL, gRPC]

**HTTP Client:**

```[language]
// [How API client is configured]
[Code example]
```

**Request Pattern:**

```[language]
// [How requests are made]
[Code example]
```

**Response Handling:**

```[language]
// [How responses are processed]
[Code example]
```

**Error Handling:**

```[language]
// [How API errors are handled]
[Code example]
```

**Real Example:**
- File: `[path/to/api/service]`

---

## Dependency Management

### [Dependency Pattern: e.g., Dependency Injection, Service Locator]

**Pattern:**

```[language]
// [How dependencies are managed]
[Code example]
```

**Registration:**

```[language]
// [How services are registered]
[Code example]
```

**Resolution:**

```[language]
// [How dependencies are resolved]
[Code example]
```

---

## Configuration Management

### [Config Pattern: e.g., Environment Variables, Config Files]

**Configuration Loading:**

```[language]
// [How config is loaded]
[Code example]
```

**Accessing Configuration:**

```[language]
// [How to access config values]
[Code example]
```

**Real Example:**
- Config file: `[path/to/config]`
- Usage: `[path/to/usage]`

---

## Performance Patterns

### [Performance Pattern: e.g., Memoization, Lazy Loading, Caching]

**When to Apply:**
- ✅ [Scenario 1]
- ✅ [Scenario 2]

**Pattern:**

```[language]
// [Description]
[Code example]
```

**Real Example:**
- File: `[path/to/example]`
- Performance impact: [metrics]

**Measurement:**
```[language]
// [How to measure performance]
[Code showing measurement]
```

---

## Security Patterns

### [Security Pattern: e.g., Authentication, Authorization, Input Validation]

**Pattern:**

```[language]
// [Description]
[Code example]
```

**Where to Apply:**
- [Location 1]
- [Location 2]

**Real Example:**
- File: `[path/to/example]`

---

## Testing Integration with Patterns

### Unit Testing Pattern Components

**Test Structure:**

```[language]
// [How tests are structured for this pattern]
[Test example]
```

**Mocking Pattern:**

```[language]
// [How to mock dependencies]
[Mock example]
```

**Real Example:**
- Implementation: `[path/to/component]`
- Test: `[path/to/test]`

---

## Pattern Decision Matrix

Use this matrix to choose between patterns:

| Scenario | Pattern to Use | Rationale |
|----------|----------------|-----------|
| [Scenario 1] | [Pattern A] | [Why] |
| [Scenario 2] | [Pattern B] | [Why] |
| [Scenario 3] | [Pattern A or B] | [Decision criteria] |

---

## Pattern Evolution

### Deprecated Patterns

> Document old patterns that should no longer be used

#### [Old Pattern Name]

**Status:** ❌ Deprecated  
**Deprecated Date:** [Date]  
**Reason:** [Why deprecated]  
**Migration Path:** See `[link to migration guide]`  
**Still Found In:** [List of files using old pattern]

**Old Pattern:**
```[language]
// ❌ Don't use this anymore
[Old pattern code]
```

**New Pattern:**
```[language]
// ✅ Use this instead
[New pattern code]
```

---

### Experimental Patterns

> Document patterns being tested but not yet standard

#### [Experimental Pattern Name]

**Status:** 🧪 Experimental  
**Started:** [Date]  
**Testing In:** [Where it's being tested]  
**Feedback:** [Learnings so far]

**Pattern:**
```[language]
[Experimental pattern code]
```

**Evaluation Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

## Quick Reference

**For New Features:**
1. Follow [Primary Pattern Name]
2. Use [State Management Pattern]
3. Structure services per [Service Pattern]
4. Test according to [Test Pattern]

**For Refactoring:**
1. Identify current pattern (see deprecated patterns)
2. Check migration guide (if exists)
3. Apply new pattern incrementally
4. Update tests

**For Code Review:**
- [ ] Follows [Pattern X] for [scenario]
- [ ] No deprecated patterns used
- [ ] Consistent with existing codebase
- [ ] Tests match pattern requirements

---

## Additional Resources

**Internal Documentation:**
- Standards: `.context/standards/[file].md`
- Testing: `.context/testing/[file].md`
- Migration: `.context/architecture/migration-guide.md`

**External References:**
- [Link to framework docs]
- [Link to style guides]
- [Link to design pattern resources]

---

*Last Updated: [Date]*  
*Pattern Count: [Number]*  
*Status: [Draft/In Review/Current]*

## Related

- See also: [migration guide](migration-guide-template.md)
