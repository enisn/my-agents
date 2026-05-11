---
name: handle-abp-support-ticket
description: "Handle an ABP support ticket end-to-end: read the support question, inspect screenshots, verify behavior from ABP source and docs, and produce a support-team answer in markdown."
---

# Handle ABP Support Ticket

Handle an ABP support ticket from link to support-ready answer. Read the full ticket, inspect screenshots, verify behavior from real ABP source and documentation, then produce a public-facing markdown answer written as ABP Support Team.

Use this skill for support analysis first. Only move into docs changes or code changes when the user asks for them or when they are a natural follow-up to the investigation.

## When to Use This Skill

- User gives an `abp.io/support/questions/...` link
- User asks you to investigate or answer an ABP support request
- User wants a support-team style response
- User asks you to inspect screenshots attached to a support ticket
- User wants a markdown deliverable for the response
- User wants source-backed support guidance for ABP Framework, ABP modules, ABP Studio, or related products

## Core Outcomes

Choose the appropriate outcome for the request:

- `answer-only` - provide a verified support answer in markdown
- `answer-plus-docs` - provide the answer and update documentation if the docs are missing or misleading
- `answer-plus-code-investigation` - provide the answer and continue into bug analysis or implementation if the user explicitly wants a fix

Default to `answer-only` unless the user asks for documentation or code changes.

## Hard Rules

1. Always read the full support question before answering.
2. Always inspect attached screenshots when they exist. Extract the actual visible configuration values, errors, toggles, model names, and URLs.
3. When the ticket touches ABP internals, module behavior, framework conventions, or unclear implementation details, load and use the `abp-source-reference` skill instead of assuming repository locations from memory.
4. Verify from real source and docs; do not guess internal behavior.
5. Distinguish clearly between:
   - verified facts from source/docs
   - likely inferences
   - external provider behavior from third-party docs
6. Write the public answer as **ABP Support Team**.
7. Always generate a markdown file for the public answer unless the user explicitly asks not to.
8. Do not expose private repository code snippets or internal-only implementation details in the public answer.
9. It is fine to mention package names, class names, module names, config fields, and public doc concepts when useful.
10. Keep ticket-specific one-off artifacts out of this reusable workflow unless the user explicitly asks for them.
11. If external behavior matters, verify with vendor documentation rather than assuming ABP is at fault.
12. If you are going to present code or configuration as copy-paste-safe, validate it first with `abp-support-lab` or `/abp-support-validate` when available. Otherwise label it clearly as guidance-only.

## Recommended Workflow

### Step 0: Reuse local ticket memory

Before fetching the ticket, check whether a local ticket folder already exists:

- `C:\Users\enisn\support-answers\<ticket-id>\`

If the folder exists:

- read the latest `support-answer-<ticket-id>-NN.md` draft if present
- read the latest `support-notes-<ticket-id>-NN.md` notes if present
- use them as prior context, open questions, and continuity from earlier sessions
- do not treat local notes as the source of truth over the actual support ticket, screenshots, source, or docs

In a fresh session, do not start from scratch if previous local artifacts already exist for the same ticket.
Always reuse them first, then re-fetch the support ticket and re-verify the current facts.

### Step 1: Read the support ticket

Fetch the support page in a readable form.

- Use markdown fetch for readable content
- Use HTML fetch when needed to discover attachment URLs or missing details

Look for:

- the exact problem statement
- expected vs actual behavior
- product/module name
- configuration details
- logs or pasted errors
- screenshots and attachments
- whether the user wants guidance, docs clarification, or a product fix

### Step 2: Inspect screenshots and attachments

If screenshots or image attachments are present:

- inspect each image one by one
- transcribe visible values and messages
- note selected provider/model names, endpoint URLs, toggles, workspace names, and visible errors
- use those observed values in the diagnosis instead of generic assumptions

Treat screenshots as evidence, not decoration.

### Step 3: Classify the support task

Choose one primary path:

- `answer-only`
- `answer-plus-docs`
- `answer-plus-code-investigation`

Use this shortcut:

```text
Need only explanation, configuration help, or troubleshooting guidance?
- Yes -> answer-only

Is the user also asking to improve or correct documentation?
- Yes -> answer-plus-docs

Is the user explicitly asking for a product fix, root-cause investigation in code, or implementation work?
- Yes -> answer-plus-code-investigation
```

### Step 4: Verify with source and docs

When ABP internals are relevant:

1. Load `abp-source-reference`
2. Locate the real implementation
3. Read the actual source paths involved
4. Cross-check any existing docs
5. If the issue depends on a third-party provider like Ollama, OpenAI, PostgreSQL, Docker, etc., verify that behavior from the vendor docs too

Prefer evidence like:

- source paths you inspected
- relevant docs pages
- workspace configuration expectations
- actual fallback or error-handling behavior

### Step 5: Build the diagnosis

Before drafting the answer, identify:

- the most likely root cause
- at least one plausible alternative explanation
- why the chosen diagnosis is stronger than the alternatives
- the fastest confirmation steps for the asker

Good support analysis usually includes:

- what looks correctly configured
- what looks suspicious
- what to try first
- what information to request if it still fails

### Step 5.5: Validate compile-sensitive guidance when needed

Use this step when:

- the public answer includes concrete code or configuration changes
- the user asks whether the example is exact or compile-ready
- the issue is sensitive to template version, solution shape, or runtime behavior

Recommended path:

- spawn `abp-support-lab`, or use `/abp-support-validate`
- pass the exact ABP version and relevant solution parameters from the ticket
- ask it to create a fresh project, apply the proposed changes, and validate with build/tests/browser as needed

In the public answer:

- only describe code as exact if the lab validated it
- otherwise describe it as guidance, sample shape, or a likely starting point

### Step 6: Draft the public answer

Write the public answer as a support-team response.

Recommended shape:

```text
Hi,

Thanks for the details.

- Briefly restate the observed setup from the ticket/screenshots
- State the most likely cause
- Explain why
- Give the smallest practical steps to verify or resolve it
- Ask for 2-4 concrete follow-up details only if the issue persists

Best regards,

ABP Support Team
```

Preferred tone:

- calm
- direct
- evidence-based
- helpful
- not overly defensive

Avoid:

- narrating your private investigation process
- dumping large code excerpts
- exposing non-public implementation details
- offering to create or manage internal issues, escalations, or other internal follow-up processes on the asker's behalf, or asking them for permission/confirmation to do so
- sounding uncertain when the source is clear

If an internal issue has already been created and it is useful context, you may mention only the issue number in the public answer (for example `Internal issue created: #12345`). Do not ask the asker for confirmation and do not discuss internal workflow.

### Step 7: Save the answer as markdown

Create a markdown file for the public response.

Default storage location:

- `C:\Users\enisn\support-answers\<ticket-id>\`

Recommended naming:

- public replies: `support-answer-<ticket-id>-NN.md`
- internal notes: `support-notes-<ticket-id>-NN.md`

Storage rules:

- keep one folder per ticket number
- on follow-up or fresh-session reruns for the same ticket, check the existing folder first and continue from the latest notes/draft when applicable
- keep earlier drafts instead of overwriting
- increment `NN` for each new public reply draft

If you also prepare supporting notes for internal use, keep them separate from the public answer.

## Docs Follow-Up Path

Use this only when the user asks for documentation changes or the docs gap is part of the task.

Checklist:

- confirm what the current docs say
- identify the missing or misleading part
- patch the docs with the minimum useful clarification
- keep examples general and reusable
- avoid baking ticket-specific troubleshooting into general docs unless it is broadly applicable

Typical good doc additions:

- required prerequisites
- exact model/config requirements
- common setup pitfalls
- verification commands
- provider-specific caveats

## Code Investigation Path

Use this when the user wants an actual fix or asks for deeper code-level confirmation.

Checklist:

- verify the relevant source paths with `abp-source-reference`
- inspect the current behavior end-to-end
- identify whether the issue is:
  - configuration error
  - documentation gap
  - third-party dependency limitation
  - ABP bug or missing feature
- only propose code changes after the root cause is clear

If a real bug is confirmed and the user wants implementation work, continue with the normal coding workflow outside this skill.

## Evidence Checklist

Before finalizing the answer, make sure you have considered:

- the exact support question text
- screenshot evidence
- current ABP docs
- real ABP source behavior when relevant
- third-party docs when provider behavior matters
- fresh-project validation results when you used `abp-support-lab` or `/abp-support-validate`
- whether the recommended steps are minimal and testable

## Output Expectations

When finishing, report back to the local user with:

- the support-task classification
- the likely diagnosis
- what evidence you used
- whether any code/config examples were validated or remain guidance-only
- the markdown file path you created
- the validation report path, if you used the lab
- any docs/code files changed, if applicable
- any internal follow-up you recommend or created; if you also mention it in the public support answer, keep it to a terse status with the issue number only
- any unresolved question that still needs asker feedback

## Quick Reminder

Use support-ticket evidence first, source-of-truth verification second, and public support writing last. If ABP internals are involved, use `abp-source-reference` rather than relying on remembered repository paths.
