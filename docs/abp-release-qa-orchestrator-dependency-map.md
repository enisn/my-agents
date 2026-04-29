# abp-release-qa-orchestrator Dependency Map

This document shows which repositories, generated artifacts, GitHub actions, and validation rules are involved in the `abp-release-qa-orchestrator` flow in this repository.

Primary skill file:

- [`opencode/skills/abp-release-qa-orchestrator/SKILL.md`](../opencode/skills/abp-release-qa-orchestrator/SKILL.md)

Docs index:

- [Workflow Documentation Index](./README.md)

## Related Workflow Docs

- [abp-source-reference Dependency Map](./abp-source-reference-dependency-map.md) - documents the same ABP, VOLO, and Lepton source roots this workflow analyzes

## Mermaid Flowchart

```mermaid
flowchart TD
    A["Start: receive framework from and to versions"] --> B{"Explicit Lepton versions provided?"}
    B -->|Yes| C["Use provided Lepton branch versions"]
    B -->|No| D["Derive Lepton versions\nfrom framework offset rule"]
    C --> E["Resolve branch pairs for ABP, VOLO, and Lepton"]
    D --> E

    E --> F["Analyze ABP branch delta\nand generate QA markdown"]
    F --> G["Analyze VOLO branch delta\nand generate QA markdown"]
    G --> H["Analyze Lepton branch delta\nand generate QA markdown"]
    H --> I["Build exhaustive merge PR baseline\nand filter bot PRs"]
    I --> J["Build ui-testable set\nand feature-grouped scenarios"]
    J --> K["Verify coverage rule\nui-testable set minus scenario set equals zero"]
    K --> L["Translate issue content to Turkish"]
    L --> M["Create 3 issues in vs-internal\nassigned to gizemmutukurt"]
    M --> N["Record issue URLs and finish"]
```

## Mermaid Dependency Graph

```mermaid
flowchart LR
    A["abp-release-qa-orchestrator\nSKILL.md"]

    A --> B["ABP repo\nbranch diff source"]
    A --> C["VOLO repo\nbranch diff source"]
    A --> D["Lepton repo\nbranch diff source"]
    A --> E["QA markdown files\none per repo root"]
    A --> F["gh CLI in vs-internal\nissue creation path"]
    A --> G["Turkish issue bodies\nself-contained QA plans"]
    A --> H["Coverage equation\nui-testable set validation"]
```

## ASCII Fallback

```text
abp-release-qa-orchestrator
  |
  +-- uses source repos
  |     - C:\P\abp
  |     - C:\P\volo
  |     - C:\P\lepton
  |
  +-- derives branch ranges
  |     - framework rel-from -> rel-to
  |     - lepton explicit or offset-derived
  |
  +-- generates per-repo QA markdown
  |     - one changelog and testing scenario file per repo
  |
  +-- filters and maps PRs
  |     - remove bot PRs
  |     - build ui-testable set
  |     - verify coverage equation
  |
  +-- creates output issues
        - 3 Turkish issues in vs-internal
        - assigned to gizemmutukurt
```

## Dependency Table

| Type | Name | Repository Path | Relationship to `abp-release-qa-orchestrator` |
|---|---|---|---|
| Skill | `abp-release-qa-orchestrator` | `opencode/skills/abp-release-qa-orchestrator/SKILL.md` | Root skill |
| Source repo | ABP | `C:\P\abp` | Direct branch-diff input source |
| Source repo | VOLO | `C:\P\volo` | Direct branch-diff input source |
| Source repo | Lepton | `C:\P\lepton` | Direct branch-diff input source |
| Output artifact | QA markdown files | repo root of each source repo | Direct generated changelog and test-plan artifacts |
| Runtime capability | `gh` CLI in `vs-internal` | `C:\P\vs-internal` | Direct issue-creation path |
| Output artifact | Turkish GitHub issues | not in repo | Final QA planning output |
| Validation rule | UI coverage equation | not in repo | Direct completion rule before issue creation |
| Related workflow doc | [abp-source-reference](./abp-source-reference-dependency-map.md) | `docs/abp-source-reference-dependency-map.md` | Documents the same local source roots used by this workflow |

## What Is Direct vs Indirect

Direct runtime references from `abp-release-qa-orchestrator`:

1. `C:\P\abp`
2. `C:\P\volo`
3. `C:\P\lepton`
4. `C:\P\vs-internal`
5. Generated QA markdown files
6. Turkish issue output through `gh`

Direct validation rule:

1. `ui_testable_set - scenario_pr_set = 0`

Related workflow docs:

1. [abp-source-reference](./abp-source-reference-dependency-map.md)

## Guidance For Repo Organization

This kind of diagram belongs in `docs/`, not under `opencode/`.

Reason:

1. `opencode/` should stay limited to runtime assets.
2. `docs/` can hold diagrams, explanation, dependency maps, and contributor notes.
3. That keeps the runtime clean while still making the repository understandable to humans.
