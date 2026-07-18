# Integration Testing Conventions

## Scope

Integration tests verify that multiple components work together correctly. They test:
- Service-to-database interactions
- API endpoint behavior
- External service integrations
- Message queue processing

## Test Environment

### Database
- Use: [Real database / In-memory database / Test containers]
- Setup: [How to provision test database]
- Cleanup: [How data is cleaned between tests]

### External Services
- Approach: [Mock servers / Test doubles / Real sandbox environments]
- Tools: [WireMock, nock, mockserver, etc.]

## Test Structure

### Setup and Teardown
```typescript
describe('Integration: [Feature/Module]', () => {
  // One-time setup
  beforeAll(async () => {
    await setupTestDatabase();
    await startMockServer();
  });
  
  // One-time teardown
  afterAll(async () => {
    await cleanupTestDatabase();
    await stopMockServer();
  });
  
  // Per-test setup
  beforeEach(async () => {
    await clearTestData();
    await seedTestData();
  });
  
  describe('[Scenario]', () => {
    it('should [expected behavior]', async () => {
      // Arrange - set up test state
      // Act - perform the operation
      // Assert - verify the outcome
    });
  });
});
```

## API Testing

### HTTP Request Testing
```typescript
describe('GET /api/users/:id', () => {
  it('should return user when found', async () => {
    // Arrange
    const user = await createTestUser({ name: 'Test User' });
    
    // Act
    const response = await request(app)
      .get(`/api/users/${user.id}`)
      .set('Authorization', `Bearer ${testToken}`);
    
    // Assert
    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({
      id: user.id,
      name: 'Test User',
    });
  });
  
  it('should return 404 when user not found', async () => {
    const response = await request(app)
      .get('/api/users/nonexistent')
      .set('Authorization', `Bearer ${testToken}`);
    
    expect(response.status).toBe(404);
  });
  
  it('should return 401 without authentication', async () => {
    const response = await request(app)
      .get('/api/users/123');
    
    expect(response.status).toBe(401);
  });
});
```

## Database Integration

### Repository Testing
```typescript
describe('Integration: UserRepository', () => {
  let repository: UserRepository;
  
  beforeAll(async () => {
    repository = new UserRepository(testDataSource);
  });
  
  beforeEach(async () => {
    await testDataSource.query('DELETE FROM users');
  });
  
  describe('save', () => {
    it('should persist user to database', async () => {
      const user = new User({ email: 'test@example.com', name: 'Test' });
      
      await repository.save(user);
      
      const saved = await repository.findById(user.id);
      expect(saved).toMatchObject({
        email: 'test@example.com',
        name: 'Test',
      });
    });
  });
  
  describe('findByEmail', () => {
    it('should find user by email', async () => {
      await seedUser({ email: 'find@example.com' });
      
      const found = await repository.findByEmail('find@example.com');
      
      expect(found).not.toBeNull();
      expect(found?.email).toBe('find@example.com');
    });
  });
});
```

## External Service Testing

### Mock Server Setup
```typescript
// Using WireMock, nock, or similar
describe('Integration: PaymentService', () => {
  beforeEach(() => {
    // Set up mock responses
    mockPaymentApi
      .post('/charges')
      .reply(200, { id: 'ch_123', status: 'succeeded' });
  });
  
  afterEach(() => {
    // Clear mock expectations
    mockPaymentApi.reset();
  });
  
  it('should process payment through external API', async () => {
    const result = await paymentService.charge({
      amount: 1000,
      currency: 'USD',
    });
    
    expect(result.status).toBe('succeeded');
    expect(mockPaymentApi.isDone()).toBe(true); // Verify mock was called
  });
});
```

## Test Data Management

### Seeding
```typescript
// test/helpers/seed.ts
export async function seedTestData() {
  const admin = await createTestUser({ role: 'ADMIN' });
  const users = await Promise.all([
    createTestUser({ name: 'User 1' }),
    createTestUser({ name: 'User 2' }),
  ]);
  
  return { admin, users };
}
```

### Cleanup Strategies
| Strategy | When to Use |
|----------|-------------|
| Truncate tables | Fast, use for most tests |
| Transaction rollback | Ensures isolation, use for complex scenarios |
| Delete specific records | When truncate is too aggressive |

## Running Integration Tests

```bash
# Run all integration tests
[command]

# Run with specific test database
[command with env vars]

# Run specific integration suite
[command with filter]
```

## Configuration

### Environment Variables
```env
TEST_DATABASE_URL=postgresql://localhost:5432/test_db
TEST_API_BASE_URL=http://localhost:3001
MOCK_SERVER_PORT=9999
```

### Test Configuration
```typescript
// test/config.ts
export const testConfig = {
  database: {
    url: process.env.TEST_DATABASE_URL,
    synchronize: true, // Auto-create schema in test
  },
  api: {
    baseUrl: process.env.TEST_API_BASE_URL || 'http://localhost:3001',
  },
  timeouts: {
    database: 10000,
    api: 5000,
  },
};
```

## Best Practices

1. **Isolate tests** - Each test should be independent
2. **Use realistic data** - Test with data that resembles production
3. **Test error paths** - Include network failures, timeouts, invalid responses
4. **Keep tests fast** - Integration tests should still complete in reasonable time
5. **Document dependencies** - Note what services/databases are needed

## Related

- See also: [unit testing](unit-testing.md)
- Governed by: [CI/CD workflow](../workflows/ci-cd.md)
