---
name: migration-planning
description: >
  Use when a schema migration is needed, a feature flag rollout is planned, a library version jump introduces backward-incompatible changes, or a code review finds that database or API migrations are not backward-compatible.
user-invocable: true
---

# Migration Planning

## Overview

**Every migration is at least two deploys.** The expand phase adds the new path without removing the old; the contract phase removes the old path only after the new path is verified at full production load. Collapsing both into one deploy is the single most common migration failure mode this skill prevents.

## When to Use

- Schema change where existing data must be migrated
- API contract change with live clients depending on the current contract
- Feature flag rollout to a cohort or percentage of users
- Breaking library upgrade requiring parallel import paths
- `code-quality-rules` Pass 3 asks "Are database/API migrations backward-compatible?" and the answer is currently no

**When NOT to use**: Single-file refactors with no data dependency and no live clients consuming the changed interface. Internal-only type renames that touch no persisted state also don't need this process.

## Relationship to dependency-management and code-quality-rules

`dependency-management` covers coexistence strategy for library migrations — adapter pattern, feature flags, parallel imports — and this skill is the full expansion of that guidance. `code-quality-rules` asks the backward-compatibility question during code review; this skill is the upstream discipline that produces a yes answer before review. If a code review is failing the backward-compatibility gate, invoke this skill to produce the plan before re-submitting.

---

## migration-planning: Pattern 1: Two-Phase Deploy (Expand → Contract)

The canonical pattern for any migration with existing consumers.

**Expand phase** (deploy 1):
1. Add the new path alongside the old — new column, new endpoint, new schema version
2. Dual-write to both old and new paths on every write
3. Verify dual-write at production load before proceeding (tail logs, check both destinations)
4. Flip reads to the new path
5. Verify read correctness for a confidence window (hours to days, depending on risk)

**Contract phase** (deploy 2 or later):
1. Remove dual-write — write to new path only
2. Verify no consumers still reading old path
3. Remove old path, column, endpoint, or schema version
4. Verify removal is clean in CI and production

**Verification gate between phases**: Do not proceed to the contract phase until the expand phase has been confirmed at production load. "Deploy and monitor" is not a verification gate — name the metric and threshold.

---

## migration-planning: Pattern 2: Feature Flag Rollout

For behavioral changes that can be toggled without a schema change.

**Rollout plan**:
1. Define the canary cohort (internal users, a named % of traffic, a specific region)
2. Define the rollback trigger — the specific metric threshold that triggers reverting to 0%
3. Define the rollout ladder (e.g., 1% → 10% → 50% → 100%) with a hold window at each step
4. Define the completion criterion — what "100% stable" means before the flag is locked and removed

**Rollback trigger must be named before rollout begins** — not after problems are observed. If you can't name the rollback signal, you can't safely roll out.

**Flag cleanup**: Feature flags that reach 100% stable must be scheduled for removal. A flag that is never removed becomes a permanent branch in every conditional path. Set a removal date at rollout completion.

---

## migration-planning: Pattern 3: Schema Migration with Backfill

For database schema changes affecting existing rows.

**Step-by-step**:
1. **Add column/table as nullable or with a safe default** — never add NOT NULL without a default in the same migration
2. **Write backfill script — make it idempotent** (safe to re-run; produces the same result if rows are already migrated)
3. **Run backfill in production** — in batches with rate limiting to avoid lock contention
4. **Verify backfill completeness** — count rows where new column is still null/default; must be 0 before proceeding
5. **Switch reads to new column**
6. **Switch writes to new column only (remove dual-write)**
7. **Add NOT NULL constraint** (if applicable) — only after writes are fully migrated
8. **Drop legacy column/table** — in a separate deploy, after a rollback window closes

**Never drop the legacy column until**:
- Backfill is verified complete (zero null rows)
- All write paths are migrated
- The rollback window (typically one release cycle) has closed

---

## migration-planning: Pattern 4: Incremental Refactor

For large-scale code changes where the entire refactor cannot be done atomically.

**Strangler-fig approach**:
1. Add an adapter at the boundary between old and new code
2. Route a subset of callers through the new path via the adapter
3. Verify new path in CI and production before expanding
4. Migrate module-by-module — each module migration is an independently shippable commit
5. Keep both paths green in CI throughout — never let the old path go red while the new path is incomplete
6. Delete the old path in a separate commit once all callers are migrated

**Both paths must stay green in CI during the migration period.** A failing old path is a merge blocker, not a TODO.

---

## Rollback Criteria

Every migration plan must name a rollback signal before the first deploy. If you cannot name the signal, the migration is not ready to ship.

| Pattern | Rollback Signal Example |
|---------|------------------------|
| Two-phase deploy | Error rate on new read path exceeds X% |
| Feature flag rollout | Metric Y drops below Z threshold at current % |
| Schema backfill | Backfill error rate exceeds X rows/minute or constraint violation detected |
| Incremental refactor | CI goes red on old path, or integration test failures exceed N |

Rollback must be executable without a code deploy when possible (feature flags, database reads). When rollback requires a code deploy, the rollback procedure must be documented and rehearsed.

---

## Common Mistakes

- **Expand + contract in one deploy** — the most common failure; breaks live consumers
- **No dual-write verification** — assuming dual-write is correct without confirming both paths received identical data
- **Deleting old path before backfill converges** — data loss; the old path is still the source of truth until backfill is verified
- **Rollout % without a stopping signal** — feature flags at 50% with no named rollback trigger are bets, not plans
- **NOT NULL constraint in the same migration as column add** — locks the table on large datasets
- **Flag never removed** — feature flag debt compounds; schedule removal at rollout completion

---

## Rationalization Prevention

| Rationalization | Reality | Correct Action |
|----------------|---------|----------------|
| "It's a small schema change, one deploy is fine" | Small schema changes with existing data are the ones that surprise you | Use Pattern 3 — the process is short for small schemas |
| "We can roll back if there's a problem" | Rollback without a named trigger is not a plan | Name the rollback signal before starting |
| "The backfill is simple, it doesn't need to be idempotent" | Non-idempotent backfills corrupt data if re-run after partial failure | Write idempotent backfills; verify with a dry-run |
| "We'll remove the flag after we're confident" | "Confident" has no definition; the flag stays forever | Set a removal date at rollout completion |
| "The old path will be dead code after the migration" | Dead code that compiles is different from removed code | Delete old path in a named commit, verify CI passes |
