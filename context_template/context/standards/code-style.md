# Code Style Guide

## Formatting

### Indentation
- Use [spaces/tabs] with [N] characters

### Line Length
- Maximum line length: [80/100/120] characters
- Break long lines at logical points

### Braces
- [Same line / New line] for opening braces
- Always use braces for control structures, even single statements

## Imports/Includes

### Organization
Organize imports in this order:
1. Standard library / Framework imports
2. Third-party library imports
3. Internal/project imports
4. Relative imports

### Example
```
// Standard library
import { Component } from '@angular/core';

// Third-party
import { Store } from '@ngxs/store';
import { Observable } from 'rxjs';

// Internal packages
import { ApiService } from '@myorg/api-client';

// Relative imports
import { UserModel } from '../models/user.model';
import { formatDate } from './utils';
```

## Comments

### When to Comment
- Complex business logic that isn't self-explanatory
- Workarounds with links to issues/tickets
- Public API documentation
- TODO items with ticket references

### When NOT to Comment
- Obvious code that is self-documenting
- Commented-out code (delete it instead)
- Redundant comments that repeat the code

### Format
```
// Single line comment for brief notes

/**
 * Multi-line documentation for public APIs
 * @param paramName Description of parameter
 * @returns Description of return value
 */

// TODO(TICKET-123): Description of what needs to be done
```

## Control Structures

### Conditionals
```
// Prefer early returns to reduce nesting
function processUser(user: User): Result {
  if (!user) {
    return Result.error('User required');
  }
  
  if (!user.isActive) {
    return Result.error('User inactive');
  }
  
  // Main logic here
  return Result.success(processedUser);
}
```

### Loops
```
// Prefer functional methods when appropriate
const activeUsers = users.filter(u => u.isActive);
const userNames = users.map(u => u.name);

// Use traditional loops for complex logic or performance
for (const user of users) {
  // complex processing
}
```

## Error Handling

### Exceptions
- Throw specific exception types, not generic errors
- Include context in error messages
- Don't swallow exceptions silently

```
// Good
throw new ValidationError(`Invalid email format: ${email}`);

// Avoid
throw new Error('Error');
throw 'something went wrong';
```

### Async Error Handling
```
// Use try-catch with async/await
try {
  const result = await fetchData();
  return process(result);
} catch (error) {
  logger.error('Failed to fetch data', { error, context });
  throw new DataFetchError('Unable to retrieve data', { cause: error });
}
```

## Project-Specific Rules

<!-- Add any project-specific style rules here -->

### [Area 1]
- [Rule]

### [Area 2]
- [Rule]
