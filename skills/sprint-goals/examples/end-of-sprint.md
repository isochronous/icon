# Example: End-of-Sprint Report
**Scenario**: Most goals complete, one incomplete, extra work done.

**Input CSV** (simplified):
- Parent: Payment Schedule Modernization | Summary: [NgWi] Create payment schedule list grid | Status: Done
- Parent: Payment Schedule Modernization | Summary: [Domain API] Create GET endpoint for payment schedules | Status: Done
- Parent: Payment Schedule Modernization | Summary: [NgWi] Add export to CSV functionality | Status: Done
- Parent: User Dashboard Enhancements | Summary: [NgWi] Display recent activity feed | Status: To Do (not complete)
- Parent: (no parent) | Summary: Fix critical security vulnerability in authentication | Status: Done (not in original sprint plan)

**Output:**

```
**2024.Q4 Sprint 15 (Nov 1 - Nov 14) - End-of-Sprint Report**

**Payment Schedule Modernization**

* ✅ [Complete] Enable users to view and search payment schedules in the new Angular interface
* ✅ [Complete] Allow users to export payment schedule data to CSV for analysis

**User Dashboard Enhancements**

* ❌ [Not Complete] Display user's recent activity and notifications on dashboard
    *Explanation: WHY - Activity Service API from Platform team was delayed and only delivered on last day of sprint. WHAT - Will complete in first 2 days of next sprint. HOW - Delays overall dashboard release by one sprint, but does not impact other planned work for next sprint.*

**Additional Deliverables**

* ✅ [Complete] Fixed critical authentication vulnerability discovered during sprint (emergency fix)
```
