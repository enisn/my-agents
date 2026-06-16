---
name: concrete-section-titles
description: Revise article, documentation, blog post, and guide section headings so they use direct, concrete topic labels instead of rhetorical or AI-styled titles such as "Why X Matters", "What X Means", "How X Helps", or vague benefit-led headings. Use when editing headings, outlines, article titles, section titles, or table-of-contents labels for ABP community articles, technical blogs, documentation, release posts, tutorials, and similar written content.
---

# Concrete Section Titles

## Goal

Make headings read like stable section labels, not prompt-generated article hooks. Prefer exact nouns and workflow names that tell the reader what the section contains.

## Title Rules

- Use concrete topic labels: `Git In The AI Workflow`, `Changed Files And Diff Review`, `Pull Request Feedback Context`.
- Prefer domain nouns and product workflow terms over persuasion words.
- Keep headings short, usually 3-7 words.
- Match the section body. If the section is about an action, name the action. If it is about a context source, name the context source.
- Keep series titles consistent with neighboring articles, but remove rhetorical phrasing inside section headings.
- Use title case only when the surrounding article uses title case. Otherwise preserve the local heading style.

Avoid these patterns unless the user explicitly asks for marketing/editorial style:

- `Why ... Matters`
- `What ... Means`
- `How ... Helps`
- `The Power Of ...`
- `Unlocking ...`
- `A Better Way To ...`
- `From ... To ...`
- vague value labels such as `More Confidence`, `Better Collaboration`, `A Smarter Workflow`

## Editing Workflow

1. Read the current headings and enough surrounding prose to understand each section.
2. Preserve the article's current order and structure unless the user asks for outline changes.
3. Replace rhetorical headings with concrete labels that describe the section itself.
4. Avoid changing body text unless a heading change makes one nearby transition awkward.
5. If editing a file, patch only heading lines and the minimum necessary surrounding text.
6. Validate that no image anchors, table of contents links, or explicit heading references broke.

## Examples

Use replacements like these:

```text
Why Git Matters In An AI Workflow -> Git In The AI Workflow
Starting From A Solution -> Initializing Git For A Solution
Reviewing Changes Where They Happen -> Changed Files And Diff Review
Committing With Intention -> Selected Files And Commit Messages
Branches, Stashes, And Sync -> Branching, Stashing, And Syncing
AI Review Before The Commit -> AI Review And Manual Diff Comments
Starting From A GitHub Issue -> GitHub Issue Context
Addressing Pull Request Feedback -> Pull Request Feedback Context
Where Git Integration Fits In The Series -> Git Integration In The Deep Dive Series
```

More examples:

```text
Why Permissions Matter -> Permission Checks And Access Control
What The Module Does -> Module Responsibilities
How It Works In Practice -> Runtime Flow
The Power Of Automation -> Automated Workflow Steps
Making Deployment Easier -> Deployment Configuration
```

## Quality Check

Before finishing, scan the headings as a table of contents. A reader should be able to predict the article's structure without reading the body text.
