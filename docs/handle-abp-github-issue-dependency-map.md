# handle-abp-github-issue Dependency Map

This document shows which skills, subagents, and related runtime assets are involved in the `handle-abp-github-issue` flow in this repository.

Primary skill file:

- `opencode/skills/handle-abp-github-issue/SKILL.md`

## Mermaid Diagram

```mermaid
flowchart TD
    A[handle-abp-github-issue\nopencode/skills/handle-abp-github-issue/SKILL.md]

    A --> B[abp-source-reference\nopencode/skills/abp-source-reference/SKILL.md]
    A --> C[abp-support-lab\nopencode/agent/abp-support-lab.md]
    C --> D[worker-browser-test\nopencode/agent/worker-browser-test.md]
    A --> E[abpdev references to-local\nCLI command used by the flow]
    E -. documented by .-> F[abpdev-references\nopencode/skills/abpdev-references/SKILL.md]
    A -. optional external planning path .-> G[/gsd-quick or /gsd-plan-phase\nnot stored in this repo]
    A -. alternative validation command .-> H[/abp-support-validate\nnot stored in this repo]
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
