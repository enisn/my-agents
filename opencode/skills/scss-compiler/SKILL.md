---
name: scss-compiler
description: "Compile SCSS to CSS using Sass CLI with repo-aware defaults (direct file compile, watch mode, and compilerconfig.json mapping support). Use when: (1) user asks to compile .scss, (2) CSS output is missing/stale, (3) agent needs repeatable Sass commands."
---

# SCSS Compiler

Compile `.scss` files into `.css` files safely and consistently.

## When to Use This Skill

- User asks to compile one or more SCSS files
- A Razor/Page/Component style output CSS is missing
- `compilerconfig.json` includes SCSS input/output mappings
- Agent needs watch mode during frontend edits

## Core Rule

Prefer `sass <input.scss> <output.css>` with explicit paths.

For one-off builds:

```bash
sass "<input.scss>" "<output.css>"
```

For live development:

```bash
sass --watch "<input.scss>:<output.css>"
```

If Sass is not installed:

```bash
npm install -g sass
```

## Repo-Aware Workflow

### Step 1: Check for compiler mapping

Look for `compilerconfig.json` in the target project. If present, use its mapping first.

Example mapping:

```json
[
  {
    "outputFile": "Pages/FileManagement/index.css",
    "inputFile": "Pages/FileManagement/index.scss"
  }
]
```

### Step 2: Build from project root of mapping

If mapping exists, resolve paths relative to the `compilerconfig.json` directory and compile with explicit full paths.

### Step 3: Verify result

- Ensure output `.css` exists
- Ensure output timestamp is updated
- If source maps are unwanted, add `--no-source-map`

## Standard Commands

Single file compile:

```bash
sass "C:\path\to\input.scss" "C:\path\to\output.css"
```

Single file compile without source maps:

```bash
sass --no-source-map "C:\path\to\input.scss" "C:\path\to\output.css"
```

Watch mode:

```bash
sass --watch "C:\path\to\input.scss:C:\path\to\output.css"
```

## Known Good Example (This Repository)

Input:

`C:\P\volo\abp\file-management\src\Volo.FileManagement.Web\Pages\FileManagement\index.scss`

Output:

`C:\P\volo\abp\file-management\src\Volo.FileManagement.Web\Pages\FileManagement\index.css`

Compile command:

```bash
sass "C:\P\volo\abp\file-management\src\Volo.FileManagement.Web\Pages\FileManagement\index.scss" "C:\P\volo\abp\file-management\src\Volo.FileManagement.Web\Pages\FileManagement\index.css"
```

## Troubleshooting

- `sass: command not found`
  - Install globally: `npm install -g sass`
  - Or use `npx sass ...`
- Relative path confusion
  - Use absolute paths
  - Or run command in project folder and keep mapping-relative paths
- CSS not updated
  - Confirm correct input file
  - Check for compile errors in terminal output
- Locked file / permission issue
  - Stop watch process or editor plugin locking output file

## Agent Behavior Guidelines

- Do not ask permission for basic compile; run with best default path pair
- Prefer existing mapping from `compilerconfig.json` over guessing
- Keep commands explicit and reproducible
- Report the exact command used and output path
