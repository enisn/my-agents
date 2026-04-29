# handle-abp-github-issue Dependency Map

This document shows which skills, subagents, and related runtime assets are involved in the `handle-abp-github-issue` flow in this repository.

Primary skill file:

- [`opencode/skills/handle-abp-github-issue/SKILL.md`](../opencode/skills/handle-abp-github-issue/SKILL.md)

Docs index:

- [Workflow Documentation Index](./README.md)

## Related Workflow Docs

- [handle-github-issue Dependency Map](./handle-github-issue-dependency-map.md) - the generic issue-handling flow that this skill specializes for ABP repos
- [handle-abp-support-ticket Dependency Map](./handle-abp-support-ticket-dependency-map.md) - adjacent ABP support workflow that can feed into issue work
- [abp-source-reference Dependency Map](./abp-source-reference-dependency-map.md) - source-root lookup workflow used for ABP internals verification
- [abpdev-references Dependency Map](./abpdev-references-dependency-map.md) - local reference switching workflow used during fresh-project validation

## Mermaid Diagram

```mermaid
flowchart TD
    A[Start: user provides ABP GitHub issue] --> B[Read full issue with gh\ncomments, labels, milestone, screenshots]
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
    J5 --> J5A{Visual or browser issue?}
    J5A -->|Yes| J5B{Playwright MCP tools available?}
    J5B -->|No| J5C[Ask user to enable Playwright MCP tools.\nDo not scaffold a standalone Playwright project]
    J5C --> J5B
    J5B -->|Yes| J5D[Verify actual on-screen behavior.\nCompare visible UI state and native DOM value]
    J5A -->|No| J6{Fresh project validation needed?}
    J5D --> J6
    J6 -->|Yes| J7[Use abp-support-lab or a fresh local app,\nrun abpdev references to-local,\nthen build/run and validate against local refs]
    J6 -->|No| J8[Proceed]
    J7 --> J9[Commit, push, create PR targeting resolved base\ninclude Closes number]
    J8 --> J9
    J9 --> J9A[Request review from issue opener.\nAdd PR labels]
    J9A --> J10[Optional issue comment with PR link or status]
    J10 --> Z

    K --> K1[Ask focused option questions if needed]
    K1 --> K2[Direction settled]
    K2 --> K3[Create branch from resolved base]
    K3 --> K4[Implement planned feature]
    K4 --> K5[Add or update tests]
    K5 --> K6[Run validation]
    K6 --> K7[Create PR targeting resolved base\ninclude Closes number]
    K7 --> K7A[Request review from issue opener.\nAdd PR labels]
    K7A --> K8[Optional issue comment with PR link or status]
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
  +-- uses Playwright MCP/browser tools (for visual issues)
  |     - runtime capability, not a repo-local file
  |     - purpose: verify actual on-screen state, not only underlying DOM values
  |     - compare visible wrapper/UI text with native select or DOM state when needed
  |     - if unavailable, ask the user to enable Playwright MCP tools
  |     - do not replace this with a scratch standalone Playwright/npm project
  |
  +-- uses `abpdev references to-local` command
  |     - used when fresh generated projects must point to local ABP source
  |     - critical for reproducing and validating browser-visible fixes against local source changes
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
| Skill | [abp-source-reference](./abp-source-reference-dependency-map.md) | `opencode/skills/abp-source-reference/SKILL.md` | Direct referenced skill for ABP internals and source verification |
| Subagent | `abp-support-lab` | `opencode/agent/abp-support-lab.md` | Direct referenced validation subagent for fresh-project verification |
| Subagent | `worker-browser-test` | `opencode/agent/worker-browser-test.md` | Transitive dependency used by `abp-support-lab` for browser validation |
| Runtime capability | Playwright MCP/browser tools | not in repo | Direct validation path for visual issues; verifies visible on-screen state and should be user-enabled when unavailable |
| Skill | [abpdev-references](./abpdev-references-dependency-map.md) | `opencode/skills/abpdev-references/SKILL.md` | Related documentation for the `abpdev references to-local` CLI used in the flow |
| Related workflow doc | [handle-github-issue](./handle-github-issue-dependency-map.md) | `docs/handle-github-issue-dependency-map.md` | Generic upstream issue-handling workflow |
| Related workflow doc | [handle-abp-support-ticket](./handle-abp-support-ticket-dependency-map.md) | `docs/handle-abp-support-ticket-dependency-map.md` | Adjacent ABP support workflow that may surface bugs or feature requests |
| External workflow | `/gsd-quick` | not in repo | Optional feature-planning workflow mentioned by the skill |
| External workflow | `/gsd-plan-phase` | not in repo | Optional feature-planning workflow mentioned by the skill |
| External command | `/abp-support-validate` | not in repo | Alternative validation route mentioned by the skill |

## What Is Direct vs Indirect

Direct runtime references from `handle-abp-github-issue`:

1. [abp-source-reference](./abp-source-reference-dependency-map.md)
2. `abp-support-lab`
3. `abpdev references to-local` command
4. Playwright MCP/browser tools for visual validation

Indirect runtime reference:

1. `worker-browser-test` through `abp-support-lab`

Related workflow docs:

1. [handle-github-issue](./handle-github-issue-dependency-map.md)
2. [handle-abp-support-ticket](./handle-abp-support-ticket-dependency-map.md)
3. [abp-source-reference](./abp-source-reference-dependency-map.md)
4. [abpdev-references](./abpdev-references-dependency-map.md)

Mentioned but not stored in this repository:

1. `/abp-support-validate`
2. `/gsd-quick`
3. `/gsd-plan-phase`

Explicitly avoided fallback for visual issues:

1. Installing standalone Playwright in a scratch npm project instead of asking the user to enable Playwright MCP tools

## Guidance For Repo Organization

This kind of diagram belongs in `docs/`, not under `opencode/`.

Reason:

1. `opencode/` should stay limited to runtime assets.
2. `docs/` can hold diagrams, explanation, dependency maps, and contributor notes.
3. That keeps the runtime clean while still making the repository understandable to humans.
