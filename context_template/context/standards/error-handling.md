# Error Handling Conventions

## Principles

1. **Fail fast** - Detect and report errors as early as possible
2. **Be specific** - Use specific error types, not generic exceptions
3. **Include context** - Error messages should help diagnose the problem
4. **Don't swallow** - Never catch exceptions without handling or re-throwing
5. **Log appropriately** - Log errors at the right level with sufficient context

## Error Types

### Use Specific Error Classes

```
// Define specific error types for your domain
class ValidationError extends Error {
  constructor(message: string, public field?: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NotFoundError extends Error {
  constructor(resource: string, id: string) {
    super(`${resource} with id '${id}' not found`);
    this.name = 'NotFoundError';
  }
}

class AuthorizationError extends Error {
  constructor(action: string, resource: string) {
    super(`Not authorized to ${action} ${resource}`);
    this.name = 'AuthorizationError';
  }
}
```

### Error Hierarchy
```
ApplicationError (base)
├── ValidationError
├── NotFoundError
├── AuthorizationError
├── ConflictError
└── ExternalServiceError
```

## Handling Patterns

### Service Layer
```
async function getUser(id: string): Promise<User> {
  const user = await repository.findById(id);
  
  if (!user) {
    throw new NotFoundError('User', id);
  }
  
  return user;
}
```

### API/Controller Layer
```
async function handleGetUser(req: Request, res: Response) {
  try {
    const user = await userService.getUser(req.params.id);
    res.json(user);
  } catch (error) {
    if (error instanceof NotFoundError) {
      res.status(404).json({ error: error.message });
    } else if (error instanceof ValidationError) {
      res.status(400).json({ error: error.message });
    } else {
      // Log unexpected errors
      logger.error('Unexpected error in getUser', { error, userId: req.params.id });
      res.status(500).json({ error: 'Internal server error' });
    }
  }
}
```

### External Service Calls
```
async function callExternalApi(data: RequestData): Promise<ResponseData> {
  try {
    const response = await httpClient.post('/api/endpoint', data);
    return response.data;
  } catch (error) {
    // Wrap external errors with context
    throw new ExternalServiceError(
      'PaymentService',
      'processPayment',
      { cause: error, requestId: data.requestId }
    );
  }
}
```

## Validation

### Input Validation
```
function validateUserInput(input: unknown): UserInput {
  if (!input || typeof input !== 'object') {
    throw new ValidationError('Input must be an object');
  }
  
  const { email, name } = input as Record<string, unknown>;
  
  if (!email || typeof email !== 'string') {
    throw new ValidationError('Email is required', 'email');
  }
  
  if (!isValidEmail(email)) {
    throw new ValidationError('Invalid email format', 'email');
  }
  
  if (!name || typeof name !== 'string') {
    throw new ValidationError('Name is required', 'name');
  }
  
  return { email, name };
}
```

## Logging

### Log Levels
| Level | Use For |
|-------|---------|
| ERROR | Unexpected failures requiring attention |
| WARN | Recoverable issues or degraded functionality |
| INFO | Significant business events |
| DEBUG | Diagnostic information for troubleshooting |

### What to Include
```
logger.error('Failed to process order', {
  orderId: order.id,
  customerId: order.customerId,
  error: error.message,
  stack: error.stack,
  // Don't log sensitive data like credit cards, passwords
});
```

## Anti-Patterns to Avoid

### ❌ Swallowing Exceptions
```
// BAD - error is silently ignored
try {
  await riskyOperation();
} catch (error) {
  // do nothing
}
```

### ❌ Catching Too Broadly
```
// BAD - catches everything including programming errors
try {
  doSomething();
} catch (error) {
  return null; // hides bugs
}
```

### ❌ Generic Error Messages
```
// BAD - not helpful for debugging
throw new Error('Error occurred');
throw new Error('Failed');
```

### ❌ Logging Sensitive Data
```
// BAD - security risk
logger.error('Login failed', { password: user.password });
```

## Project-Specific Patterns

<!-- Add your project's specific error handling patterns -->

### [Service/Module 1]
- [Specific error types used]
- [Handling patterns]

### [Service/Module 2]
- [Specific error types used]
- [Handling patterns]
