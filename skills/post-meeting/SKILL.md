---
name: post-meeting
description: >
  Transforms meeting transcriptions into structured summaries with key points, Q&A, and action items. Use when processing voice/video meeting transcripts to create searchable documentation and track follow-ups. Extracts decisions, unresolved questions, and commitments from verbose recordings.
user-invocable: true
---

# Post-Meeting Documentation Skill

## Overview

This skill synthesizes meeting transcriptions into clear, actionable documentation. It extracts key points, identifies questions and answers, and surfaces action items from verbose meeting recordings, transforming conversational flow into structured, searchable summaries.

**Core Capabilities:**
- Extract essential discussion points from transcriptions
- Identify and match questions with their answers
- Surface commitments and action items
- Create concise summaries for absent team members
- Preserve institutional knowledge

## Why This Matters

Reading full meeting transcriptions or watching recordings is time-consuming and inefficient. Important details get buried in conversation flow, questions go unanswered, and action items are scattered throughout. 

**Benefits of structured summaries:**
- **Time Savings**: Absent team members quickly understand outcomes without watching full recordings
- **Accountability**: Track commitments and action items with clear ownership
- **Knowledge Preservation**: Create searchable reference documentation for future decisions
- **Follow-up Management**: Ensure unanswered questions are addressed
- **Decision Context**: Provide rationale for choices made during discussions

**Target Audience:**
- Team members who missed the meeting
- Meeting participants needing a record of decisions
- Future team members seeking context for past decisions

## Inputs and Outputs

### Inputs
- **Meeting transcription** (text format)
  - Voice-to-text from recording tools (Zoom, Teams, etc.)
  - Live transcription services
  - Manual notes converted to text

### Outputs
Structured markdown document containing:
- **Summary**: 2-4 sentence overview of meeting purpose and outcomes
- **Key Points**: 3-8 major discussion topics with context and outcomes
- **Questions**: All substantive questions raised, matched with answers when available
- **Action Items**: Specific commitments with owner and timeline

## Step-by-Step Process

### post-meeting: Step 1: Read and Analyze the Transcription

Carefully review the entire meeting transcription to understand:
- The overall purpose and topic of the meeting
- Major discussion points and themes
- Decisions that were made
- Questions that were raised
- Action items that were committed to
- Unresolved issues or open questions

**Time Investment**: Full read-through ensures you don't miss connections between early and late discussion points.

### post-meeting: Step 2: Extract Key Points

Identify the most important discussion points from the meeting.

**For each key point:**
- **State the topic clearly**: What was being discussed?
- **Provide essential context**: Enough detail for someone who wasn't there to understand
- **Include outcomes**: Was a decision made? Was agreement reached? Is follow-up needed?

**Guidelines**:
- Focus on substance, not conversational flow
- Combine related discussion scattered throughout the meeting
- Omit small talk, off-topic tangents, and procedural discussions
- Typically 3-8 key points for a 1-hour meeting
- Prioritize decisions over general discussion

### post-meeting: Step 3: Identify Questions and Answers

Extract all substantive questions raised during the meeting.

**For answered questions**:
- **Question**: State the question clearly and concisely
- **Answer**: Provide the answer given during the meeting

**For unanswered questions**:
- **Question**: State the question
- **Answer**: Leave blank
- **Action**: Add a follow-up action item (e.g., "Research X and report back")

**Guidelines**:
- Rephrase rambling questions into clear, direct questions
- If multiple people asked similar questions, consolidate them
- Focus on substantive questions, not clarifications like "Can you repeat that?"
- Include rhetorical questions if they prompted important discussion

### post-meeting: Step 4: Capture Action Items

Extract all commitments, tasks, and follow-ups mentioned.

**Format each action item with**:
- **What**: The specific action to be taken
- **Who**: The person responsible (if mentioned)
- **When**: Deadline or timeline (if mentioned)

**Guidelines**:
- **Be specific**: "Update the dashboard" → "Update customer dashboard to show real-time inventory status"
- Include unanswered questions as action items for follow-up
- If responsibility is unclear, note "Owner TBD"
- If deadline is unclear, note "Timeline TBD"
- Avoid vague actions like "look into it" - clarify what "looking into it" means

### post-meeting: Step 5: Write the Summary

Create a concise overview (2-4 sentences) that captures:
- The meeting's purpose
- Primary topics discussed
- Major outcomes or decisions

**Guidelines**:
- Write for someone who wasn't there
- Highlight what matters most
- Don't just list topics - convey meaning and outcome
- Answer: "Why did this meeting happen and what changed because of it?"

### post-meeting: Step 6: Organize the Output

Structure the document following the exact format specified in the Output Format section below. Ensure consistency across all meetings for easy scanning and comparison.

## Output Format

```markdown
## Summary
[2-4 sentences capturing the meeting's purpose, main topics, and key outcomes]

## Key Points
- **[Topic 1]**: [Description with context and outcome]
- **[Topic 2]**: [Description with context and outcome]
- **[Topic 3]**: [Description with context and outcome]
[Continue as needed]

## Questions
**Q**: [First question]  
**A**: [Answer if provided, otherwise leave blank]

**Q**: [Second question]  
**A**: [Answer if provided, otherwise leave blank]

[Continue as needed]

## Action Items
- **[Action description]** - [Owner] - [Timeline/Deadline]
- **[Action description]** - [Owner TBD] - [Timeline TBD]
[Continue as needed]

---

*If there were no questions, write: "No questions were raised during this meeting."*  
*If there were no action items, write: "No action items were identified."*
```

## Examples

Two worked transformations live alongside this skill:

- [`examples/sprint-planning.md`](examples/sprint-planning.md) — sprint planning transcription with multiple action items and an open architectural question.
- [`examples/sprint-retrospective.md`](examples/sprint-retrospective.md) — short retro with no questions and a single action item; useful as a minimal-output reference.

## Edge Cases

### Case 1: Meeting with No Clear Outcomes
**Situation**: Discussion-only meeting with no decisions or action items.
**Handling**: 
- Focus Key Points on the topics explored and perspectives shared
- Note in summary that meeting was exploratory
- Write "No action items were identified" rather than forcing artificial action items

### Case 2: Highly Technical Discussion
**Situation**: Transcription contains jargon and technical details.
**Handling**:
- Preserve technical terms as-is (don't simplify)
- Provide just enough context for team members to recall discussion
- Don't explain basic concepts the team already knows

### Case 3: Heated Disagreement
**Situation**: Transcription shows conflict or strong disagreement.
**Handling**:
- Focus on substance of positions, not emotional tone
- Document both viewpoints objectively
- Note if resolution was reached or if follow-up is needed
- Don't editorialize or take sides

### Case 4: Off-Topic Tangents
**Situation**: Meeting wandered significantly off agenda.
**Handling**:
- Omit purely social conversations
- Include substantive tangents if they led to decisions
- Note in summary if meeting covered additional topics beyond original purpose

### Case 5: Unclear Ownership
**Situation**: Action items mentioned but responsibility unclear.
**Handling**:
- Note "Owner TBD" and create action item to assign owner
- If someone volunteered tentatively, note with "tentative" flag
- Don't guess or assign responsibility not stated in meeting

## Quality Checklist

Before finalizing the summary, verify each section:

**Summary** — 2-4 sentences; readable cold by someone who wasn't in the meeting; highlights the most important outcome.

**Key Points** — 3-8 points for a typical 1-hour meeting; each has a clear topic header; outcomes or next steps included; the **why** behind decisions captured, not just the what; related discussions combined, not scattered. Be generous with detail — this becomes the primary reference document.

**Questions** — all substantive questions captured; rephrased for clarity if needed; answers provided when available; blank answers flagged with corresponding action items; similar questions consolidated.

**Action Items** — specific, actionable descriptions; owner identified (or marked "Owner TBD"); timeline specified (or "Timeline TBD"); related action items grouped; dependencies between action items flagged; every unanswered question has a follow-up action; no vague commitments like "look into it".

**Overall** — format matches the Output Format template exactly; markdown rendering correct; no conversational filler preserved ("um", "like", repetitions); technical terms used exactly as in the discussion; self-contained for future reference; nothing invented or editorialized.

## Tips by Meeting Type

- **Long (2h+)**: break the transcription into logical sections before processing.
- **Multi-topic**: use clear topic headers in Key Points so the doc is scannable.
- **Cross-speaker questions**: consolidate into a single clear question with a composite answer.
- **Follow-up meetings**: cross-reference the previous summary to track progress on prior action items.
