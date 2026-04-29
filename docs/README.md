# Workflow Documentation Index

This folder contains human-facing workflow maps for the runtime skills in `opencode/skills/` plus supporting repository documentation.

## Issue And Support Workflows

- [handle-github-issue Dependency Map](./handle-github-issue-dependency-map.md) - generic GitHub issue triage, answer, bug-fix, and feature flow
- [handle-abp-github-issue Dependency Map](./handle-abp-github-issue-dependency-map.md) - ABP-specific GitHub issue flow with milestone, branch, source, and validation rules
- [handle-abp-support-ticket Dependency Map](./handle-abp-support-ticket-dependency-map.md) - ABP support-ticket analysis and support-answer workflow

## Source And Reference Workflows

- [abp-source-reference Dependency Map](./abp-source-reference-dependency-map.md) - lookup flow for ABP, ABP Studio, VOLO, and Lepton local source roots
- [abpdev-references Dependency Map](./abpdev-references-dependency-map.md) - switching consumer projects between NuGet and local project references

## QA, Review, And Tooling Workflows

- [abp-release-qa-orchestrator Dependency Map](./abp-release-qa-orchestrator-dependency-map.md) - release-diff QA planning and Turkish issue creation flow
- [code-review-excellence Dependency Map](./code-review-excellence-dependency-map.md) - structured pull-request review process and decision flow
- [scss-compiler Dependency Map](./scss-compiler-dependency-map.md) - SCSS-to-CSS compile, mapping, and verification workflow

## Supporting Docs

- [OpenCode Runtime Layout](./opencode-runtime-layout.md) - repository structure and runtime-vs-docs boundary guidance

## Notes

1. These docs are intentionally kept under `docs/`, not under `opencode/`, so they do not become runtime assets.
2. Cross-links are added between workflow docs when one documented workflow explicitly depends on or naturally feeds into another.
