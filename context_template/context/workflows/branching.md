# Git Branching Strategy

## Branch Structure

```
main (or master)
 │
 ├── develop
 │    │
 │    ├── feature/TICKET-123-user-authentication
 │    ├── feature/TICKET-456-payment-integration
 │    └── bugfix/TICKET-789-fix-login-error
 │
 ├── release/v1.2.0
 │
 └── hotfix/TICKET-999-critical-security-fix
```

## Branch Types

| Branch Type | Pattern | Base Branch | Merge To |
|-------------|---------|-------------|----------|
| Main | `main` | - | - |
| Develop | `develop` | main | main (releases) |
| Feature | `feature/[ticket]-description` | develop | develop |
| Bugfix | `bugfix/[ticket]-description` | develop | develop |
| Release | `release/v[version]` | develop | main, develop |
| Hotfix | `hotfix/[ticket]-description` | main | main, develop |

## Naming Conventions

### Feature Branches
```
feature/TICKET-123-short-description
feature/PROJ-456-add-user-authentication
```

### Bugfix Branches
```
bugfix/TICKET-123-fix-description
bugfix/PROJ-789-fix-login-timeout
```

### Release Branches
```
release/v1.2.0
release/v2.0.0-beta
```

### Hotfix Branches
```
hotfix/TICKET-123-description
hotfix/PROJ-999-fix-security-vulnerability
```

## Workflow

### Feature Development
```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/TICKET-123-new-feature

# 2. Work on feature, commit regularly
git add .
git commit -m "TICKET-123: Add user validation"

# 3. Keep branch updated
git fetch origin
git rebase origin/develop

# 4. Push and create merge request
git push origin feature/TICKET-123-new-feature
```

### Release Process
```bash
# 1. Create release branch from develop
git checkout develop
git checkout -b release/v1.2.0

# 2. Update version numbers, final testing
# 3. Merge to main
git checkout main
git merge release/v1.2.0 --no-ff

# 4. Tag the release
git tag -a v1.2.0 -m "Release v1.2.0"

# 5. Merge back to develop
git checkout develop
git merge release/v1.2.0 --no-ff
```

### Hotfix Process
```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/TICKET-999-critical-fix

# 2. Fix the issue, commit
git commit -m "TICKET-999: Fix critical security issue"

# 3. Merge to main
git checkout main
git merge hotfix/TICKET-999-critical-fix --no-ff
git tag -a v1.2.1 -m "Hotfix v1.2.1"

# 4. Merge to develop
git checkout develop
git merge hotfix/TICKET-999-critical-fix --no-ff
```

## Commit Messages

### Format
```
TICKET-ID[, TICKET-ID]: Brief description (max 50 chars)

Longer description if needed. Explain what and why,
not how. Wrap at 72 characters.

- Bullet points are okay
- Use present tense ("Add feature" not "Added feature")
```

### Examples
```
PROJ-123: Add user authentication

Implement JWT-based authentication with refresh tokens.
- Add login endpoint
- Add token refresh endpoint
- Add middleware for protected routes

PROJ-456: Fix login timeout issue

Users were being logged out after 5 minutes due to
incorrect token expiry configuration.

PROJ-789, PROJ-790: Update registration and profile email validation
```

## Merge Request Guidelines

### Before Creating MR
- [ ] Branch is up to date with target branch
- [ ] All tests pass
- [ ] Linting passes
- [ ] Self-review completed

### MR Description Template
```markdown
## Summary
[Brief description of changes]

## Related Ticket
[TICKET-123](link-to-ticket)

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Add screenshots]
```

## Protected Branches

| Branch | Protection Rules |
|--------|-----------------|
| main | Require MR, require approvals, no force push |
| develop | Require MR, require passing CI |

Configuring these protection rules on the main branch is a required setup prerequisite — protect the branch (no direct pushes), require a merge request, require at least one approval from someone other than the author, reject force-push, and have a human perform the merge. Where your GitLab plan supports it, also require (or at least recommend) **signed commits**: enable a push rule that rejects unsigned commits so cryptographic authorship is enforced on the main branch.

## Git Configuration

### Recommended Settings
```bash
# Set default branch name
git config --global init.defaultBranch main

# Set pull to rebase
git config --global pull.rebase true

# Set push default
git config --global push.default current
```
