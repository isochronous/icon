# Migration Guide Template - [Old Pattern] to [New Pattern]

## Overview

**Migration:** [Old Pattern Name] → [New Pattern Name]

**Status:** [Planning/In Progress/Complete]

**Timeline:** [Start Date] - [Target Completion]

**Scope:** [Description of what's being migrated]

---

## Executive Summary

### Why Migrate?

[Brief explanation of why this migration is needed]

**Benefits:**
- ✅ [Benefit 1]
- ✅ [Benefit 2]
- ✅ [Benefit 3]

**Costs:**
- ⚠️ [Cost/Risk 1]
- ⚠️ [Cost/Risk 2]

**Decision:** [Proceed/Don't Proceed] - [Rationale]

---

## Current State (Before Migration)

### Old Pattern Description

**Pattern Name:** [Old Pattern Name]

**Used In:**
- [Module/File 1]
- [Module/File 2]
- [Module/File 3]
- Total files: [count]

**Characteristics:**
- [Characteristic 1]
- [Characteristic 2]
- [Characteristic 3]

**Code Example:**

```[language]
// Example of current/old pattern
[Code showing old approach]

// Key issues:
// - [Issue 1]
// - [Issue 2]
// - [Issue 3]
```

**Real Example:**
- File: `[path/to/old/pattern/example]`

---

### Problems with Current Approach

#### Problem 1: [Problem Name]

**Description:** [What the problem is]

**Impact:**
- [Impact on development]
- [Impact on performance]
- [Impact on maintainability]

**Example:**
```[language]
// Code showing the problem
[Code example]
```

**Where Found:**
- [File 1]
- [File 2]

---

#### Problem 2: [Problem Name]

**Description:** [What the problem is]

**Impact:** [Impact description]

**Example:**
```[language]
[Code example]
```

---

## Target State (After Migration)

### New Pattern Description

**Pattern Name:** [New Pattern Name]

**Characteristics:**
- [Characteristic 1]
- [Characteristic 2]
- [Characteristic 3]

**Code Example:**

```[language]
// Example of new/target pattern
[Code showing new approach]

// Key improvements:
// - [Improvement 1]
// - [Improvement 2]
// - [Improvement 3]
```

**Real Example:**
- File: `[path/to/new/pattern/example]`

---

### How New Pattern Solves Problems

| Old Problem | New Solution | Benefit |
|-------------|--------------|---------|
| [Problem 1] | [Solution 1] | [Benefit] |
| [Problem 2] | [Solution 2] | [Benefit] |
| [Problem 3] | [Solution 3] | [Benefit] |

---

## When to Migrate

### Triggers for Migration

Migrate when:
- ✅ **Touching 5+ files** in old pattern (migrate while refactoring)
- ✅ **Adding new feature** (use new pattern from start)
- ✅ **Major refactoring** (good time to migrate)
- ✅ **Performance issues** caused by old pattern
- ✅ **Team decides** to allocate specific migration time

Don't migrate when:
- ❌ **Small bug fix** (< 3 files touched)
- ❌ **Urgent hotfix** (stability over migration)
- ❌ **Code works fine** and not being touched
- ❌ **Near deadline** (minimize risk)

### Indicators Migration is Needed

- [Indicator 1: e.g., "Code duplication across modules"]
- [Indicator 2: e.g., "Difficulty testing"]
- [Indicator 3: e.g., "Performance degradation"]

---

## Migration Strategy

### Approach

**Strategy:** [Incremental/Big Bang/Module-by-Module/etc.]

**Rationale:** [Why this approach was chosen]

**Phases:**
1. [Phase 1 description]
2. [Phase 2 description]
3. [Phase 3 description]

---

### Phase 1: [Phase Name, e.g., Preparation]

**Goal:** [What this phase achieves]

**Timeline:** [Estimate]

**Steps:**

1. **[Step 1 Name]**
   - Action: [What to do]
   - Output: [What's produced]
   - Validation: [How to verify]

2. **[Step 2 Name]**
   - Action: [What to do]
   - Output: [What's produced]
   - Validation: [How to verify]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

### Phase 2: [Phase Name, e.g., Core Migration]

**Goal:** [What this phase achieves]

**Timeline:** [Estimate]

**Steps:**

1. **[Step 1]**
2. **[Step 2]**
3. **[Step 3]**

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

### Phase 3: [Phase Name, e.g., Cleanup]

**Goal:** [What this phase achieves]

**Timeline:** [Estimate]

**Steps:**

1. **[Step 1]**
2. **[Step 2]**

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

## Step-by-Step Migration Process

### For Each File/Module to Migrate:

#### Step 1: Preparation

**Actions:**
1. Read the old code thoroughly
2. Identify dependencies
3. Check test coverage
4. Create feature branch

**Checklist:**
- [ ] Old code understood
- [ ] Dependencies identified
- [ ] Tests exist (or write them first)
- [ ] Branch created: `migrate/[component-name]`

---

#### Step 2: Create New Structure

**Actions:**
1. Create new files following new pattern
2. Implement new pattern
3. Preserve existing behavior

**Code Template:**

```[language]
// New pattern structure
[Template showing the new pattern structure]
```

**Checklist:**
- [ ] New files created
- [ ] New pattern implemented
- [ ] Behavior matches old implementation

---

#### Step 3: Update Tests

**Actions:**
1. Update existing tests for new structure
2. Add tests for new pattern features
3. Ensure all tests pass

**Test Pattern:**

```[language]
// Updated test structure
[Test example]
```

**Checklist:**
- [ ] Tests updated
- [ ] New tests added
- [ ] All tests pass
- [ ] Coverage maintained or improved

---

#### Step 4: Update References

**Actions:**
1. Update imports in dependent files
2. Update configuration if needed
3. Update documentation

**Checklist:**
- [ ] All imports updated
- [ ] Configuration updated
- [ ] Documentation updated
- [ ] No references to old pattern remain

---

#### Step 5: Verify and Clean Up

**Actions:**
1. Run full test suite
2. Check application builds
3. Test manually in dev environment
4. Remove old files

**Checklist:**
- [ ] All tests pass
- [ ] Application builds successfully
- [ ] Manual testing complete
- [ ] Old files removed
- [ ] Code review complete

---

## Code Transformation Examples

### Example 1: [Common Scenario]

#### Before (Old Pattern)

```[language]
// Old pattern code
[Code example showing old approach]
```

**Issues:**
- [Issue 1]
- [Issue 2]

#### After (New Pattern)

```[language]
// New pattern code
[Code example showing new approach]
```

**Improvements:**
- [Improvement 1]
- [Improvement 2]

**Migration Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

---

### Example 2: [Another Common Scenario]

#### Before (Old Pattern)

```[language]
[Old code]
```

#### After (New Pattern)

```[language]
[New code]
```

**Migration Steps:**
1. [Step 1]
2. [Step 2]

---

### Example 3: [Edge Case Scenario]

#### Before (Old Pattern)

```[language]
[Old code]
```

#### After (New Pattern)

```[language]
[New code]
```

**Special Considerations:**
- [Consideration 1]
- [Consideration 2]

---

## Testing Implications

### Test Strategy During Migration

**Approach:** [How to ensure quality during migration]

**Test Coverage Requirements:**
- Maintain minimum [X]% coverage
- Test old pattern continues working
- Test new pattern works correctly
- Test integration between old and new (during transition)

### Testing Checklist Per Migration

- [ ] **Unit tests** updated/created
- [ ] **Integration tests** updated/created
- [ ] **E2E tests** still pass (if applicable)
- [ ] **Manual testing** performed
- [ ] **Regression testing** complete

### Test Pattern Migration

**Old Test Pattern:**
```[language]
// How tests were written before
[Old test example]
```

**New Test Pattern:**
```[language]
// How tests should be written now
[New test example]
```

---

## Rollback Strategy

### When to Rollback

Rollback if:
- ⚠️ Critical bugs found in production
- ⚠️ Performance degradation > [threshold]
- ⚠️ Migration cannot complete in timeline
- ⚠️ Unforeseen technical blockers

### Rollback Process

**Step 1: Identify Issue**
- [How to detect problems]
- [Metrics to monitor]

**Step 2: Execute Rollback**
```bash
# Commands to rollback
[Rollback commands/steps]
```

**Step 3: Verify Rollback**
- [ ] Old pattern restored
- [ ] Application functional
- [ ] No data loss
- [ ] Tests passing

**Step 4: Post-Mortem**
- Document what went wrong
- Identify root cause
- Update migration plan
- Schedule retry

---

## Common Pitfalls

### Pitfall 1: [Common Mistake]

**Description:** [What developers commonly do wrong]

**Why It's Wrong:** [Explanation]

**How to Avoid:**
- [Prevention step 1]
- [Prevention step 2]

**Example:**
```[language]
// ❌ Wrong approach
[Bad code]

// ✅ Correct approach
[Good code]
```

---

### Pitfall 2: [Another Common Mistake]

**Description:** [What the mistake is]

**How to Avoid:**
- [Prevention step]

---

## Migration Tracking

### Progress Dashboard

**Overall Progress:** [X]% complete

| Module/Area | Files | Status | Notes |
|-------------|-------|--------|-------|
| [Module 1] | [count] | ✅ Complete | [Notes] |
| [Module 2] | [count] | 🔄 In Progress | [Notes] |
| [Module 3] | [count] | ⏸️ Not Started | [Notes] |

**Total:**
- Files migrated: [X] / [Total]
- Tests updated: [X] / [Total]
- Documentation updated: [X] / [Total]

---

### Weekly Progress Template

```markdown
## Week of [Date]

**Migrated:**
- [File/Module 1]
- [File/Module 2]

**Blockers:**
- [Blocker 1]

**Next Week:**
- [Plan 1]
- [Plan 2]

**Metrics:**
- Files migrated: [count]
- Tests passing: [count]
- Coverage: [percent]%
```

---

## Coexistence Strategy

During migration, old and new patterns will coexist:

### Guidelines for Coexistence

**For New Code:**
- ✅ Always use new pattern
- ✅ Even if calling old pattern code

**For Bug Fixes:**
- If < 3 files: Keep old pattern
- If > 3 files: Migrate while fixing

**For Refactoring:**
- If touching file: Migrate it
- If module-wide: Migrate whole module

**Integration Between Patterns:**

```[language]
// How old pattern calls new pattern
[Code example]

// How new pattern calls old pattern (if needed)
[Code example]
```

---

## Success Criteria

Migration is complete when:

- [ ] **All target files migrated** (or deprecated files documented)
- [ ] **All tests passing** (unit, integration, E2E)
- [ ] **Documentation updated** (code, architecture, standards)
- [ ] **Performance benchmarks met** ([metric] within [threshold])
- [ ] **Team trained** on new pattern
- [ ] **Code review standards updated** to enforce new pattern
- [ ] **No blocker issues** remaining
- [ ] **Old pattern removed** (or marked deprecated)

---

## Post-Migration

### Cleanup Tasks

After successful migration:

- [ ] Remove old pattern files
- [ ] Update `.context/architecture/patterns.md`
- [ ] Update `.context/standards/` documentation
- [ ] Mark old pattern as deprecated
- [ ] Update code review checklist
- [ ] Celebrate! 🎉

### Lessons Learned

**What Went Well:**
- [Success 1]
- [Success 2]

**What Could Be Improved:**
- [Improvement 1]
- [Improvement 2]

**Patterns Worth Repeating:**
- [Pattern 1]

**Unexpected Challenges:**
- [Challenge 1]: [How resolved]
- [Challenge 2]: [How resolved]

---

## Resources

**Documentation:**
- Old pattern: `.context/architecture/[old-pattern].md`
- New pattern: `.context/architecture/patterns.md#[new-pattern]`
- Standards: `.context/standards/`

**Examples:**
- Migration branch: `migrate/[example]`
- Completed migration: `[path/to/migrated/module]`

**Tools:**
- [Tool 1]: [Purpose]
- [Tool 2]: [Purpose]

**Contacts:**
- Migration lead: [Name]
- Architecture reviewer: [Name]

---

*Migration Guide Version: 1.0*  
*Last Updated: [Date]*  
*Status: [Draft/Active/Complete]*
