---
description: Review GitHub notifications and rank the next actions by urgency
argument-hint: "[1d|3d|7d|unread] [limit=10] [reasons=assign,review_requested,ci_activity] [repos=owner/repo,...] [participating=true] [unread-only=true]"
tools:
  bash: true
  question: true
---

<objective>
Inspect GitHub notifications with `gh`, identify what is actionable now, and rank the next work items by urgency.

This command is script-first: use the local PowerShell collector to fetch and normalize notifications into JSON, then use the model for prioritization and selective follow-up.

Default behavior is inbox triage for the last `3d`. Time-window mode includes read and unread items unless the user explicitly requests `unread-only=true`. Use `unread` when you want a strict unread-only view.
</objective>

<input_contract>
Accept freeform tokens and key=value pairs.

Supported arguments:
- `unread`
- relative windows: `1d`, `3d`, `7d`
- `limit=<n>`
- `reasons=<comma-separated reasons>`
- `repos=<comma-separated owner/repo values>`
- `participating=true|false`
- `unread-only=true|false`

Interpretation rules:
- No arguments => `3d`
- `1d`, `3d`, `7d` => use a time window ending now
- Time-window mode should include both read and unread items by default
- If both a time window and `unread-only=true` are provided, keep only unread items from that window
- If `reasons` is omitted, consider all reasons
- If `repos` is omitted, consider all repositories
</input_contract>

<safety>
- Use `gh` first for all GitHub data access
- Do not mark notifications as read or mutate GitHub state unless explicitly asked
- Use the local script as the primary data source for notifications instead of ad-hoc `gh api notifications` calls
- Do not over-fetch details for every item; fetch richer details only for the top actionable candidates
</safety>

<process>
1. Run the local collector script first:
   - `pwsh -NoProfile -File "$HOME/.config/opencode/command/gh-inbox.ps1" $ARGUMENTS`
2. Treat the script JSON as the source of truth for the notification list, applied filters, and query window.
3. If the script fails because `gh` is missing or authentication is invalid, report the failure clearly and ask at most one targeted question.
4. Rank urgency using this rubric:
   - highest: assigned open issues, especially `priority:high`, `bug`, customer-facing regressions, production-impact items, or small-effort urgent fixes
   - high: failing CI on your own repository default branch, direct `review_requested` items on open PRs, blocked work waiting on your review
   - medium: activity on your own open PRs that may need follow-up, subscribed issues with likely action, non-blocking review requests on draft PRs
   - low: closed issues, merged PRs, routine subscribed chatter, stale items with no clear action
5. For the top candidates only, fetch details to avoid guessing:
   - `gh issue view <url> --json ...` for issues
   - `gh pr view <url> --json ...` for pull requests
   - `gh run list` or `gh run view` for workflow failures when the notification is CI-related
6. Prefer fetching extra details for at most the top 3-5 actionable items, not the entire inbox.
7. Produce a concise triage report with these sections:
   - `Now`: ranked items that likely deserve immediate attention
   - `Soon`: items worth handling after the top group
   - `Noise / Cleanup`: items that are unread but likely require no action
8. For each ranked item, include:
   - **repository and number** as a clickable markdown link using the `url` field from the script output. Format: `[owner/repo#123](https://github.com/owner/repo/issues/123)` (use `/pull/` for PRs, `/issues/` for issues). The user needs to quickly open items across many repos, so every item mention must be a link.
   - subject title
   - notification reason
   - last update time
   - one-line why it is ranked there
9. Finish with a direct recommendation for `next item to pick up`, rendered as a clickable markdown link.

If there are no matching notifications, say so clearly and mention the applied query.
</process>

<examples>
- `/gh-inbox`
- `/gh-inbox 1d`
- `/gh-inbox 3d limit=15`
- `/gh-inbox 3d unread-only=true`
- `/gh-inbox unread reasons=assign,review_requested`
- `/gh-inbox 1d repos=volosoft/volo,abpframework/abp`
</examples>
