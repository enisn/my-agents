---
description: Sync OpenCode runtime assets with the my-agents repo while preserving local secrets and excluding GSD assets
argument-hint: "[repo=<path>] [local=<path>] [no-push]"
tools:
  bash: true
  read: true
  glob: true
  grep: true
  apply_patch: true
  question: true
---

<objective>
Synchronize OpenCode runtime assets between the local OpenCode configuration and the source repository, using Git and diffs for mechanics and model judgment for logical merges.

Default source repository: `C:\P\my-agents`
Default repository runtime root: `C:\P\my-agents\opencode`
Default local runtime root: `$HOME/.config/opencode`
</objective>

<input_contract>
Accept freeform tokens and key=value pairs.

Supported arguments:
- `repo=<path>`: override the source repository root
- `local=<path>`: override the local OpenCode runtime root
- `no-push`: commit repo changes but do not push

Examples:
- `/opencode-sync`
- `/opencode-sync no-push`
- `/opencode-sync repo=C:\P\my-agents local=$HOME/.config/opencode`
</input_contract>

<sync_scope>
Sync these paths under both runtime roots when present:
- `AGENTS.md`
- `agent/**`
- `agents/**`
- `command/**`
- `skills/**`
- `hooks/**`
- `plugin/**`
- `plugins/**`
- `mcp-servers/**`
- `tool/**`
- `tools/**`
- `opencode.json`
- `opencode.jsonc`
- `settings.json`

Do not collapse similarly named folders. `agent/` and `agents/` are separate OpenCode runtime directories and both must be considered.
</sync_scope>

<exclusions>
Exclude these everywhere, per file or directory basename:
- any basename starting with `gsd-*`
- `get-shit-done/**`
- `gsd-file-manifest.json`
- `node_modules/**`
- `logs/**`
- `__pycache__/**`
- `captures/**`
- `.venv/**`
- `venv/**`
- `dist/**`
- `build/**`
- `*.pyc`
- `*.tmp`
- `.lock-*`
- `*.bak.*`

Important: filter per file. Do not assume an entire folder is GSD or non-GSD.
</exclusions>

<secret_policy>
- Never copy local secrets into the GitHub repository.
- Preserve local secret values when merging config files.
- For repo-side config, use placeholders, environment-variable references, or omit machine-local secret values.
- Treat these as secret-bearing unless proven otherwise: `opencode.json`, `opencode.jsonc`, `settings.json`, `mcp-servers/**`, `hooks/**`, `plugin/**`, `plugins/**`, `tool/**`, `tools/**`.
- Prefer OS/user-level environment variables for API keys instead of literal values in OpenCode config files.
- Use OpenCode config variable syntax `{env:VARIABLE_NAME}` when referencing environment variables in JSON/JSONC.
- The helper blocks common secret shapes in repo files, including key names containing `API_KEY`, `TOKEN`, `SECRET`, `PASSWORD`, connection strings, `Authorization: Bearer ...`, and CLI arguments such as `--api-key=...`.
- The helper reports every `{env:...}` reference used by local `opencode.jsonc` or `opencode.json`, and whether that variable is visible to the current process, user environment, or machine environment.
- Do not print secret values in the response, commit message, or diagnostics.
- If a useful repo update conflicts with a local secret, keep the local value locally and commit only the non-secret structure or placeholder in the repo.
</secret_policy>

<process>
Do not run multiple helper modes concurrently against the same repository. Git fetch, pull, stage, commit, and push steps must be sequential.

1. Always start by running the helper in prepare mode:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/opencode-sync.ps1" -Mode Prepare -RawArguments "$ARGUMENTS"`
2. Treat the helper output as the candidate inventory, not as permission to copy blindly.
3. For each candidate diff worth syncing, inspect the real diff with Git before editing:
   - `git diff --no-index -- "<repo-runtime-file>" "<local-runtime-file>"`
   - `git -C <repo-root> diff -- opencode`
4. Merge logically with `apply_patch`:
   - update both repo and local copies when both should converge
   - preserve local-only secrets locally
   - use repo-safe placeholders for secret-bearing repo config
   - keep `agent/` and `agents/` paths distinct
   - never add excluded GSD files
   - if the intended merge strategy is unclear, stop and ask the user before editing
5. After edits, rerun prepare mode to review the remaining diff surface:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/opencode-sync.ps1" -Mode Prepare -RawArguments "$ARGUMENTS"`
6. Run the secret scan before committing anything:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/opencode-sync.ps1" -Mode Scan -RawArguments "$ARGUMENTS"`
7. Check environment-variable references used by local OpenCode config:
   - `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/opencode-sync.ps1" -Mode EnvCheck -RawArguments "$ARGUMENTS"`
   - if a referenced variable is present in User/Machine but not the current process, tell the user to restart OpenCode/terminal
   - if a referenced variable is missing, report the variable name and reference location without printing any secret value
8. Check the repository status:
   - `git -C <repo-root> status --short`
9. If repository changes are present and the scan passes, commit and push unless `no-push` was requested:
   - normal path: `pwsh -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/command/opencode-sync.ps1" -Mode CommitPush -RawArguments "$ARGUMENTS"`
   - if unrelated pre-existing repo changes are present, do not use bulk commit mode; stage only the reviewed sync files manually, commit, and push if appropriate
10. Report what changed, what was intentionally left local-only, env variables that are missing or need a restart, and whether a push occurred.
</process>

<merge_guidance>
- Prefer the newest correct behavior, not necessarily the newest timestamp.
- If both sides edited instructions, combine compatible intent and remove duplication.
- If repo has a reusable agent/skill improvement and local has machine-specific paths, keep the reusable content in both and keep machine-specific values local or placeholder-backed.
- If only one side has a non-secret runtime file, usually add it to the other side unless it is machine-generated or excluded.
- If a deletion appears intentional on one side, verify from context before deleting from the other side.
- If files contain opposite directives, mutually exclusive behavior, or unclear conflicts, ask the user for the merge strategy before editing. Do not invent a compromise for safety, authority, model behavior, permissions, sync scope, secret handling, or destructive-operation rules.
</merge_guidance>
