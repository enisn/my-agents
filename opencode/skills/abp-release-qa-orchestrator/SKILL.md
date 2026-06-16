---
name: abp-release-qa-orchestrator
description: Use ONLY when the user asks about ABP/VOLO/Lepton release QA generation, QA test cases from release branch diffs, or the old abp-release-qa-orchestrator workflow. Do not run the workflow directly; suggest the /generate-release-qa-test-cases command.
---

# ABP Release QA Command Router

This workflow is command-only.

Do not collect branches, generate markdown, run scripts, or create GitHub issues from this skill.

If the user wants ABP/VOLO/Lepton release QA test cases, suggest this command:

`/generate-release-qa-test-cases framework_from=10.4 framework_to=10.5`

Optional examples:

`/generate-release-qa-test-cases framework_from=10.4 framework_to=10.5 lepton_from=5.4 lepton_to=5.5`

`/generate-release-qa-test-cases {"framework_from":"10.4","framework_to":"10.5","assignee":"gizemmutukurt"}`

The command owns the scripts, validation rules, issue creation, and side effects.
