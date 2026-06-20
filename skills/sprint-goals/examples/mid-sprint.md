# Example: Mid-Sprint Update
**Scenario**: Some goals complete, one blocked, one descoped.

**Input CSV** (simplified):
- Parent: Payment Schedule Modernization | Summary: [NgWi] Create payment schedule list grid | Status: Done
- Parent: Payment Schedule Modernization | Summary: [Domain API] Create GET endpoint for payment schedules | Status: Done
- Parent: Payment Schedule Modernization | Summary: [NgWi] Add export to CSV functionality | Status: In Progress
- Parent: User Dashboard Enhancements | Summary: [NgWi] Display recent activity feed | Status: Blocked
- Parent: User Dashboard Enhancements | Summary: [NgWi] Add quick action buttons | Status: To Do (descoped)

**Output:**

```
**2024.Q4 Sprint 15 (Nov 1 - Nov 14) - Mid-Sprint Update**

**Payment Schedule Modernization**

* ✅ [Complete] Enable users to view and search payment schedules in the new Angular interface
* ✅ [On Target] Allow users to export payment schedule data to CSV for analysis

**User Dashboard Enhancements**

* ⚠️ [Blocked] Display user's recent activity and notifications on dashboard
    *Explanation: WHY - Waiting for Activity Service API changes from Platform team to complete their work. WHAT - Expected to unblock by end of week when Platform team delivers API. HOW - May slip to next sprint if unblocked late, which would delay dashboard release by 2 weeks.*
* ❌ [Descoped] Provide quick access to common actions from dashboard
    *Explanation: WHY - Descoped due to activity feed being blocked and team capacity constraints. WHAT - Will be carried to next sprint once activity feed is complete. HOW - Does not impact overall dashboard release as this is a nice-to-have enhancement.*
```
