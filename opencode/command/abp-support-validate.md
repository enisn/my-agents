---
description: Create a fresh ABP sandbox, apply proposed guidance, and validate it by build, tests, and optional browser checks.
argument-hint: "<freeform spec or JSON with version, scenario, changes, and optional template parameters>"
tools:
  task: true
  question: true
---

<objective>
Create a fresh ABP project for the requested version, apply the proposed support guidance or code change, and verify whether it is really valid before we present it as exact.
</objective>

<input_contract>
Accept freeform text, key=value pairs, or JSON.

Required:
- exact ABP version
- scenario, ticket link, or issue description
- proposed changes or guidance to validate

Optional:
- solution name
- output path (defaults to `C:\P\<solution-name>`; if it exists, use `C:\P\<solution-name>-lab-<timestamp>`)
- template
- ui
- tiered
- separate auth server
- mobile
- database provider
- database management system
- theme
- local framework reference path
- verify mode (`build`, `build,test`, `build,browser`, `full`)
- browser flows
</input_contract>

<process>
1. Parse `$ARGUMENTS` into a normalized validation spec.
2. If the exact ABP version is missing and cannot be inferred safely, ask exactly one targeted question for the version and stop.
3. Infer safe defaults for omitted fields:
   - `template=app`
   - `ui=mvc`
   - `mobile=none`
   - `database_provider=ef`
   - `verify=build`
   - if browser or runtime validation is requested and DBMS is omitted, prefer `SQLite` unless the scenario depends on another DBMS
4. Launch the `abp-support-lab` subagent with the normalized spec. Require it to:
   - resolve the correct CLI/version strategy
   - generate a fresh project
   - apply the requested changes
   - validate with build/tests/browser as appropriate
   - create `SUPPORT-LAB-REPORT.md`
   - clearly say whether the result is `validated`, `partially-validated`, or `guidance-only`
5. Return the subagent result concisely, including workspace path, report path, CLI version used, and pass/fail status.
</process>

<examples>
- `/abp-support-validate version=8.3.3 ui=mvc tiered=false verify=build ticket=https://abp.io/support/questions/10529/Hook-points-for-On-Prem-Windows-AD-authentication changes="Validate Windows AD LDAP override guidance"`
- `/abp-support-validate {"version":"10.1.0","ui":"angular","verify":"build,browser","scenario":"check login redirect guidance","changes":"apply the proposed AuthServer configuration fix"}`
</examples>
