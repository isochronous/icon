# Example: Sprint Retrospective

**Scenario**: Retrospective meeting with no questions and few action items.

**Input Transcription**:
```
Emily: Let's start the retro. What went well this sprint?

David: I think the deployment process improvements really helped. We had zero production issues.

Emily: Agreed. The automated rollback was clutch.

David: Yeah. What didn't go well?

Emily: Communication. I didn't know the database migration was happening until it was done.

David: You're right, my bad. I should have sent out a notice.

Emily: No worries. Just for next time. Let's add a policy - announce any database changes 24 hours in advance in Slack.

David: Sounds good. I'll do that.
```

**Expected Output**:
```markdown
## Summary
The team held a sprint retrospective focusing on recent deployment improvements and communication gaps. Deployment process enhancements, including automated rollbacks, resulted in zero production issues. A new policy was established requiring 24-hour advance notice in Slack for database changes.

## Key Points
- **Deployment Success**: Deployment process improvements, particularly automated rollback functionality, eliminated production issues this sprint
- **Communication Gap**: Database migration occurred without advance notice to the team, highlighting need for better change communication
- **New Policy Established**: All database changes must be announced 24 hours in advance in Slack channel to ensure team awareness

## Questions
No questions were raised during this meeting.

## Action Items
- **Announce database changes 24 hours in advance in Slack before executing** - David - Ongoing

---
```
