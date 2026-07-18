# CI/CD Pipeline

## Overview

Describes the Continuous Integration and Continuous Deployment (CI/CD) pipeline for this project.

## Pipeline Stages

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│  Build  │──▶│  Test   │──▶│  Lint   │──▶│ Security│──▶│ Deploy  │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

## Stage Details

### 1. Build
**Trigger**: Every push to any branch
**Purpose**: Compile code, install dependencies, create artifacts

```yaml
build:
  steps:
    - Install dependencies
    - Compile/transpile code
    - Create build artifacts
  artifacts:
    - dist/
    - build/
```

### 2. Test
**Trigger**: After successful build
**Purpose**: Run automated tests

```yaml
test:
  unit:
    - Run unit tests
    - Generate coverage report
    - Fail if coverage < [threshold]%
  
  integration:
    - Start test database
    - Run integration tests
    - Cleanup test environment
```

### 3. Lint
**Trigger**: After build (can run parallel with test)
**Purpose**: Enforce code quality standards

```yaml
lint:
  steps:
    - Run linter ([ESLint/Checkstyle/etc.])
    - Run formatter check ([Prettier/etc.])
    - Run type check (if applicable)
```

### 4. Security
**Trigger**: After lint
**Purpose**: Identify security vulnerabilities

```yaml
security:
  steps:
    - Dependency vulnerability scan
    - SAST (Static Application Security Testing)
    - Secret detection
```

### 5. Deploy
**Trigger**: Merge to main/develop, manual for production
**Purpose**: Deploy to target environment

```yaml
deploy:
  environments:
    development:
      trigger: merge to develop
      approval: none
    staging:
      trigger: merge to main
      approval: none
    production:
      trigger: manual or tag
      approval: required
```

## Environment Configuration

### Development
| Setting | Value |
|---------|-------|
| URL | https://dev.example.com |
| Database | dev-db |
| Logging | Debug |

### Staging
| Setting | Value |
|---------|-------|
| URL | https://staging.example.com |
| Database | staging-db |
| Logging | Info |

### Production
| Setting | Value |
|---------|-------|
| URL | https://example.com |
| Database | prod-db |
| Logging | Warn |

## Pipeline Configuration

### Required Environment Variables
```
# Build
NODE_VERSION=18
BUILD_ARTIFACT_PATH=./dist

# Test
TEST_DATABASE_URL=postgresql://...
COVERAGE_THRESHOLD=80

# Deploy
DEPLOY_SSH_KEY (secret)
DEPLOY_HOST (per environment)
DEPLOY_PATH (per environment)
```

### Secrets Management
| Secret | Used In | Description |
|--------|---------|-------------|
| DEPLOY_SSH_KEY | Deploy stage | SSH key for deployment |
| NPM_TOKEN | Build stage | Private registry access |
| SONAR_TOKEN | Security stage | SonarQube authentication |

## Branch Policies

| Branch | Pipeline | Deploy To |
|--------|----------|-----------|
| feature/* | build, test, lint | - |
| develop | full pipeline | development |
| main | full pipeline | staging |
| release/* | full pipeline | production (manual) |

## Notifications

### Success
- Slack channel: #deployments
- Email: [none/team distribution list]

### Failure
- Slack channel: #ci-failures
- Email: commit author + team lead

## Manual Actions

### Triggering Production Deploy
```bash
# Option 1: Create a release tag
git tag -a v1.2.3 -m "Release 1.2.3"
git push origin v1.2.3

# Option 2: Manual trigger in CI/CD UI
# Navigate to Pipelines > Run Pipeline > Select production
```

### Rollback Procedure
```bash
# Option 1: Redeploy previous version
# In CI/CD UI, find previous successful deploy and click "Retry"

# Option 2: Revert commit and redeploy
git revert [commit-sha]
git push origin main
# Automatic deploy will trigger
```

## Troubleshooting

### Common Failures

| Error | Cause | Solution |
|-------|-------|----------|
| Build fails on dependency install | Version mismatch | Check package-lock.json, clear cache |
| Tests timeout | Database connection | Check TEST_DATABASE_URL, ensure DB is up |
| Deploy fails on SSH | Key issues | Verify DEPLOY_SSH_KEY, check host keys |

### Viewing Logs
- Build logs: Available in CI/CD pipeline view
- Runtime logs: [Log aggregation service/location]

## Metrics

### Tracked Metrics
- Build duration
- Test duration
- Deployment frequency
- Lead time (commit to production)
- Change failure rate
