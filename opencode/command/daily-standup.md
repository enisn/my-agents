---
description: Build a Turkish daily standup answer from Taskever agenda/tasks and recent GitHub activity
argument-hint: "[today=YYYY-MM-DD] [yesterday=YYYY-MM-DD] [orgs=abpframework,volosoft] [repos=owner/repo,...] [window=2d]"
---

<objective>
Build a concise daily standup answer for the user by combining Taskever agenda/task data with recent GitHub activity.

The command prompt and reasoning instructions are intentionally written in English. The final user-facing answer must be in Turkish unless the user explicitly asks for another language in `$ARGUMENTS`.
</objective>

<input_contract>
Accept freeform tokens and key=value pairs.

Supported arguments:
- `today=YYYY-MM-DD`
- `yesterday=YYYY-MM-DD`
- `from=YYYY-MM-DD`
- `to=YYYY-MM-DD`
- `window=<n>d`
- `orgs=<comma-separated GitHub orgs>`
- `repos=<comma-separated owner/repo values>`
- `include-meetings=true|false`
- `language=tr|en`

Interpretation rules:
- No arguments => use the local current date as `today`, and the previous calendar day as `yesterday`.
- If `today` is omitted, get it from the system date available to the session or by running a safe local date command.
- If `yesterday` is omitted, calculate it as one day before `today`.
- `from` and `to` override the activity search window. If only `window` is provided, use the last `n` days ending on `today`.
- If `orgs` is omitted, use `abpframework,volosoft`.
- If `repos` is provided, prefer repo-scoped GitHub searches over org-wide searches.
- If `include-meetings` is omitted, include meeting agenda items only as context and do not list them as work unless the meeting itself was the work.
- If `language` is omitted, output Turkish.
</input_contract>

<safety>
- Do not mutate Taskever or GitHub state.
- Use Taskever tools for Taskever data and `gh` for GitHub data.
- Do not mark inbox items or notifications as read.
- Do not create comments, tasks, issues, PRs, commits, or edits.
- If a Taskever list call fails because of permission or token contention, retry once sequentially if useful, then continue with the data already available.
- If GitHub CLI auth fails, report that clearly and still use Taskever data if available.
- Avoid exposing raw private details unnecessarily; summarize work items by title, repo/project, number, and status.
</safety>

<taskever_collection>
1. Get the Taskever profile first. Use it to identify:
   - Taskever user id
   - Taskever username
   - GitHub username, if present
2. Get agenda items from `yesterday` through `today` with completed, done, and meeting items included.
3. Get pending inbox and unread summaries.
4. Get visible projects if useful for resolving project slugs and task links.
5. For agenda items that link to Taskever tasks or requests, fetch details when the task/request id or project task key is available.
6. If agenda item text contains a recognizable GitHub URL, keep that URL and later enrich it via `gh`.
7. Treat Taskever as the primary source for planned work and explicit personal agenda state.
</taskever_collection>

<github_collection>
1. Verify the authenticated GitHub login with `gh api user --jq '.login'`.
2. Prefer the GitHub username from Taskever if present; otherwise use the authenticated `gh` login.
3. Search recent activity for the chosen date window.
4. For each target org or repo, collect:
   - PRs authored by the user and updated in the window.
   - PRs authored by the user and created in the window.
   - PRs authored by the user and merged/closed in the window when supported by `gh search prs` flags.
   - PRs reviewed by the user and updated in the window.
   - issues and PRs commented on by the user and updated in the window.
   - open issues assigned to the user.
   - open PRs where review is requested from the user.
5. Use commands shaped like these, adapting org/repo/date arguments as needed:
   - `gh search prs --owner <org> --author <login> --updated "YYYY-MM-DD..YYYY-MM-DD" --json repository,title,number,state,isDraft,createdAt,updatedAt,closedAt,url --limit 50`
   - `gh search prs --owner <org> --reviewed-by <login> --updated "YYYY-MM-DD..YYYY-MM-DD" --json repository,title,number,state,isDraft,createdAt,updatedAt,closedAt,url --limit 50`
   - `gh search issues --include-prs --owner <org> --commenter <login> --updated "YYYY-MM-DD..YYYY-MM-DD" --json repository,title,number,state,isPullRequest,createdAt,updatedAt,closedAt,url --limit 50`
   - `gh search issues --owner <org> --assignee <login> --state open --json repository,title,number,state,isPullRequest,createdAt,updatedAt,url --limit 50`
   - `gh search prs --owner <org> --review-requested <login> --state open --json repository,title,number,state,isDraft,createdAt,updatedAt,url --limit 50`
6. If a search field is unsupported by the installed `gh` version, adjust to available fields instead of stopping.
7. For only the most relevant items, fetch extra details with `gh pr view` or `gh issue view` to confirm state, review decision, latest reviews, CI context, linked issue context, or merge time.
8. Deduplicate by URL. Prefer the most specific artifact with the clearest next action.
9. Treat GitHub as a secondary source for activity that may not have synced to Taskever.
</github_collection>

<classification>
Create two answer buckets:

`Dun ne yaptin?`
- Completed or effectively done Taskever agenda items dated `yesterday`.
- PRs authored/reviewed/commented by the user that were created, materially updated, merged, or closed during `yesterday`.
- Work that was started yesterday and resolved early today may be mentioned as a follow-up if it clearly belongs to yesterday's work stream.
- Group related issue/PR/task references into one sentence instead of listing duplicates.

`Bugun ne yapacaksin?`
- Taskever agenda items dated `today` that are pending, open, or in progress.
- Open GitHub assigned issues, requested reviews, authored PRs needing author action, failing CI, requested changes, or reviewer feedback.
- Prioritize work that is already in progress, blocked by feedback, assigned to the user, or due soon.
- Do not list work that is merely waiting on someone else unless it needs follow-up or monitoring.
</classification>

<output>
Write the final answer in Turkish by default.

Output format:
- Start directly with `Dun ne yaptin?` and a first-person answer.
- Then `Bugun ne yapacaksin?` and a first-person answer.
- If useful, add a short `Notlar` section for sync gaps, data-source caveats, or blockers.
- Keep it standup-friendly: concise, concrete, and readable aloud.
- Include key issue/PR/task numbers as clickable Markdown links when URLs are known.
- Avoid dumping raw tool output.
- Do not include the internal investigation steps unless there was a data access problem.
</output>

<examples>
- `/daily-standup`
- `/daily-standup today=2026-06-17`
- `/daily-standup orgs=abpframework,volosoft window=2d`
- `/daily-standup repos=abpframework/abp,volosoft/abp-studio`
- `/daily-standup language=en`
</examples>
