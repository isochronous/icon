---
name: post-meeting
description: >
  Transforms meeting transcriptions into structured summaries with key points, Q&A, and action items. Use when processing voice/video meeting transcripts to create searchable documentation and track follow-ups. Extracts decisions, unresolved questions, and commitments from verbose recordings.
user-invocable: true
---

# Post-Meeting Documentation Skill

## Overview

Synthesizes meeting transcriptions into clear, actionable documentation — extracting key points, matching questions with answers, and surfacing action items from verbose recordings into structured, searchable summaries.

**Core Capabilities:**
- Extract essential discussion points from transcriptions
- Identify and match questions with their answers
- Surface commitments and action items
- Create concise summaries for absent team members
- Preserve institutional knowledge

## Why This Matters

Reading full transcriptions or watching recordings is slow; details get buried, questions go unanswered, action items scatter.

**Benefits of structured summaries:**
- **Time Savings**: absent members grasp outcomes without the recording
- **Accountability**: commitments and action items with clear ownership
- **Knowledge Preservation**: searchable reference for future decisions
- **Follow-up Management**: unanswered questions get addressed
- **Decision Context**: the rationale behind choices captured

**Target Audience:** members who missed the meeting, participants needing a record of decisions, future members seeking context for past decisions.

## Inputs and Outputs

### Inputs
- **Meeting transcription** (text format)
  - Voice-to-text from recording tools (Zoom, Teams, etc.)
  - Live transcription services
  - Manual notes converted to text

### Outputs
Structured markdown document with:
- **Summary**: 2-4 sentence overview of meeting purpose and outcomes
- **Key Points**: 3-8 major discussion topics with context and outcomes
- **Questions**: All substantive questions raised, matched with answers when available
- **Action Items**: Specific commitments with owner and timeline

## Step-by-Step Process

### post-meeting: Step 1: Read and Analyze the Transcription

Review the entire transcription to understand:
- Overall purpose and topic
- Major discussion points and themes
- Decisions made
- Questions raised
- Action items committed to
- Unresolved issues or open questions

**Time Investment**: a full read-through catches connections between early and late discussion points.

### post-meeting: Step 2: Extract Key Points

Identify the most important discussion points.

**For each key point:**
- **Topic**: what was discussed?
- **Context**: enough detail for someone who wasn't there
- **Outcome**: decision made? agreement reached? follow-up needed?

**Guidelines**:
- Focus on substance, not conversational flow
- Combine related discussion scattered through the meeting
- Omit small talk, tangents, and procedural discussion
- Typically 3-8 key points for a 1-hour meeting
- Prioritize decisions over general discussion

### post-meeting: Step 3: Identify Questions and Answers

Extract all substantive questions raised.

**For answered questions**:
- **Question**: State it clearly and concisely
- **Answer**: The answer given during the meeting

**For unanswered questions**:
- **Question**: State it
- **Answer**: Leave blank
- **Action**: Add a follow-up action item (e.g. "Research X and report back")

**Guidelines**:
- Rephrase rambling questions into clear, direct ones
- Consolidate similar questions from multiple people
- Focus on substantive questions, not clarifications like "Can you repeat that?"
- Include rhetorical questions if they prompted important discussion

### post-meeting: Step 4: Capture Action Items

Extract all commitments, tasks, and follow-ups mentioned.

**Format each action item with**:
- **What**: The specific action
- **Who**: The person responsible (if mentioned)
- **When**: Deadline or timeline (if mentioned)

**Guidelines**:
- **Be specific**: "Update the dashboard" → "Update customer dashboard to show real-time inventory status"
- Include unanswered questions as follow-up action items
- If responsibility is unclear, note "Owner TBD"
- If deadline is unclear, note "Timeline TBD"
- Avoid vague actions like "look into it" — clarify what it means

### post-meeting: Step 5: Write the Summary

Create a concise overview (2-4 sentences) capturing:
- The meeting's purpose
- Primary topics discussed
- Major outcomes or decisions

**Guidelines**:
- Write for someone who wasn't there
- Highlight what matters most
- Convey meaning and outcome, not just a topic list
- Answer: "Why did this meeting happen and what changed because of it?"

### post-meeting: Step 6: Organize the Output

Structure the document following the exact format in the Output Format section below. Keep it consistent across meetings for easy scanning and comparison.

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

- [`examples/sprint-planning.md`](examples/sprint-planning.md) — sprint planning with multiple action items and an open architectural question.
- [`examples/sprint-retrospective.md`](examples/sprint-retrospective.md) — short retro, no questions, single action item; a minimal-output reference.

## Edge Cases

### Case 1: No Clear Outcomes
**Situation**: discussion-only meeting, no decisions or action items.
**Handling**: focus Key Points on topics explored and perspectives shared; note in the summary that it was exploratory; write "No action items were identified" rather than force artificial ones.

### Case 2: Highly Technical Discussion
**Situation**: transcription contains jargon and technical detail.
**Handling**: preserve technical terms as-is; give just enough context to recall the discussion; don't explain basics the team knows.

### Case 3: Heated Disagreement
**Situation**: transcription shows conflict or strong disagreement.
**Handling**: focus on the substance of positions, not tone; document both viewpoints objectively; note whether resolution was reached; don't editorialize or take sides.

### Case 4: Off-Topic Tangents
**Situation**: meeting wandered off agenda.
**Handling**: omit purely social conversation; include substantive tangents that led to decisions; note in the summary if extra topics were covered.

### Case 5: Unclear Ownership
**Situation**: action items mentioned but responsibility unclear.
**Handling**: note "Owner TBD" and create an action item to assign one; flag tentative volunteers as "tentative"; don't guess or assign responsibility not stated in the meeting.

## Quality Checklist

Before finalizing, verify each section:

**Summary** — 2-4 sentences; readable cold by someone who wasn't there; highlights the most important outcome.

**Key Points** — 3-8 points for a typical 1-hour meeting; each with a clear topic header; outcomes or next steps included; the **why** behind decisions captured, not just the what; related discussions combined, not scattered. Be generous with detail — this is the primary reference document.

**Questions** — all substantive questions captured; rephrased for clarity if needed; answers provided when available; blank answers flagged with corresponding action items; similar questions consolidated.

**Action Items** — specific, actionable descriptions; owner identified (or "Owner TBD"); timeline specified (or "Timeline TBD"); related items grouped; dependencies flagged; every unanswered question has a follow-up action; no vague commitments like "look into it".

**Overall** — format matches the Output Format template exactly; markdown renders correctly; no conversational filler ("um", "like", repetitions); technical terms used exactly as in the discussion; self-contained for future reference; nothing invented or editorialized.

## Tips by Meeting Type

- **Long (2h+)**: break the transcription into logical sections before processing.
- **Multi-topic**: use clear topic headers in Key Points for scannability.
- **Cross-speaker questions**: consolidate into a single clear question with a composite answer.
- **Follow-up meetings**: cross-reference the previous summary to track progress on prior action items.
