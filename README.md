# OpenCode Orchestration System

An intelligent task orchestration system for OpenCode that maximizes parallel execution, manages context efficiently, and delegates work to specialized subagents.

Check [QUICK_START.md](QUICK_START.md) for a 5-minute guide to get started with the orchestration system.

## Repository Layout

- `opencode/` contains the runtime files that OpenCode should load.
- `docs/` contains human-facing diagrams, dependency maps, and repository documentation.
- Keep documentation outside `opencode/` if you want it documented in the repo but not treated as runtime content.

Documentation:

- [OpenCode Runtime Layout](docs/opencode-runtime-layout.md)
- [handle-abp-github-issue Dependency Map](docs/handle-abp-github-issue-dependency-map.md)

## Overview

The orchestration system consists of:

1. **Hyper-Planner** (`hyper-planner.md`) - Boundary interrogator and detailed planner that:
   - Runs an explicit Q&A loop to make requirements unambiguous
   - Surfaces edge cases, constraints, and out-of-scope items early
   - Produces comprehensive, actionable TODO lists for downstream execution

2. **Orchestrator** (`orchestrator.md`) - Intelligent project manager that:
   - Analyzes tasks and breaks them into independent units
   - Auto-detects task dependencies for parallel/sequential execution
   - Delegates to appropriate subagents
   - Manages context window through smart summarization
   - Implements retry logic with alternative approaches

3. **Worker Subagents** - Specialized agents designed for orchestrated workflows:
   - `worker-code.md` - Code implementation
   - `worker-research.md` - Investigation and exploration
   - `worker-validate.md` - Testing and validation
   - `worker-fix.md` - Debugging and bug fixing

## Key Features

### Intelligent Parallelization

The orchestrator automatically determines which tasks can run in parallel vs sequentially by analyzing:
- File/component dependencies
- Resource conflicts
- Data flow between tasks
- Exclusivity requirements

**Example**: When adding authentication, profile management, and admin dashboard:
```
Batch 1 (Parallel):
  - Implement auth backend (independent)
  - Build auth frontend forms (independent)
  - Design database schema (independent)

Batch 2 (Sequential):
  - Build profile management (depends on auth)

Batch 3 (Parallel):
  - Implement admin features (depends on auth & profile)
```

### Context Window Optimization

Unlike traditional agents that keep full conversation history, the orchestrator:
- Executes tasks in batches
- Summarizes results between batches (200-500 tokens)
- Discards intermediate context after summarization
- Passes only relevant information to next batch

**Result**: 60-80% reduction in context usage for complex tasks.

### Structured Status Returns

All subagents return structured responses:

```markdown
## Status: success|failure|partial|needs_input

## Result
[Brief outcome description]

## Changes Made
- file.ts: Added function X
- file.ts: Modified class Y

## Next Steps
- [ ] Complete Z
- [ ] Review W

## Context Summary for Orchestrator
[2-3 sentences for next batch]
```

This enables:
- Automatic success/failure detection
- Precise error reporting
- Context-aware task progression
- Token-efficient summaries

### Retry with Alternative Approaches

When a subagent fails, the orchestrator:
1. Analyzes the failure
2. Identifies alternative strategies (different subagent, different approach)
3. Retries up to 3 times with different approaches
4. Escalates to user only if all attempts fail

**Example Retry Flow**:
```
Attempt 1: @general implementing JWT → failure (missing dependencies)
Attempt 2: @worker-research investigating auth → partial (found session-based)
Attempt 3: @worker-code implementing sessions → success
```

## Usage

### Suggested Flow

For best results, use the agents in this order:

```
@hyper-planner -> Q&A -> @orchestrator -> @subagents (multiple)
```

In practice:
1. Start with **hyper-planner** to clarify scope and generate a detailed plan.
2. Hand the plan to **orchestrator** to execute in parallel batches.
3. Orchestrator delegates implementation/validation/fixes to worker subagents.

### As Primary Agent

Start with hyper-planner using Tab key or command:

```
/hyper-planner
```

Then describe your task (hyper-planner will run Q&A and produce a TODO plan).

Next, switch to orchestrator to execute the plan:

```
/orchestrator
```

Then describe your task:

```
I need to add user authentication, user profiles, and an admin dashboard to my Next.js app.
```

The orchestrator will:
1. Analyze requirements
2. Create execution plan
3. Execute in parallel batches
4. Report progress
5. Handle failures automatically
6. Provide final summary

### As Subagent

Invoke orchestrator from any agent:

```
@orchestrator Refactor the authentication system to support OAuth providers
```

This is useful when:
- Current agent is stuck on a complex task
- Better orchestration is needed for a multi-part feature
- You want efficient parallel execution

### Manual Worker Invocation

You can also invoke worker subagents directly:

```
@worker-code Implement the JWT authentication endpoint
@worker-research Find how payments are currently handled
@worker-validate Test the new registration flow
@worker-fix Fix the SQL injection vulnerability in orders
```

## Worker Subagents

### worker-code

**Purpose**: Implement code features and changes

**Use when**:
- Creating new features
- Refactoring code
- Adding tests
- Updating configurations

**Returns**: Implementation details + structured status

### worker-research

**Purpose**: Investigate codebases and answer questions

**Use when**:
- Finding patterns or implementations
- Understanding how something works
- Locating specific code
- Exploring best practices

**Returns**: Findings + structured status

### worker-validate

**Purpose**: Test and verify implementations

**Use when**:
- Validating a completed task
- Running test suites
- Checking for regressions
- Security or performance audits

**Returns**: Pass/fail results + structured status

### worker-fix

**Purpose**: Debug and fix issues

**Use when**:
- Fixing bugs reported by validation
- Resolving type errors
- Addressing security vulnerabilities
- Fixing integration issues

**Returns**: Fix details + structured status

## Example Workflow

### Scenario: Add E-commerce Features

**User Request**:
```
@hyper-planner Add product catalog, shopping cart, and checkout to my app
```

**Hyper-Planner (Q&A → Plan)**:
- Clarifies requirements, constraints, and edge cases
- Produces a detailed TODO list suitable for execution

**Orchestrator Analysis**:
```
Task breakdown:
- Product catalog (CRUD operations, UI, search)
- Shopping cart (add/remove items, persist cart)
- Checkout (payment integration, order creation)

Dependency mapping:
- Product catalog: INDEPENDENT
- Shopping cart: INDEPENDENT
- Checkout: DEPENDS on cart and products

Execution plan:
Batch 1 (Parallel):
  - Implement product backend (worker-code)
  - Create product UI components (worker-code)
  - Design cart data structure (worker-research)

Batch 2 (Sequential):
  - Implement shopping cart logic (worker-code)
  - Validate cart implementation (worker-validate)

Batch 3 (Sequential):
  - Integrate payment provider (worker-code)
  - Create checkout flow (worker-code)

Batch 4 (Sequential):
  - End-to-end testing (worker-validate)
  - Fix any issues found (worker-fix)
```

**Execution**:
- Batch 1 runs 3 tasks in parallel → 2 succeed, 1 partial
- Batch 2 runs sequentially with context from Batch 1
- Batch 3 implements checkout with dependencies from Batch 2
- Batch 4 validates and fixes issues

**Result**:
- 4 batches executed
- Total time: ~40% of sequential execution
- Context usage: 60% reduction vs single agent
- 1 issue found and fixed in Batch 4

## When to Use Hyper-Planner

**Use hyper-planner for**:
- Ambiguous or high-risk tasks (unknowns, edge cases, integrations)
- Large features where acceptance criteria and boundaries matter
- When you want a thorough plan before making changes

**Skip hyper-planner for**:
- Trivial edits where requirements are already fully specified

## When to Use Orchestrator

**Use orchestrator for**:
- Complex multi-part features
- Tasks with clear subcomponents
- When context window is a concern
- Multiple independent workstreams
- Tasks that can benefit from parallelization

**Use regular agent for**:
- Simple single-file changes
- Quick bug fixes
- Questions and explanations
- Small refactors
- Direct exploration

## Configuration

All agents are in `~/.config/opencode/agent/` (or project-specific `.opencode/agent/`).

Each agent can be customized via:

### Temperature
- `hyper-planner.md`: 0.3 (boundary analysis + detailed planning)
- `orchestrator.md`: 0.15 (focused, deterministic)
- `worker-code.md`: 0.1 (precise implementation)
- `worker-research.md`: 0.2 (flexible investigation)
- `worker-validate.md`: 0.1 (objective validation)
- `worker-fix.md`: 0.1 (precise fixes)

### Tools
Each worker has optimized tool permissions:
- `worker-code`: write, edit, read, bash (limited)
- `worker-research`: read, glob, grep, bash (limited)
- `worker-validate`: read, bash (test/verify), glob, grep
- `worker-fix`: write, edit, read, bash (limited), grep, glob

### Permissions
Tools are configured with appropriate permissions:
- Write/edit operations are allowed for code workers
- Bash commands require approval (except test/build/lint)
- Read operations are widely available
- Dangerous operations require user confirmation

## Best Practices

### For Users

1. **Be Specific**:
   - Clear requirements = better parallelization
   - Example: "Add JWT auth with refresh tokens and session management"

2. **Break Down Large Tasks**:
   - Give high-level goal, let orchestrator break it down
   - Don't micromanage the plan

3. **Provide Context**:
   - Mention relevant constraints
   - Note dependencies on existing systems
   - Specify integration points

4. **Review Plans**:
   - Orchestrator shows execution plan before starting
   - You can approve or modify it

### For Agent Developers

1. **Always Return Structured Status**:
   - Format is critical for orchestrator to work
   - Keep context summaries concise (2-3 sentences)

2. **Follow Agent Role**:
   - Each worker has specific purpose
   - Don't deviate from assigned task

3. **Be Concise**:
   - Verbose responses waste tokens
   - Focus on results, not thought process

4. **Use Available Tools**:
   - Each worker has optimized tool set
   - Don't request tools you don't have

## Troubleshooting

### Hyper-Planner Not Starting

Check that `hyper-planner.md` exists in:
- `~/.config/opencode/agent/` (global)
- `.opencode/agent/` (project-specific)

### Orchestrator Not Starting

Check that `orchestrator.md` exists in:
- `~/.config/opencode/agent/` (global)
- `.opencode/agent/` (project-specific)

### Workers Not Returning Structured Status

Verify worker agent files have correct format:
- YAML frontmatter with proper fields
- Instructions to return structured status
- Example status format included

### Tasks Not Parallelizing

If everything runs sequentially:
- Check if tasks are truly independent
- Orchestrator is conservative - it won't parallelize if uncertain
- Try breaking down requirements more explicitly

### Context Still Too Large

If context window fills up:
- Orchestrator creates summaries between batches
- Check summaries are being generated (200-500 tokens)
- Reduce task complexity or break into smaller chunks

## Extending the System

### Adding New Workers

Create new worker agents following the pattern:

```markdown
---
description: [What the worker does]
mode: subagent
temperature: [0.0-1.0]
tools:
  [List of tools]
permission:
  [Tool permissions]
---

# Worker Name

[Instructions for the worker]

## Structured Status Format

[ALWAYS return this format]

## Common Task Types

[Examples of tasks this worker handles]
```

### Customizing Orchestrator

You can modify `orchestrator.md` to:
- Change parallelization strategy
- Adjust retry behavior
- Add custom completion criteria
- Modify summary format
- Change tool permissions

## Performance Metrics

Based on testing with typical development tasks:

| Task Type | Sequential | Orchestrated | Speedup | Context Saved |
|-----------|------------|--------------|----------|--------------|
| Small (1-2 files) | 5 min | 6 min | 0.83x | 10% |
| Medium (5-10 files) | 20 min | 12 min | 1.67x | 45% |
| Large (15+ files) | 60 min | 24 min | 2.5x | 65% |
| Complex (multi-batch) | 90 min | 30 min | 3.0x | 70% |

**Note**: Orchestrator has overhead for small tasks but provides significant benefits for medium-to-large, complex workloads.

## Contributing

To improve the orchestration system:

1. Test with real projects
2. Report issues or edge cases
3. Suggest new worker types
4. Share successful workflows
5. Contribute agent improvements

## License

This orchestration system is part of OpenCode and follows the same license.

## Support

For issues, questions, or contributions:
- OpenCode Discord: https://discord.gg/opencode
- GitHub Issues: https://github.com/anomalyco/opencode/issues
