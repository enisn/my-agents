- For GitHub links or repository access, prefer `gh` first when private access or repository data/actions may be involved, and use plain web fetching for clearly public content or when `gh` is unavailable, failing, or not appropriate.

## Uncommitted Change Hygiene

- For code-editing tasks inside a Git repository, check `git status --short --branch` before substantial edits so you know whether the worktree already contains user or other-agent changes.
- Keep edits tightly scoped to the requested task. Avoid broad formatting, generated-file churn, dependency lockfile churn, or unrelated cleanup unless explicitly requested or required for correctness.
- Do not revert, overwrite, or mix unrelated uncommitted changes. If existing changes overlap the files you need to edit, read them carefully and ask before making a conflicting change.
- During long or multi-repository tasks, periodically check `git diff --stat` or `git status --short` after meaningful milestones. If the uncommitted diff grows large, pause and recommend a checkpoint commit or task split instead of continuing to accumulate changes.
- Do not create commits unless the user explicitly asks for a commit. If a large validated change set is complete and left uncommitted, clearly tell the user and offer to commit it.
- Prefer finishing each requested unit with a small, reviewable diff and a clean/synced worktree when the user has asked for commit/push. This helps avoid OpenCode Desktop/server instability caused by large uncommitted diffs.

## Architecture Conflict Handling

- Before implementing a request that conflicts with the current architecture, package boundaries, dependency direction, layering, public API design, or ownership of a type, stop and explain the conflict clearly.
- Do not silently introduce wrapper types, factory abstractions, package references, dependency inversions, public API changes, or cross-layer references to satisfy the request unless the user has explicitly approved that architectural change.
- If the user's requested implementation would create a circular dependency, make a lower-level package depend on a higher-level package, couple generic infrastructure to a specific UI/theme package, or otherwise violate existing design boundaries, push back instead of proceeding.
- When there are two valid paths, ask a short confirmation question and present the tradeoff: preserve current architecture with a local/minimal fix, or change architecture with broader implications.
- If the user appears to request something that is impossible or undesirable under the current architecture, say so directly and propose the smallest architecture-compatible alternative.

## Web Research

- When the user asks you to perform web research or find external information on the internet, you MUST use the `bash` tool to run the headless `gemini` CLI.
- Run the command: `gemini -p "Use google web search to [your search query here]"` to leverage Gemini's native Google Grounding tools.
- Read the output from the CLI to gather your findings and provide a concise summary to the user.

## GitHub CLI Body Safety

- On Windows, do not rely on inline `\n` escape sequences in `gh` command arguments such as `--body`, since shell quoting often collapses or truncates multiline content.
- For PR bodies, issue bodies, comments, or other multiline GitHub content, prefer file-backed input such as `gh pr create --body-file <file>` or `gh api ... -F body=@<file>`.
- If you must update existing GitHub content and formatting matters, verify the stored body afterward with `gh pr view --json body`, `gh issue view --json body`, or the equivalent `gh api` readback.
