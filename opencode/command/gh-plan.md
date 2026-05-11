---
description: Build a day plan from your GitHub responsibilities and recent activity
argument-hint: "[1d|3d|7d] [limit=20] [repos=owner/repo,...]"
tools:
  bash: true
  question: true
---

<objective>
Build a practical GitHub work plan for today.

This command is responsibility-first: start from your open assigned issues and open review requests, then use recent activity as context to decide what deserves attention now versus later.

This command is script-first: use the local PowerShell collector to gather deterministic JSON, then use the model for prioritization and selective follow-up.
</objective>

<input_contract>
Accept freeform tokens and key=value pairs.

Supported arguments:
- `1d`, `3d`, `7d`
- `limit=<n>`
- `repos=<comma-separated owner/repo values>`

Interpretation rules:
- No arguments => `3d`
- The window controls how much recent activity context to include
- `limit` applies to each primary bucket: assigned issues, review requests, and authored open PRs
- If `repos` is omitted, consider all repositories you can access
</input_contract>

<safety>
- Use the local script as the primary data source instead of building the whole view ad hoc in the prompt
- Use `gh` first for GitHub data access when extra detail is needed
- Do not mutate GitHub state unless explicitly asked
- Do not fetch full details for every item; only enrich the top candidates needed for a better ranking
- Prefer items with a concrete next action for you over items that are merely waiting on review, merge, or someone else's follow-up
</safety>

<process>
1. Run the local collector script first:
   - `pwsh -NoProfile -File "$HOME/.config/opencode/command/gh-plan.ps1" $ARGUMENTS`
2. Treat the script JSON as the source of truth for your current work surface.
3. Use these inputs in priority order:
   - `assignedIssues`
   - `reviewRequests`
   - `recentCiActivities`
   - `authoredOpenPrs`
   - `recentActionableNotifications`
4. Before ranking, classify candidates into `actionable now`, `waiting on others`, or `already covered`:
   - If an assigned issue already has an open related PR or is clearly represented by an in-flight PR for the same work, do not put the issue in `Pick Up Now` unless follow-up shows a concrete next step for you now
   - If one of your open PRs is mergeable, green, and simply awaiting review, approval, or merge by someone else, do not put it in `Pick Up Now`; keep it visible but treat it as waiting work
   - If a review request or notification points to a PR that is already merged or closed, drop it from the plan
   - Avoid double-counting the same work as both an issue and a PR; prefer the artifact with the next concrete action for you
5. Rank using this rubric:
   - highest: assigned open issues with `priority:high`, `bug`, regressions, customer-facing problems, or small urgent fixes, but only when there is still a clear next action for you
   - high: direct review requests on still-open PRs, especially when they are blocking another person or closely related to active assigned issues
   - medium: your own open PRs that need author action, such as failing CI, requested changes, merge conflicts, or reviewer questions that need a response; include CI failures that may block your repos or releases
   - low: your own PRs that are merely awaiting review or merge, stale items with no recent movement, draft review requests with no clear action, or older background tasks
6. For only the top candidates, fetch extra detail if needed:
   - `gh issue view <url> --json ...`
   - `gh pr view <url> --json ...`
   - use targeted `gh` follow-up to confirm whether a top assigned issue is already in flight via an open PR before recommending it as `Pick Up Now`
   - `gh run view <url or id>` or repo-specific `gh run list` when CI context matters
7. Produce a day-planning report with these sections:
   - `Pick Up Now`: the top items worth starting immediately
   - `After That`: worthwhile follow-up items once the top item is moving
   - `Keep Warm`: items to keep visible but not start first
8. For each item include:
   - a clickable Markdown link in the form `[owner/repo#123](https://github.com/owner/repo/issues/123)` or the PR equivalent
   - title
   - why it appears in the plan
   - whether it came from assignment, review queue, CI, or authored PR follow-up
   - whether it needs your action now or is currently waiting on others
9. When referring back to an item elsewhere in the response, prefer the same clickable Markdown link instead of plain text.
10. Finish with a direct recommendation for `first task to start today`.

If there is no meaningful work in the current result set, say so clearly and summarize what was checked.
</process>

<examples>
- `/gh-plan`
- `/gh-plan 1d`
- `/gh-plan 3d limit=10`
- `/gh-plan repos=volosoft/volo,abpframework/abp`
</examples>
