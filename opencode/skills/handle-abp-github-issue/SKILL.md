---
name: handle-abp-github-issue
description: "Handle an ABP GitHub issue end-to-end: analyze the issue, verify behavior from real ABP source and docs, validate with ABP lab projects when needed, and comment or create a PR from the correct milestone branch."
---

# Handle ABP GitHub Issue

Handle an ABP GitHub issue from link to resolution. Use the normal GitHub issue workflow for classification, comments, fixes, and PR creation, but verify ABP behavior from real source and docs before answering or coding.

This is a maintenance and development skill first, not a support-ticket workaround skill. For actionable ABP product issues, inspect the source, validate the reported behavior, and if repository code needs to change, make the change and open a PR. Only stop at a public issue comment when source-backed investigation shows that no repository code change is needed.

This skill is for ABP repositories and ABP-related issues that may require:

- maintainer-style issue replies
- bug fixes with PRs
- feature planning before implementation
- ABP source-backed investigation
- fresh-project validation with local source references
- branch and PR targeting based on the issue milestone

## When to Use This Skill

- User gives a GitHub issue URL for `abpframework`, `abp`, `abp-studio`, `volo`, `lepton`, or another ABP-managed repository
- User wants an ABP GitHub issue triaged, answered, fixed, or implemented
- User wants a PR created from an ABP issue
- The issue touches ABP internals, module behavior, framework conventions, templates, Studio behavior, or commercial modules
- The issue needs branch selection from milestone such as `10.2 -> rel-10.2`
- The issue needs fresh-project validation before claiming the change is exact

## Core Outcomes

Choose one primary outcome:

- `answer-only` - provide a verified issue reply only when no repository code change is needed
- `bug-fix` - implement the minimal fix and open a PR that closes the issue
- `feature` - plan first, then implement and open a PR that closes the issue

Default behavior:

- questions, clarification, or usage guidance with no required code change -> `answer-only`
- existing behavior is wrong -> `bug-fix`
- new behavior or product choices are needed -> `feature`

## Primary Maintenance Rule

Treat this skill as code-first for actionable ABP GitHub issues.

- Always inspect the relevant source before deciding that a comment-only answer is enough.
- Do not stop at a workaround comment for a confirmed bug or missing implementation that should be fixed in the repository.
- If source verification shows the behavior is intended, unsupported, external to the repo, or purely configuration usage, answer on the issue directly.
- If source verification shows repository code should change, fix it and create a PR against the correct base branch.

## Hard Rules

1. Always use `gh` first for issue data, issue comments, PR creation, branch info, and milestone inspection.
2. Always read the full issue, existing comments, labels, and milestone before acting.
3. Always resolve the target base branch from the issue milestone before coding.
4. Always inspect the relevant source before deciding the issue is `answer-only` or before suggesting any workaround.
5. Always use `abp-source-reference` when the issue touches ABP internals, module behavior, templates, Studio behavior, or unclear implementation details.
6. Verify from real source and docs; do not guess internal behavior from memory.
7. If screenshots or image attachments are present in the issue, inspect them and use the visible values, errors, URLs, toggles, versions, and provider names as evidence.
8. For `bug-fix`, you may proceed directly to reproduction, root cause analysis, fix, validation, and PR creation.
9. For `feature`, never jump straight into coding. Use plan mode first, present focused options, and only implement once the direction is clear.
10. Do not post a workaround comment instead of fixing the issue when source validation shows repository code changes are needed.
11. Only comment without code changes when source-backed investigation shows the behavior is intended, unsupported, external to the repository, or otherwise does not require repository changes.
12. If the issue has no milestone, skip it in batch mode. In single-issue mode, ask exactly one targeted question for the target branch or version.
13. If you present code or configuration as exact or copy-paste-safe, validate it with `abp-support-lab` or `/abp-support-validate` when practical.
14. When validating a fresh generated project against local ABP source, use `abpdev references to-local <workingdirectory>` so the lab project switches from package references to local csproj references.
15. PRs must target the resolved base branch and include a closing keyword such as `Closes #123`.
16. Prefer the smallest safe change that resolves the issue.

## Branch Resolution From Milestone

Resolve the base branch before editing code or creating a PR.

### Step 1: Read the issue milestone

Start with GitHub-native data:

```bash
gh issue view <issue-url> --comments --json number,title,body,labels,milestone,assignees,url
```

If needed, also inspect repository milestones:

```bash
gh api repos/<owner>/<repo>/milestones?state=all
```

### Step 2: Apply milestone rules

Use these rules in order:

1. If milestone title is a stable release like `10.2`, create the work branch from `rel-10.2` and target `rel-10.2` in the PR.
2. If milestone title is more specific but still maps to a stable release line such as `10.2.1`, normalize it to `rel-10.2`.
3. If milestone represents the latest development line, preview line, or pre-release line such as `11.0-preview`, use `dev` as the branch to branch from and as the PR base.
4. If milestone is missing:
   - batch issue handling -> skip the issue
   - single issue handling -> ask one targeted question
5. If milestone exists but is ambiguous, inspect the repository milestone list and determine whether it maps to a stable release line or the latest development line.
6. If it still cannot be resolved safely, ask one targeted question in single-issue mode or skip in batch mode.

### Normalization Examples

- `10.2` -> `rel-10.2`
- `10.2.1` -> `rel-10.2`
- `11.0-preview` -> `dev`
- latest unreleased development milestone -> `dev`

## Recommended Workflow

### Step 1: Read the issue with GitHub CLI

Start with:

```bash
gh issue view <issue-url> --comments
```

Also gather structured context when useful:

```bash
gh api repos/<owner>/<repo>/issues/<number>
gh api repos/<owner>/<repo>/issues/<number>/comments
gh repo view <owner>/<repo>
```

Look for:

- exact problem statement
- expected vs actual behavior
- reproduction steps
- milestone and labels
- maintainer guidance
- linked PRs or duplicates
- screenshots and attachments
- whether the issue wants explanation, a fix, or a new feature

Do not treat a possible workaround as the final outcome yet. First determine from source and tests whether the repository itself should change.

### Step 2: Resolve repository context

Work in the correct repository.

1. If the current workspace is already the target repository, use it.
2. If the issue belongs to ABP repositories, use `abp-source-reference` to locate the correct local source root when possible.
3. If no local checkout is available, clone with `gh repo clone <owner>/<repo>` into a safe working location.
4. Fetch the resolved base branch, check it out, update it, and create the work branch from there.

Do not assume the current directory or current git branch is correct.

### Step 3: Inspect screenshots and attachments

If the issue contains image attachments or screenshot links:

- inspect each image one by one
- transcribe visible errors, versions, settings, toggles, URLs, workspace names, provider names, and model names
- use those observed values in the diagnosis instead of generic assumptions

Treat screenshots as evidence.

### Step 4: Verify with source and docs

When ABP internals are relevant:

1. Load `abp-source-reference`
2. Locate the exact implementation in `C:\P\abp`, `C:\P\abp-studio`, `C:\P\volo`, or `C:\P\lepton`
3. Read the real source paths involved
4. Cross-check with current docs
5. If the issue depends on third-party behavior, verify that with vendor docs too

Prefer evidence like:

- source paths inspected
- tests or examples inspected
- docs pages inspected
- actual fallback and error-handling behavior
- milestone and branch data from GitHub

### Step 5: Classify the issue

Choose exactly one primary path:

- `answer-only`
- `bug-fix`
- `feature`

Shortcut:

```text
Need only explanation or guidance?
- Yes -> answer-only

Is existing behavior wrong?
- Yes -> bug-fix

Does this add or change behavior in a way that requires choices?
- Yes -> feature
```

Classification rule:

- If the issue reports wrong product behavior, inspect source and available tests before considering `answer-only`.
- The existence of a temporary workaround does not change a real bug into `answer-only`.
- Use `answer-only` only when the investigated result is truly no-code-change.

## Path A: Answer the Issue Directly

Use this only when source-backed investigation shows no repository code change is needed.

Checklist:

- confirm the behavior is intended, unsupported, external to the repository, or purely usage/configuration guidance
- verify the answer from source, docs, issue context, and screenshots when relevant
- keep the answer concrete and actionable
- mention relevant file, command, config, doc, or branch if useful
- write as a normal project maintainer in the public issue thread
- avoid private progress narration

Do not use this path just because you can suggest a workaround.

Comment with:

```bash
gh issue comment <issue-url> --body "<final answer>"
```

Preferred phrasing:

- `This is expected behavior because...`
- `This is a bug and will be fixed in #123.`
- `Use <x> here instead of <y>.`
- `This is not supported yet, but #123 adds it.`

## Path B: Bug Fix

Bug fixes do not require plan mode by default.

If source-backed investigation shows the repository should change, do not stop at workaround guidance. Fix the issue and create the PR. If a temporary workaround is useful for the reporter, mention it only as secondary guidance, ideally alongside the PR.

Workflow:

1. Reproduce the issue or confirm the failure mode from tests, logs, screenshots, or code.
2. Find the root cause before editing.
3. Resolve the correct base branch from the milestone.
4. Create the work branch from that base branch.
5. Implement the narrowest correct fix.
6. Add or update tests when reasonable.
7. Run relevant validation.
8. Commit, push, and create a PR that closes the issue.

Validation can include:

- targeted tests
- lint for touched files or project
- build for affected projects
- fresh-project validation through `abp-support-lab` or `/abp-support-validate`

Use fresh-project validation when the issue depends on:

- template output
- startup configuration
- package versus project references
- version-specific behavior
- runtime or browser behavior that is safer to validate in isolation

### Local-Source Validation Rule

If the validation must exercise your local ABP source changes inside a fresh generated project:

1. Generate the fresh lab project for the exact ABP version and scenario.
2. Run:

```bash
abpdev references to-local <workingdirectory>
```

3. Then run build, tests, or browser validation against that converted project.

This ensures the lab project references local csproj files instead of NuGet packages.

## Path C: Feature Request

Feature work must use plan mode first.

### Feature Rule

Do not implement a feature directly from the issue description unless the planning step is already complete and the open questions are fully resolved.

### Planning Goals

Before coding, produce a concise plan that covers:

- problem statement
- scope and non-goals
- affected areas
- milestone branch impact
- risks and migrations
- validation strategy
- open questions
- implementation options with a recommended default

### Use Plan Mode

Prefer an existing planning workflow when the repo supports it.

- If the repository already uses GSD planning, prefer `/gsd-quick` for a small standalone feature request or `/gsd-plan-phase` when the issue maps to a larger roadmap phase.
- If no repo planning workflow exists, perform an equivalent plan-mode step in chat before coding.

### Ask Option Questions

For feature issues, ask focused questions when the issue leaves real choices open.

Examples:

- minimal version vs full version
- preserve old behavior vs introduce a change
- enabled by default vs behind a flag
- API-only vs UI plus API

Question style:

- give 2-4 concrete options
- recommend one option first
- explain what changes depending on the choice
- avoid open-ended brainstorming when a small decision list is enough

### After Planning Is Settled

Once the feature direction is clear:

1. resolve the correct milestone branch
2. create the work branch from that base branch
3. implement the planned change
4. add or update tests
5. run validation
6. create a PR that closes the issue

## PR Creation Rules

When opening a PR:

- branch from the resolved base branch, not from the current branch by habit
- target the same resolved base branch in the PR
- include a concise summary and testing section
- include `Closes #<issue-number>` in the PR body

After creating the PR:

- assign the PR to the issue opener when that user is assignable and there is no repo-specific reason to use a different assignee
- add the relevant module and UI labels to the PR based on the issue and the touched area, following existing PR labeling conventions in that repository
- do not blindly copy issue-only workflow labels like effort or priority onto the PR unless the repository already uses them on PRs
- prefer `gh pr edit` for assignees and labels, but if it fails due to CLI or GraphQL issues, update the PR through the issue REST endpoint with `gh api repos/<owner>/<repo>/issues/<pr-number> -X PATCH ...`

Recommended PR body shape:

```text
## Summary
- fix or implement the issue in the correct ABP branch
- add or update validation for the affected scenario

## Testing
- <command 1>
- <command 2>

Closes #<issue-number>
```

If a short issue update is useful after PR creation, comment with the PR link and a one-line status update.

## Public Commenting Guidance

All GitHub comments produced by this skill are public maintainer comments in the issue conversation.

When commenting:

- reply to the reporter's problem directly
- write as if you are part of the project team
- do not mention that an agent or tool asked you to do this
- do not narrate internal investigation steps unless they help explain the conclusion
- if linking a PR, phrase it as issue progress, for example `Fixed in #123.` or `Opened #123 to address this.`

Avoid noisy comments like `looking into this` unless the user explicitly wants that.

## Evidence Checklist

Before finalizing the issue response or PR, make sure you considered:

- the exact issue text
- issue comments
- milestone and branch resolution
- screenshot evidence when present
- current ABP docs
- real ABP source behavior when relevant
- third-party docs when provider behavior matters
- fresh-project validation results when you used `abp-support-lab` or `/abp-support-validate`
- whether `abpdev references to-local` was needed for local source validation

## Output Expectations

When finishing, report back with:

- issue classification
- resolved milestone and chosen base branch
- what evidence you used
- whether you answered the issue or changed code
- tests and validation run
- whether lab validation was `validated`, `partially-validated`, or `guidance-only`
- PR URL if created
- any remaining open question

## Quick Reminder

Use GitHub-native issue handling first, milestone-to-branch resolution second, ABP source-of-truth verification third, and code or public reply last. For ABP internals, use `abp-source-reference`. For exact validation on fresh projects, use `abp-support-lab` or `/abp-support-validate`, and switch the lab project to local csproj references with `abpdev references to-local` when needed.
