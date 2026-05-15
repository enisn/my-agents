---
name: volo-admin-console-generated-conflicts
description: Use when fixing volo PR merge conflicts in abp/admin-console generated React Admin Console assets, wwwroot/admin-console files, package-lock.json, route-config.ts, or build-and-pack.ps1 output.
---

# Volo Admin Console Generated Conflicts

Use this skill when a `volosoft/volo` PR has conflicts caused by React Admin Console generated output under `abp/admin-console/src/Volo.Abp.AdminConsole/wwwroot/admin-console`, especially after release-to-dev auto-merge PRs.

## Required Context

- Prefer `gh` for PR access because the repository may be private.
- Read `abp/admin-console/AGENTS.md` before changing files in that subtree.
- Start from a clean or understood worktree. Do not revert unrelated user changes.
- Generated `wwwroot/admin-console` output may be ignored by `.gitignore` on newer branches and rebuilt by `Volo.Abp.AdminConsole.csproj` during pack.

## Workflow

1. Inspect the PR and checkout its branch:
   - `gh pr view <number> --json headRefName,baseRefName,mergeStateStatus,url`
   - `gh pr checkout <number>`
2. Fetch the base branch and merge it into the PR branch:
   - `git fetch origin <baseRefName>`
   - `git merge origin/<baseRefName>`
3. Resolve generated asset conflicts by accepting the incoming/base result:
   - If incoming/base deleted `wwwroot/admin-console` and added it to `.gitignore`, use `git rm -r -f abp/admin-console/src/Volo.Abp.AdminConsole/wwwroot/admin-console` and do not force-add rebuilt ignored files unless the user explicitly asks.
   - If the target branch still tracks generated assets, accept the incoming generated files first, then rebuild and stage the regenerated tracked output.
4. Resolve source conflicts manually instead of blindly taking one side:
   - Keep both branches' real source changes in `react-app` files such as `route-config.ts`, `package.json`, and `package-lock.json`.
   - If a source file keeps imports/code from one side, make sure the matching dependency from the other side is preserved in `package.json`.
5. Run the canonical build/package script from `abp/admin-console`:
   - `powershell -ExecutionPolicy Bypass -File .\build-and-pack.ps1 -Configuration Release`
6. Stage the merge resolution:
   - `git add -A`
   - Confirm `git diff --name-only --diff-filter=U` is empty.
   - Confirm conflict markers are absent with an anchored search such as `^(<<<<<<<|=======|>>>>>>>)`.
7. Commit and push only the PR branch fix:
   - `git commit --no-edit`
   - `git push origin <headRefName>`
8. Re-check the PR:
   - `gh pr view <number> --json mergeStateStatus,headRefOid,url`
   - `DIRTY` means conflicts remain. `BLOCKED` usually means checks, reviews, or branch rules rather than conflicts.

## Notes

- `build-and-pack.ps1` runs `npm install`, `npm run build`, copies dist to `wwwroot/admin-console`, and runs `dotnet pack`.
- Newer Admin Console projects can run `npm run build:wwwroot` from MSBuild, so generated files can exist locally after the build while remaining ignored by Git.
- Do not push unrelated local skill/config changes together with the PR merge fix.
