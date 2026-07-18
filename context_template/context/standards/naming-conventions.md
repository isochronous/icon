# Naming Conventions

## Files and Directories

### General Rules
- Use lowercase with hyphens (kebab-case) for file names
- Use descriptive names that indicate purpose
- Group related files in directories

### Examples by Type
| Type | Convention | Example |
|------|------------|---------|
| Components | `feature-name.component.ext` | `user-profile.component.ts` |
| Services | `feature-name.service.ext` | `authentication.service.ts` |
| Models/Types | `feature-name.model.ext` | `user.model.ts` |
| Tests | `feature-name.spec.ext` or `feature-name.test.ext` | `user.service.spec.ts` |
| Utilities | `utility-name.util.ext` | `date-formatter.util.ts` |

## Code Naming

### Variables
- Use camelCase for variables and function parameters
- Use UPPER_SNAKE_CASE for constants
- Use descriptive names (avoid single letters except for iterators)

```
// Good
const userEmail = 'test@example.com';
const MAX_RETRY_ATTEMPTS = 3;

// Avoid
const e = 'test@example.com';
const max = 3;
```

### Functions/Methods
- Use camelCase
- Start with a verb indicating action
- Be specific about what the function does

```
// Good
function fetchUserById(id: string): Promise<User>
function validateEmailFormat(email: string): boolean
function calculateTotalPrice(items: Item[]): number

// Avoid
function user(id: string)
function check(email: string)
function total(items: Item[])
```

### Classes/Types/Interfaces
- Use PascalCase
- Use nouns or noun phrases
- Interfaces may be prefixed with 'I' (project-specific decision)

```
// Good
class UserService
interface UserRepository  // or IUserRepository
type PaymentMethod

// Avoid
class userService
interface userrepo
```

### Booleans
- Prefix with is, has, can, should, etc.

```
// Good
const isActive = true;
const hasPermission = false;
const canEdit = true;

// Avoid
const active = true;
const permission = false;
```

## Project-Specific Conventions

<!-- Add your project-specific naming rules here -->

### [Feature Area 1]
- [Convention]

### [Feature Area 2]
- [Convention]

## Related

- See also: [code style](code-style.md)
- Governed by: [branching workflow](../workflows/branching.md)
