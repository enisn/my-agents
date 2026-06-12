---
description: Prepare ABP/VOLO/Lepton release-QA markdown and Turkish vs-internal issues from branch diffs
argument-hint: "framework_from=10.4 framework_to=10.5 [lepton_from=5.4 lepton_to=5.5] [assignee=gizemmutukurt]"
tools:
  bash: true
  read: true
  glob: true
  grep: true
  apply_patch: true
  skill: true
  question: true
---

<objective>
Generate release-QA test-plan markdown files for `C:\P\abp`, `C:\P\volo`, and `C:\P\lepton`, then create three Turkish GitHub issues in `C:\P\vs-internal`.

This command is script-first:
- use the bundled PowerShell scripts for argument normalization, branch/PR collection, reference extraction, coverage validation, and issue creation
- use the `abp-release-qa-orchestrator` skill as the policy source for UI-mode filtering, grouping, coverage rules, and Turkish issue structure
</objective>

<input_contract>
Accept key=value pairs, `key: value` pairs, or a JSON object.

Required:
- `framework_from`
- `framework_to`

Optional:
- `lepton_from`
- `lepton_to`
- `assignee` (default: `gizemmutukurt`)

Interpretation rules:
- if `lepton_from` / `lepton_to` are omitted, derive them with the existing offset rule from the skill
- repo roots default to:
  - `C:\P\abp`
  - `C:\P\volo`
  - `C:\P\lepton`
  - `C:\P\vs-internal`
</input_contract>

<safety>
- use `gh` first for GitHub access
- do not edit or revert unrelated changes in the target repos
- use the bundled scripts as the deterministic source of branch/PR data instead of rebuilding the same logic ad hoc
- create or edit GitHub issues only after coverage validation passes
</safety>

<process>
1. Run the normalizer first:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/abp-release-qa.ps1" $ARGUMENTS`
2. Treat the normalizer JSON as the source of truth for versions, branches, repo roots, output markdown paths, and issue defaults.
3. Load and follow the `abp-release-qa-orchestrator` skill.
4. For each repo context from the normalizer JSON, run the collector script:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/skills/abp-release-qa-orchestrator/scripts/collect-release-data.ps1" -RepoPath <repoPath> -RepoFullName <repoFullName> -FromBranch <fromBranch> -ToBranch <toBranch> -OutputPath <jsonOutputPath>`
5. Build the non-bot exhaustive baseline from collector output:
   - exclude author/login `github-actions[bot]`
   - exclude author/login `github-actions`
   - exclude bot-authored auto-sync titles matching `^Merge branch dev with rel-\d+\.\d+$`
6. Derive the final `ui_testable_set` using collector evidence plus model judgment:
   - collector `suggestedUiTestable`, `assessmentReason`, file classifications, title, and touched areas are hints, not a replacement for judgment
   - include backend/app changes when the effect is UI-verifiable by page/route/flow/message/visibility
   - exclude docs-only, workflow-only, version-only, infra-only, and technical-only items that cannot be verified from the UI
7. Write one markdown file per repo at the exact output path from the normalizer JSON, following the skill's required section structure.
8. Prepare one temporary Turkish issue-body markdown file per repo in a scratch location you control.
9. Before each issue create/edit, run the coverage validator script against the issue-body file:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/skills/abp-release-qa-orchestrator/scripts/validate-coverage.ps1" -DocumentPath <issueBodyPath> -RepoFullName <repoFullName> -ExpectedUrlsCsv <comma-separated-ui-testable-pr-urls>`
10. If validation reports missing URLs, update the test cases until `missing.Count = 0`.
11. Create the issues with the bundled issue script:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/skills/abp-release-qa-orchestrator/scripts/create-issue.ps1" -IssueRepoPath <vsInternalPath> -Title <issueTitle> -BodyFile <issueBodyPath> -Assignee <assignee>`
12. Return a compact summary with:
   - generated markdown file paths
   - created issue URLs
   - assignee verification
   - per-repo coverage result
</process>

<examples>
- `/abp-release-qa framework_from=10.4 framework_to=10.5`
- `/abp-release-qa framework_from=10.4 framework_to=10.5 lepton_from=5.4 lepton_to=5.5`
- `/abp-release-qa {"framework_from":"10.4","framework_to":"10.5","lepton_from":"5.4","lepton_to":"5.5"}`
</examples>
