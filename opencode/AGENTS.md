- For GitHub links or repository access, prefer `gh` first when private access or repository data/actions may be involved, and use plain web fetching for clearly public content or when `gh` is unavailable, failing, or not appropriate.

## Uncommitted Change Hygiene

- For code-editing tasks inside a Git repository, check `git status --short --branch` before substantial edits so you know whether the worktree already contains user or other-agent changes.
- Keep edits tightly scoped to the requested task. Avoid broad formatting, generated-file churn, dependency lockfile churn, or unrelated cleanup unless explicitly requested or required for correctness.
- Do not revert, overwrite, or mix unrelated uncommitted changes. If existing changes overlap the files you need to edit, read them carefully and ask before making a conflicting change.
- During long or multi-repository tasks, periodically check `git diff --stat` or `git status --short` after meaningful milestones. If the uncommitted diff grows large, pause and recommend a checkpoint commit or task split instead of continuing to accumulate changes.
- Do not create commits unless the user explicitly asks for a commit. If a large validated change set is complete and left uncommitted, clearly tell the user and offer to commit it.
- Prefer finishing each requested unit with a small, reviewable diff and a clean/synced worktree when the user has asked for commit/push. This helps avoid OpenCode Desktop/server instability caused by large uncommitted diffs.

## Web Research

- When the user asks you to perform web research or find external information on the internet, you MUST use the `bash` tool to run the headless `gemini` CLI.
- Run the command: `gemini -p "Use google web search to [your search query here]"` to leverage Gemini's native Google Grounding tools.
- Read the output from the CLI to gather your findings and provide a concise summary to the user.
