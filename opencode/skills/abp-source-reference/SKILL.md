---
name: abp-source-reference
description: "Reference map for local ABP Framework, ABP Studio, and commercial module source trees. Use when working on ABP internals so the agent checks real implementations under C:\\P\\abp, C:\\P\\abp-studio, C:\\P\\volo, and C:\\P\\lepton instead of guessing."
---

# ABP Source Reference

Use this skill whenever the task touches ABP internals, module behavior, extension methods, framework conventions, or unclear implementations.

## Local Source Roots (Exact Paths)

- `C:\P\abp` - ABP Framework monorepo (open-source framework + official OSS modules + npm packages + templates).
- `C:\P\abp-studio` - ABP Studio source tree and related tooling implementation.
- `C:\P\volo` - Commercial/pro modules and source-code bundles (SaaS, Chat, Payment, Lepton Theme, etc.).
- `C:\P\lepton` - Lepton theme repositories (ASP.NET Core, Angular, SSR, HTML assets, npm packs).

## Mandatory Behavior

Before answering implementation details:

1. Locate the exact symbol in one of the four roots.
2. Read the real code path(s) and related interfaces/base classes.
3. Answer with evidence from source; do not infer internals from memory.
4. If code is not found locally, explicitly say it was not found and what was searched.

## Source Map Summary

### 1) ABP Framework (`C:\P\abp`)

Top-level areas:

- `framework` - Core ABP framework source.
  - `C:\P\abp\framework\src` - Main framework implementations (`Volo.Abp.*`).
  - `C:\P\abp\framework\test` - Framework test coverage and behavior examples.
- `modules` - Official open-source modules.
  - Examples: `account`, `identity`, `permission-management`, `tenant-management`, `setting-management`, `cms-kit`, `blogging`, `audit-logging`, `background-jobs`, `openiddict`.
- `npm` - JS/TS packages (Angular/MVC assets and support packages).
  - `packs` and `ng-packs` contain package sources.
- `templates` - Startup templates/scaffolding references.
- `docs` - Official docs source; useful for intent/context, not implementation truth.

Use ABP root first when question is about:

- Core abstractions (`IRepository`, UoW, authorization, data filters, domain events, settings, features).
- Base classes and extension methods under `Volo.Abp.*` packages.
- OSS module behavior and endpoints.

### 2) Volo Modules (`C:\P\volo`)

Top-level areas:

- `C:\P\volo\abp` - Commercial/pro module repositories.
  - Examples: `saas`, `payment`, `chat`, `identity-pro`, `file-management`, `language-management`, `lepton-theme`, `ai-management`, `low-code`, `forms`, `gdpr`, `text-template-management`, `suite`.
- `C:\P\volo\source-code` - Downloadable source bundles per product.
  - Folders like `Volo.Saas.SourceCode`, `Volo.Chat.SourceCode`, `Volo.FileManagement.SourceCode`, `Volo.Payment.SourceCode`, `Volo.Abp.LeptonTheme.SourceCode`, etc.

Use Volo root when question is about:

- Commercial module implementation details.
- Module-specific application contracts and app services.
- Pro-only UI/API behavior not present in OSS `C:\P\abp\modules`.

### 3) ABP Studio (`C:\P\abp-studio`)

Use ABP Studio root when question is about:

- ABP Studio desktop app behavior and workflows.
- Studio-specific tooling, orchestration, and integration logic.
- Features that exist in Studio but not in framework/module repos.

### 4) Lepton (`C:\P\lepton`)

Top-level areas:

- `aspnet-core` - Theme integrations for ASP.NET Core side.
  - Contains `abp`, `volo`, and `source-code` folders.
- `angular` - Nx workspace for Angular theme packages.
  - `apps` and `libs` include Angular app/library sources.
- `SSR` - Server-side rendering project and appearance pipeline.
- `html` / `html-build` - Static theme assets and build outputs.
- `npm` - Theme npm packs and scripts.

Use Lepton root when question is about:

- LeptonX/Lepton Theme visual behavior, styling, layout, and UI components.
- Theme packaging and front-end distribution.
- ASP.NET Core + Angular theme integration points.

## Practical Search Order

1. Try `C:\P\abp` (framework + OSS modules).
2. If Studio-specific, check `C:\P\abp-studio`.
3. If likely commercial/pro, check `C:\P\volo`.
4. If UI/theme-specific, check `C:\P\lepton`.
5. Cross-check with tests/examples before final guidance.

## Response Style Requirements

When answering ABP-source questions:

- Include concrete file paths you inspected.
- Prefer statements like "In `.../X.cs`, method `Y` does ...".
- Distinguish verified facts from assumptions.
- If assumptions remain, label them clearly.

## Fast Reminder Snippet

"Use local ABP source of truth. Check `C:\P\abp`, `C:\P\abp-studio`, `C:\P\volo`, `C:\P\lepton` before answering; do not guess internal implementations."
