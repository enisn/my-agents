---
name: handle-github-issue
description: "Handle a GitHub issue end-to-end: analyze it, decide whether it needs an answer, a bug fix, or a feature implementation, then reply on the issue or create a PR that closes it. Always plan feature work first; bug fixes may be implemented directly."
---

# Handle GitHub Issue

Handle a GitHub issue from link to resolution. Start by understanding the issue, classify the required response, then choose one of three paths:

- answer the issue directly
- fix a bug and open a PR that closes the issue
- plan a feature first, ask option questions, then implement and open a PR that closes the issue

## When to Use This Skill

- User gives a GitHub issue URL and asks you to handle it
- User wants an issue triaged, answered, fixed, or implemented
- User wants a PR created from an issue
- User wants a bug fixed directly from issue context
- User wants a feature request planned before development

## Hard Rules

1. Always analyze the issue before acting.
2. Always use `gh` first for GitHub data, issue comments, and PR creation.
3. Always classify the issue as `answer-only`, `bug-fix`, or `feature` before coding.
4. For `bug-fix`, you may proceed directly to reproduction, root cause analysis, fix, validation, and PR creation.
5. For `feature`, never jump straight into coding. Use plan mode first, present options and tradeoffs, ask focused questions, and only implement after the feature direction is clear.
6. If the issue only needs an explanation or guidance, answer on the issue directly with `gh issue comment` and do not open a PR.
7. If you create a PR for the issue, include a closing keyword such as `Closes #123` in the PR body.
8. Prefer the smallest safe change that resolves the issue.

## Classification Rules

Classify the issue before choosing a path.

### `answer-only`

Use this when the issue is primarily:

- a question
- usage help
- clarification request
- documentation explanation
- not actionable as a code change

Default action:

- gather enough repo and issue context to answer correctly
- post a concise issue comment
- stop after answering unless the user explicitly asks for docs/code changes too

### `bug-fix`

Use this when the issue describes:

- incorrect existing behavior
- regression
- crash or exception
- broken UX/API behavior that should already work

Default action:

- reproduce or reason from evidence
- find root cause
- implement the minimal fix directly
- add or update tests when possible
- create a PR that closes the issue

### `feature`

Use this when the issue asks for:

- new behavior
- enhancement or UX change
- new API surface
- new config/setting/option
- anything that needs product or implementation choices

Default action:

- enter plan mode first
- identify options, assumptions, acceptance criteria, and risks
- ask focused option questions
- only after planning is settled, implement and create a PR that closes the issue

## Recommended Workflow

### Step 1: Read the issue with GitHub CLI

Start with GitHub-native context.

```bash
gh issue view <issue-url> --comments
```

Also gather repo context when needed:

```bash
gh repo view <owner>/<repo>
gh api repos/<owner>/<repo>/issues/<number>
gh api repos/<owner>/<repo>/issues/<number>/comments
```

Look for:

- exact problem statement
- expected vs actual behavior
- reproduction steps
- linked PRs or duplicate issues
- maintainer guidance
- missing decisions or unanswered questions

### Step 2: Resolve repository context

Work in the correct codebase.

1. If the current workspace is already the target repository, use it.
2. If not, look for an obvious local checkout.
3. If no local checkout is available, clone with `gh repo clone <owner>/<repo>` into a safe working location and continue there.

Do not assume the current directory matches the issue repository.

### Step 3: Classify the issue

Choose exactly one primary path:

- `answer-only`
- `bug-fix`
- `feature`

If the issue mixes bug and feature language, classify by the required outcome:

- existing behavior is wrong -> `bug-fix`
- new behavior or product choice is needed -> `feature`

When in doubt, prefer `feature` if implementation requires product decisions.

## Path A: Answer the Issue Directly

Use this when no code change is needed.

Checklist:

- verify the answer from repo or product context
- keep the answer concrete and actionable
- mention relevant file, command, config, or docs if useful
- avoid guessing
- write as a project maintainer replying in the public issue thread
- answer the original reporter directly, not the local user who invoked the skill
- avoid meta narration about your investigation process unless it is genuinely useful to the thread

Comment with:

```bash
gh issue comment <issue-url> --body "<final answer>"
```

Good answer shape:

```text
Thanks for reporting this.

This behavior is expected because <y>.
If you want <z>, use <command/config/path>.

If that would be useful, we can keep this open as a docs or enhancement follow-up.
```

Preferred tone:

- sound like a normal maintainer in the issue thread
- be direct, calm, and helpful
- state the conclusion first
- explain only the amount needed for the reporter

Avoid phrasing like:

- `I checked the current implementation and...`
- `I investigated this and found...`
- `For you, the answer is...`
- anything that reads like a private progress report to the local operator

Prefer phrasing like:

- `This is expected behavior because...`
- `This is a bug and will be fixed in #123.`
- `This is not supported yet, but #123 adds it.`
- `Use <x> here instead of <y>.`

## Path B: Bug Fix

Bug fixes do not require plan mode by default.

Workflow:

1. Reproduce the issue or confirm the failure mode from tests/logs/code.
2. Find the root cause before editing.
3. Implement the narrowest correct fix.
4. Add or update tests when reasonable.
5. Run relevant validation.
6. Commit, push, and create a PR that closes the issue.

Validation should include the most relevant project checks available, for example:

- targeted tests
- lint for touched files or project
- build if the fix affects build-time behavior

PR body should include the closing line:

```text
Closes #<issue-number>
```

Recommended PR body shape:

```text
## Summary
- fix the root cause of <problem>
- add coverage for <scenario>

## Testing
- <command 1>
- <command 2>

Closes #<issue-number>
```

If a short issue update is useful after PR creation, comment with the PR link and a one-line status update.

## Path C: Feature Request

Feature work must use plan mode first.

### Feature Rule

Do not implement a feature directly from the issue description unless the planning step is already complete and the open questions are fully resolved.

### Planning Goals

Before coding, produce a concise plan that covers:

- problem statement
- scope and non-goals
- affected areas
- risks and migrations
- validation strategy
- open questions
- implementation options with a recommended default

### Use Plan Mode

Prefer an existing planning workflow when the repo supports it.

- If the repository already uses GSD planning, prefer `/gsd-quick` for a small standalone feature request or `/gsd-plan-phase` when the issue clearly maps to a roadmap phase.
- If no repo planning workflow exists, perform an equivalent plan-mode step in chat before coding.

### Ask Option Questions

For feature issues, ask focused questions when the issue leaves real choices open.

Examples:

- scope choice: minimal version vs full version
- UX choice: inline vs modal vs separate page
- compatibility choice: preserve old behavior vs introduce a breaking change
- rollout choice: enabled by default vs behind a flag

Question style:

- give 2-4 concrete options
- recommend one option first
- explain what changes depending on the choice
- avoid open-ended brainstorming when a small decision list is enough

### After Planning Is Settled

Once the feature direction is clear:

1. implement the planned change
2. add or update tests
3. run validation
4. create a PR that closes the issue

## Issue Commenting Guidance

Comment publicly only when it helps move the issue forward.

All GitHub comments produced by this skill are public maintainer comments in the issue conversation, not status reports to the local user.

Good reasons to comment:

- final answer for `answer-only`
- PR is ready and you want to point maintainers to it
- the issue is blocked on missing product information and a public clarification is useful

Avoid noisy comments like "looking into this" unless the user explicitly wants that.

When commenting:

- reply to the reporter's problem directly
- write as if you are part of the project team
- do not mention that an agent, tool, or local operator asked you to do this
- do not narrate internal steps unless they help explain the decision
- if linking a PR, phrase it as issue progress, for example: `Fixed in #123.` or `Opened #123 to address this.`

## Decision Shortcut

Use this quick decision tree:

```text
Need only an explanation or guidance?
- Yes -> answer on the issue directly.
- No -> continue.

Is existing behavior wrong?
- Yes -> bug-fix path, implement directly.
- No -> continue.

Does this add or change behavior in a way that requires choices?
- Yes -> feature path, use plan mode first.
```

## Output Expectations

When finishing the task, report back with:

- issue classification
- what you found
- whether you answered the issue or changed code
- tests/validation run
- PR URL if created
- any remaining open question

## Behavior Reminders

- Be decisive after reading the issue.
- Do not ask broad questions you can answer from the repo or issue history.
- For bugs, optimize for fast, validated resolution.
- For features, optimize for clarity before coding.
- Use GitHub-native actions with `gh` whenever possible.
