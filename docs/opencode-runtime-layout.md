# OpenCode Runtime Layout

This repository can safely contain both OpenCode runtime files and human-facing documentation, as long as they are separated clearly.

Docs index:

- [Workflow Documentation Index](./README.md)

Related docs:

- [handle-github-issue Dependency Map](./handle-github-issue-dependency-map.md)
- [handle-abp-github-issue Dependency Map](./handle-abp-github-issue-dependency-map.md)
- [handle-abp-support-ticket Dependency Map](./handle-abp-support-ticket-dependency-map.md)

## Recommended Rule

Only put runtime assets that OpenCode should load under `opencode/`.

Put repository documentation under `docs/`.

## Recommended Repository Structure

```text
my-agents/
├── opencode/
│   ├── AGENTS.md
│   ├── agent/
│   │   ├── orchestrator.md
│   │   ├── hyper-planner.md
│   │   ├── worker-code.md
│   │   ├── worker-research.md
│   │   ├── worker-validate.md
│   │   ├── worker-fix.md
│   │   ├── worker-browser-test.md
│   │   └── abp-support-lab.md
│   └── skills/
│       ├── handle-abp-github-issue/
│       │   └── SKILL.md
│       └── ...
├── docs/
│   ├── opencode-runtime-layout.md
│   └── handle-abp-github-issue-dependency-map.md
├── README.md
└── QUICK_START.md
```

## What OpenCode Should Consume

- `opencode/AGENTS.md`
- `opencode/agent/*.md`
- `opencode/skills/**/SKILL.md`

These are the files that should be copied or symlinked into `~/.config/opencode/` or a project-local `.opencode/` directory.

## What Should Stay Outside Runtime

Keep these outside `opencode/` if you want them documented but not treated as runtime content:

- architecture notes
- dependency maps
- Mermaid diagrams
- screenshots
- maintenance guides
- release notes
- contributor-facing design docs

## Install / Exposure Model

Source repository:

```text
C:\P\my-agents\opencode\...
```

OpenCode runtime target:

```text
~/.config/opencode/...
```

That means this repository can be organized as a source-of-truth repo, while only the `opencode/` subtree is exposed to the actual OpenCode runtime.

## Practical Recommendation

Use this split:

1. Root `README.md`: short overview, installation, and links.
2. `docs/`: detailed diagrams and dependency maps.
3. `opencode/`: only runtime assets that OpenCode should load.

## For This Repository

This repo already follows the right runtime boundary:

- runtime content is under `opencode/`
- top-level docs like `README.md` and `QUICK_START.md` are safe

Adding more docs under `docs/` is the cleanest way to document the system without mixing documentation into runtime assets.
