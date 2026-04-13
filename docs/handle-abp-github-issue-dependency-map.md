# handle-abp-github-issue Dependency Map

This document shows which skills, subagents, and related runtime assets are involved in the `handle-abp-github-issue` flow in this repository.

Primary skill file:

- `opencode/skills/handle-abp-github-issue/SKILL.md`

## Mermaid Diagram

```mermaid
flowchart TD
    A[Start: user provides ABP GitHub issue] --> B[Read full issue with gh\ncomments, labels, milestone, assignees, screenshots]
    B --> C{Milestone present?}

    C -->|No, batch mode| C1[Skip issue]
    C -->|No, single issue| C2[Ask one targeted branch or version question]
    C -->|Yes| D[Resolve base branch from milestone\n10.2 to rel-10.2\n10.2.1 to rel-10.2\n11.0-preview to dev]

    D --> E[Resolve repo context\nuse current repo, abp-source-reference,\nor gh repo clone]
    E --> F[Inspect screenshots and attachments if present]
    F --> G[Verify behavior from real source and docs\nuse abp-source-reference for ABP internals]

    G --> H{Classify issue}
    H -->|answer-only| I[Write verified maintainer reply]
    H -->|bug-fix| J[Reproduce or confirm failure mode]
    H -->|feature| K[Plan mode first\nscope, risks, options, validation]

    I --> I1[Post public issue comment with gh]
    I1 --> Z[Finish with report]

    J --> J1[Find root cause]
    J1 --> J2[Create work branch from resolved base]
    J2 --> J3[Implement smallest safe fix]
    J3 --> J4[Add or update tests when reasonable]
    J4 --> J5[Run validation]
    J5 --> J6{Fresh project validation needed?}
    J6 -->|Yes| J7[Use abp-support-lab or support validation\nand run abpdev references to-local]
    J6 -->|No| J8[Proceed]
    J7 --> J9[Commit, push, create PR targeting resolved base\ninclude Closes number]
    J8 --> J9
    J9 --> J10[Optional issue comment with PR link]
    J10 --> Z

    K --> K1[Ask focused option questions if needed]
    K1 --> K2[Direction settled]
    K2 --> K3[Create branch from resolved base]
    K3 --> K4[Implement planned feature]
    K4 --> K5[Add or update tests]
    K5 --> K6[Run validation]
    K6 --> K7[Create PR targeting resolved base\ninclude Closes number]
    K7 --> K8[Optional issue comment with PR link]
    K8 --> Z
```

## ASCII Fallback

```text
handle-abp-github-issue
  |
  +-- uses abp-source-reference
  |     - skill file: opencode/skills/abp-source-reference/SKILL.md
  |     - purpose: inspect real ABP source instead of guessing
  |
  +-- uses abp-support-lab (when exact validation is needed)
  |     - agent file: opencode/agent/abp-support-lab.md
  |     - purpose: generate a fresh ABP app and validate guidance or fixes
  |     |
  |     +-- may use worker-browser-test
  |           - agent file: opencode/agent/worker-browser-test.md
  |           - purpose: browser verification for fresh-project validation
  |
  +-- uses `abpdev references to-local` command
  |     - used when fresh generated projects must point to local ABP source
  |     - related repo skill: opencode/skills/abpdev-references/SKILL.md
  |       documents the CLI, but is not explicitly loaded by name here
  |
  +-- optionally mentions external planning flows
  |     - /gsd-quick
  |     - /gsd-plan-phase
  |     - these are referenced as optional workflow choices, not repo-local files here
  |
  +-- optionally mentions external validation command
        - /abp-support-validate
        - referenced by name, but not stored in this repo
```

## Dependency Table

| Type | Name | Repository Path | Relationship to `handle-abp-github-issue` |
|---|---|---|---|
| Skill | `handle-abp-github-issue` | `opencode/skills/handle-abp-github-issue/SKILL.md` | Root skill |
| Skill | `abp-source-reference` | `opencode/skills/abp-source-reference/SKILL.md` | Direct referenced skill for ABP internals and source verification |
| Subagent | `abp-support-lab` | `opencode/agent/abp-support-lab.md` | Direct referenced validation subagent for fresh-project verification |
| Subagent | `worker-browser-test` | `opencode/agent/worker-browser-test.md` | Transitive dependency used by `abp-support-lab` for browser validation |
| Skill | `abpdev-references` | `opencode/skills/abpdev-references/SKILL.md` | Related documentation for the `abpdev references to-local` CLI used in the flow |
| External workflow | `/gsd-quick` | not in repo | Optional feature-planning workflow mentioned by the skill |
| External workflow | `/gsd-plan-phase` | not in repo | Optional feature-planning workflow mentioned by the skill |
| External command | `/abp-support-validate` | not in repo | Alternative validation route mentioned by the skill |

## What Is Direct vs Indirect

Direct runtime references from `handle-abp-github-issue`:

1. `abp-source-reference`
2. `abp-support-lab`
3. `abpdev references to-local` command

Indirect runtime reference:

1. `worker-browser-test` through `abp-support-lab`

Mentioned but not stored in this repository:

1. `/abp-support-validate`
2. `/gsd-quick`
3. `/gsd-plan-phase`

## Guidance For Repo Organization

This kind of diagram belongs in `docs/`, not under `opencode/`.

Reason:

1. `opencode/` should stay limited to runtime assets.
2. `docs/` can hold diagrams, explanation, dependency maps, and contributor notes.
3. That keeps the runtime clean while still making the repository understandable to humans.
