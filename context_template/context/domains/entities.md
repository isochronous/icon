# [Domain Area Name]

> Rename this file to match the domain area (e.g., `payments.md`, `loans.md`, `user-management.md`).
> Create one file per major application domain.

## Overview

[What this domain area covers and its role in the application]

## Key Entities

### [Entity Name]
**Description**: [What this entity represents]
**Location**: [File path to entity definition, e.g., `src/features/payments/models/payment.ts`]

| Property | Type | Description |
|----------|------|-------------|
| id | string/uuid | Unique identifier |
| [property] | [type] | [Description] |

**Relationships**: [e.g., "belongs to Account, has many Transactions"]

## Business Rules

- [Rule 1: e.g., "Payments cannot exceed account balance"]
- [Rule 2: e.g., "Refunds must reference the original transaction"]

## Domain Terminology

| Term | Definition |
|------|-----------|
| [Term] | [What it means in this domain area] |

## Key Code Paths

- **[Flow name]**: [Brief description] — see `src/features/[area]/[file]`
- **[Flow name]**: [Brief description] — see `src/features/[area]/[file]`

## State Transitions

| Status | Transitions To | Trigger |
|--------|---------------|---------|
| [Status] | [Next status] | [What causes transition] |
