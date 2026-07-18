# Unit Testing Conventions

## Framework and Tools

| Tool | Purpose |
|------|---------|
| [Framework] | Test runner and assertions |
| [Mocking Library] | Mocking/stubbing dependencies |
| [Additional Tools] | [Purpose] |

## Test File Location

Tests are located: [alongside source files / in test directory]

| Source | Test |
|--------|------|
| `src/services/user.service.ts` | `src/services/user.service.spec.ts` |
| `src/components/Button.tsx` | `src/components/Button.test.tsx` |

## Test Structure

### File Organization
```typescript
describe('[UnitUnderTest]', () => {
  // Setup
  let service: UserService;
  let mockDependency: MockType<Dependency>;
  
  beforeEach(() => {
    // Reset mocks and create fresh instance
    mockDependency = createMock<Dependency>();
    service = new UserService(mockDependency);
  });
  
  afterEach(() => {
    // Cleanup if needed
  });
  
  describe('[methodName]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      // Act  
      // Assert
    });
    
    it('should [expected behavior] when [different condition]', () => {
      // ...
    });
  });
  
  describe('[anotherMethod]', () => {
    // ...
  });
});
```

### Naming Conventions
- Describe blocks: Use the name of the unit under test
- It blocks: "should [expected behavior] when [condition]"
- Be specific about what is being tested

```typescript
// Good
it('should return null when user is not found', () => {});
it('should throw ValidationError when email is invalid', () => {});

// Avoid
it('works correctly', () => {});
it('test 1', () => {});
```

## Mocking Patterns

### Creating Mocks
```typescript
// Using [mocking library]
const mockRepository = {
  findById: jest.fn(),
  save: jest.fn(),
};

// Or with auto-mocking
const mockRepository = createMock<UserRepository>();
```

### Setting Up Return Values
```typescript
// Single return value
mockRepository.findById.mockReturnValue(mockUser);

// Promise return value
mockRepository.findById.mockResolvedValue(mockUser);

// Different values per call
mockRepository.findById
  .mockResolvedValueOnce(user1)
  .mockResolvedValueOnce(user2);
  
// Throwing errors
mockRepository.findById.mockRejectedValue(new Error('DB Error'));
```

### Verifying Calls
```typescript
// Was called
expect(mockRepository.save).toHaveBeenCalled();

// Called with specific args
expect(mockRepository.save).toHaveBeenCalledWith(expectedUser);

// Call count
expect(mockRepository.save).toHaveBeenCalledTimes(1);

// Not called
expect(mockRepository.delete).not.toHaveBeenCalled();
```

## Assertion Patterns

### Basic Assertions
```typescript
// Equality
expect(result).toBe(expected);          // Strict equality
expect(result).toEqual(expected);       // Deep equality

// Truthiness
expect(result).toBeTruthy();
expect(result).toBeFalsy();
expect(result).toBeNull();
expect(result).toBeUndefined();

// Numbers
expect(result).toBeGreaterThan(5);
expect(result).toBeLessThanOrEqual(10);

// Strings
expect(result).toContain('substring');
expect(result).toMatch(/pattern/);

// Arrays
expect(array).toContain(item);
expect(array).toHaveLength(3);

// Objects
expect(object).toHaveProperty('key', 'value');
```

### Async Assertions
```typescript
// Resolved value
await expect(promise).resolves.toBe(expected);

// Rejected error
await expect(promise).rejects.toThrow(ErrorType);
await expect(promise).rejects.toThrow('error message');
```

## Test Data

### Factory Functions
```typescript
function createMockUser(overrides?: Partial<User>): User {
  return {
    id: 'test-id',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: new Date('2024-01-01'),
    ...overrides,
  };
}

// Usage
const activeUser = createMockUser({ status: 'ACTIVE' });
const adminUser = createMockUser({ role: 'ADMIN' });
```

### Fixtures
```typescript
// fixtures/users.ts
export const testUsers = {
  standard: createMockUser(),
  admin: createMockUser({ role: 'ADMIN' }),
  inactive: createMockUser({ status: 'INACTIVE' }),
};
```

## Running Tests

```bash
# Run all tests
[command to run all tests]

# Run specific file
[command to run specific file]

# Run tests matching pattern
[command with pattern filter]

# Run with coverage
[command for coverage]
```

## Coverage Requirements

- Minimum overall coverage: [X]%
- Minimum per-file coverage: [X]%
- Critical paths: 100% coverage required

### Excluding from Coverage
```typescript
/* istanbul ignore next */
function debugOnlyCode() {
  // Not counted in coverage
}
```

## Anti-Patterns to Avoid

### ❌ Testing Implementation Details
```typescript
// Bad - tests internal state
expect(service._internalCache.size).toBe(1);

// Good - tests behavior
expect(service.getCachedValue('key')).toBe(expectedValue);
```

### ❌ Non-Deterministic Tests
```typescript
// Bad - depends on current time
expect(result.timestamp).toBe(new Date());

// Good - control time or test range
expect(result.timestamp).toBeInstanceOf(Date);
```

### ❌ Meaningless Assertions
```typescript
// Bad - doesn't verify behavior
expect(result).toBeTruthy();

// Good - verifies specific value
expect(result.status).toBe('SUCCESS');
expect(result.data).toEqual(expectedData);
```

## Related

- See also: [integration testing](integration-testing.md)
