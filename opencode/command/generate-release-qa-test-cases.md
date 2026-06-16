---
description: Generate ABP/VOLO/Lepton release-QA test cases and Turkish vs-internal issues from branch diffs
argument-hint: "framework_from=10.4 framework_to=10.5 [lepton_from=5.4 lepton_to=5.5] [assignee=gizemmutukurt]"
tools:
  bash: true
  read: true
  glob: true
  grep: true
  apply_patch: true
  question: true
---

<objective>
Generate release-QA test-plan markdown files for `C:\P\abp`, `C:\P\volo`, and `C:\P\lepton`, then create three Turkish GitHub issues in `C:\P\vs-internal`.

This command is script-first:
- use the bundled PowerShell scripts for argument normalization, branch/PR collection, reference extraction, coverage validation, and issue creation
- use model judgment only for UI-testable filtering, feature grouping, Turkish wording, and coverage adjustments
- do not use the `abp-release-qa-orchestrator` skill; this command is the workflow owner
</objective>

<bundled_scripts>
- Argument normalizer: `$HOME/.config/opencode/command/generate-release-qa-test-cases.ps1`
- Branch/PR collector: `$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/collect-release-data.ps1`
- Reference extractor: `$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/extract-reference-urls.ps1`
- Coverage validator: `$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/validate-coverage.ps1`
- Issue creator/updater: `$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/create-issue.ps1`
</bundled_scripts>

<input_contract>
Accept key=value pairs, `key: value` pairs, or a JSON object.

Required:
- `framework_from`
- `framework_to`

Optional:
- `lepton_from`
- `lepton_to`
- `assignee` default: `gizemmutukurt`

Repo roots default to:
- `C:\P\abp`
- `C:\P\volo`
- `C:\P\lepton`
- `C:\P\vs-internal`
</input_contract>

<branch_derivation>
Framework repos (`abp`, `volo`):
- source branch: `rel-{framework_from}`
- target branch: `rel-{framework_to}`

Lepton repo (`lepton`):
- if `lepton_from` / `lepton_to` are provided, use them directly
- otherwise derive `lepton_major = framework_major - 5` and `lepton_minor = framework_minor`
- branch names: `rel-{derived_version}`

Example:
- `framework_from=10.0`, `framework_to=10.1`
- derived Lepton versions: `5.0 -> 5.1`
</branch_derivation>

<safety>
- use `gh` first for GitHub access
- do not edit or revert unrelated changes in the target repos
- use the bundled scripts as the deterministic source of branch/PR data instead of rebuilding the same logic ad hoc
- create or edit GitHub issues only after coverage validation passes
- issue bodies must be written to files and passed with `--body-file` through the bundled issue script; do not rely on inline multiline `gh --body` text
</safety>

<process>
1. Run the normalizer first:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/generate-release-qa-test-cases.ps1" $ARGUMENTS`
2. Treat the normalizer JSON as the source of truth for versions, branches, repo roots, output markdown paths, and issue defaults.
3. For each repo context from the normalizer JSON, run the collector script:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/collect-release-data.ps1" -RepoPath <repoPath> -RepoFullName <repoFullName> -FromBranch <fromBranch> -ToBranch <toBranch> -OutputPath <jsonOutputPath>`
4. Build the non-bot exhaustive baseline from collector output:
   - exclude author/login `github-actions[bot]`
   - exclude author/login `github-actions`
   - exclude bot-authored auto-sync titles matching `^Merge branch dev with rel-\d+\.\d+$`
5. Derive the final `ui_testable_set` using collector evidence plus model judgment:
   - collector `suggestedUiTestable`, `assessmentReason`, file classifications, title, and touched areas are hints, not a replacement for judgment
   - include backend/app changes when the effect is UI-verifiable by page/route/flow/message/visibility
   - exclude docs-only, workflow-only, version-only, infra-only, and technical-only items that cannot be verified from the UI
6. Write one markdown file per repo at the exact output path from the normalizer JSON, following the required document format below.
7. Prepare one temporary Turkish issue-body markdown file per repo in a scratch location you control.
8. Before each issue create/edit, run the coverage validator script against the issue-body file:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/validate-coverage.ps1" -DocumentPath <issueBodyPath> -RepoFullName <repoFullName> -ExpectedUrlsCsv <comma-separated-ui-testable-pr-urls>`
9. If validation reports missing URLs, update the test cases until `missing.Count = 0`.
10. Create the issues with the bundled issue script:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/generate-release-qa-test-cases/scripts/create-issue.ps1" -IssueRepoPath <vsInternalPath> -Title <issueTitle> -BodyFile <issueBodyPath> -Assignee <assignee>`
11. Return a compact summary with generated markdown file paths, created issue URLs, assignee verification, and per-repo coverage result.
</process>

<qa_markdown_format>
Create one markdown file in each repo root named exactly:
- `rel-{from}-to-rel-{to}-changelog-and-testing-scenarios.md`

Required sections:
1. `# QA Test Plan: {repo} {from} -> {to}`
2. `## Scope`
3. `## Feature Groups`
4. `## Test Cases` grouped by feature
5. `## Risk-Based Priority` with P0/P1/P2
6. `## Notes` mentioning whether the plan is based on PR mapping or direct commits

Each test case must include Turkish field labels:
- `Test Case ID/Adı`
- `Etkilenen PR/Commit Referansları` with full URLs only
- `Nereden Test Edilir`
- `Etkilenen Yerler`
- `Test Adımları`
- `Beklenen Sonuç`
- `Efor Sınıfı (XS/SM/MD/LG/XL)`
- `Efor Gerekçesi`
- `Tahmini Süre` when useful
- `Öncelik (P0/P1/P2)`

Effort classes are test effort levels, not viewport sizes:
- `XS`: very low effort
- `SM`: low effort
- `MD`: medium effort
- `LG`: high effort
- `XL`: very high effort
</qa_markdown_format>

<issue_rules>
- All issue titles and bodies must be in Turkish.
- Use correct Turkish characters in natural language: `ç`, `ğ`, `ı`, `İ`, `ö`, `ş`, `ü`.
- Preserve technical tokens, paths, and URLs exactly.
- Issue title format: `QA Test Plan: {RepoAdi} {from} -> {to}`.
- PR references must be full URLs, for example `https://github.com/abpframework/abp/pull/12345`; never use `#12345`.
- Test cases must be markdown checklist entries using `- [ ]`.
- Each test-case block must contain its own `Etkilenen PR/Commit Referansları` list.
- Do not add a final exhaustive PR dump at the end of the issue.
- If no PR mapping exists, use full commit URLs under the relevant test case and add a note that commit URLs were used because no PR mapping was found.
- Issue bodies must be self-contained; never refer to local markdown paths such as `C:\P\...\.md`.
- If editing an existing issue, preserve existing `@username` mentions.
</issue_rules>

<coverage_rules>
- `exhaustive PR set`: full merge PR baseline from branch diff, excluding bot authors and excluded bot auto-sync titles.
- Bot author/login exclusions: `github-actions[bot]` and `github-actions`.
- Excluded bot auto-sync title pattern: `^Merge branch dev with rel-\d+\.\d+$`.
- `ui_testable_set`: non-bot exhaustive PRs with UI-verifiable impact through route/page/flow/message/visibility, including backend/app changes when user-facing behavior is UI-testable.
- `scenario_pr_set`: PR URLs referenced under test-case `Etkilenen PR/Commit Referansları` fields in the issue body.
- Default validation: `ui_testable_set - scenario_pr_set = 0`.
- In UI mode, `scenario_pr_set` can intentionally be a subset of the non-bot exhaustive PR set.
- If validation reports missing URLs, add or adjust test cases and run validation again.
</coverage_rules>

<validation_checklist>
- `C:\P\abp` contains the generated QA markdown document.
- `C:\P\volo` contains the generated QA markdown document.
- `C:\P\lepton` contains the generated QA markdown document.
- `C:\P\vs-internal` has three created or updated issues.
- All issue URLs are captured in the final response.
- All issues are assigned to the requested assignee, default `gizemmutukurt`.
- Bot PRs are excluded from baseline and coverage validation.
- UI-testable filtering is explained.
- Coverage validation passes with no missing UI-testable PR URLs.
- Every test case has checkbox format, effort class, effort rationale, and priority.
- Issue bodies contain no local markdown file path references.
- Turkish language quality is checked.
</validation_checklist>

<failure_handling>
- If PR matching is unavailable, use direct commits from the branch range.
- Put full commit URLs under the relevant test-case references.
- Add a note: `PR eşleştirmesi bulunamadı, commit URL referansları kullanıldı.`
- If coverage validation does not pass, add or update test-case blocks and retry before creating or editing issues.
</failure_handling>

<examples>
- `/generate-release-qa-test-cases framework_from=10.4 framework_to=10.5`
- `/generate-release-qa-test-cases framework_from=10.4 framework_to=10.5 lepton_from=5.4 lepton_to=5.5`
- `/generate-release-qa-test-cases {"framework_from":"10.4","framework_to":"10.5","lepton_from":"5.4","lepton_to":"5.5"}`
</examples>
