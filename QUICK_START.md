# Quick Start Guide: OpenCode Orchestrator

Get started with the orchestration system in 5 minutes.

## Installation

The orchestration agents should already be in place:
```
~/.config/opencode/agent/
├── orchestrator.md
├── worker-code.md
├── worker-research.md
├── worker-validate.md
└── worker-fix.md
```

If not, they need to be copied there.

## Basic Usage

### 1. Simple Task (Direct Worker)

For a single, clear task, use a worker directly:

```
@worker-code Create a user login endpoint with JWT authentication
```

The worker will:
- Implement the endpoint
- Return structured status
- Summarize what was done

**Expected output**:
```markdown
Created POST /login endpoint in src/api/auth.ts.

## Status: success
## Result
Login endpoint with JWT token generation implemented.
## Changes Made
- src/api/auth.ts: Added login endpoint
- src/auth/jwt.ts: Created token utilities
## Next Steps
- [ ] Add refresh token support
## Context Summary for Orchestrator
Login endpoint working with 24h JWT tokens. Ready for refresh token implementation.
```

### 2. Complex Task (Use Orchestrator)

For multi-part features, use the orchestrator:

```
@orchestrator Add user authentication, registration, and password reset
```

The orchestrator will:
1. Analyze the task
2. Break it into independent units
3. Show you the execution plan
4. Execute in parallel batches
5. Handle failures automatically
6. Provide final summary

**Expected output**:
```markdown
## Task Analysis

**Goal**: Add complete auth system with registration, login, and password reset

**Work Streams Identified**:
1. Registration flow (backend + frontend)
2. Login flow (backend + frontend)
3. Password reset (backend + frontend + email)
4. Database schema (users, sessions, reset tokens)

**Dependency Mapping**:
- Registration: INDEPENDENT
- Login: INDEPENDENT
- Password reset: DEPENDS on database schema
- Database schema: INDEPENDENT

**Execution Plan**:

**Batch 1 (Parallel)** - 4 tasks, estimated 8 min:
  - Implement registration endpoint (worker-code)
  - Create registration form (worker-code)
  - Design user database schema (worker-code)
  - Research password reset patterns (worker-research)

**Batch 2 (Sequential)** - 2 tasks, estimated 5 min:
  - Implement login endpoint (worker-code)
  - Create login form (worker-code)

**Batch 3 (Sequential)** - 2 tasks, estimated 6 min:
  - Implement password reset flow (worker-code)
  - Create reset UI (worker-code)

**Batch 4 (Sequential)** - 1 task, estimated 3 min:
  - End-to-end validation (worker-validate)

**Total Estimated Time**: 22 minutes (vs 60 minutes sequential)

Ready to execute. Should I proceed? [Y/n]
```

## Real-World Examples

### Example 1: Add Payment Integration

```
@orchestrator Integrate Stripe payment processing with checkout flow
```

**Orchestrator plan**:
```
Batch 1 (Parallel):
  - @worker-research: Find existing payment patterns in codebase
  - @worker-code: Set up Stripe SDK configuration
  - @worker-code: Create payment intent endpoint

Batch 2 (Sequential):
  - @worker-code: Build checkout UI with Stripe Elements
  - @worker-code: Implement webhook handler

Batch 3 (Sequential):
  - @worker-validate: Test payment flow end-to-end
  - @worker-fix: Fix any issues found
```

### Example 2: Refactor API Layer

```
@orchestrator Refactor API layer to use new ORM and add error handling
```

**Orchestrator plan**:
```
Batch 1 (Parallel):
  - @worker-research: Analyze current API structure
  - @worker-code: Install and configure new ORM
  - @worker-code: Create error handling middleware

Batch 2 (Sequential):
  - @worker-code: Migrate users endpoint to new ORM
  - @worker-code: Migrate products endpoint to new ORM

Batch 3 (Sequential):
  - @worker-code: Migrate orders endpoint to new ORM
  - @worker-code: Update all controllers to use error middleware

Batch 4 (Sequential):
  - @worker-validate: Run test suite
  - @worker-validate: Check for regressions
  - @worker-fix: Fix any failing tests
```

### Example 3: Add Testing Suite

```
@orchestrator Add comprehensive testing for user authentication module
```

**Orchestrator plan**:
```
Batch 1 (Parallel):
  - @worker-research: Analyze auth module structure
  - @worker-code: Set up test framework (Jest/Vitest)
  - @worker-code: Create test utilities and mocks

Batch 2 (Sequential):
  - @worker-code: Write unit tests for registration
  - @worker-code: Write unit tests for login

Batch 3 (Sequential):
  - @worker-code: Write integration tests for auth flow
  - @worker-validate: Run all tests and check coverage

Batch 4 (Sequential):
  - @worker-fix: Fix any failing tests or low coverage
```

## Common Workflows

### Debug and Fix Workflow

When validation finds issues:

```bash
# Step 1: Validate implementation
@worker-validate Test the new user registration flow

# If it fails, Step 2: Fix issues
@worker-fix Fix the SQL injection vulnerability in registration endpoint

# Step 3: Re-validate
@worker-validate Re-run tests for registration flow
```

### Research and Implement Workflow

When adding a new feature:

```bash
# Step 1: Research existing patterns
@worker-research Find how authentication is currently implemented

# Step 2: Implement based on research
@worker-code Implement OAuth integration following existing auth patterns

# Step 3: Validate
@worker-validate Test OAuth login flow

# Step 4: Fix any issues
@worker-fix Fix token expiration handling issue
```

### Multi-Agent Workflow

When orchestrator delegates to different agents:

```bash
# Orchestrator manages everything
@orchestrator Add user profiles, social login, and email notifications

# Orchestration behind the scenes:
# Batch 1:
#   @worker-research: Social login patterns
#   @worker-code: Profile database schema
#   @worker-code: Email service setup
#
# Batch 2:
#   @worker-code: Social login implementation
#   @worker-code: Profile CRUD operations
#
# Batch 3:
#   @worker-code: Email notification integration
#   @worker-validate: End-to-end testing
#
# Batch 4:
#   @worker-fix: Fix any issues
```

## Tips for Best Results

### 1. Be Specific About Requirements

❌ **Vague**:
```
@orchestrator Add authentication
```

✅ **Specific**:
```
@orchestrator Add JWT authentication with email registration, login,
password reset, and remember-me functionality. Use bcrypt for
password hashing, 24-hour token expiration, and refresh tokens.
```

### 2. Provide Context When Helpful

```
@orchestrator Add a payment gateway. We already use Stripe for other
payments, so use the same Stripe account. The checkout page is
in src/checkout/page.tsx. Follow the existing order creation pattern.
```

### 3. Let Orchestrator Break It Down

❌ **Too prescriptive**:
```
@orchestrator First implement auth backend in server/auth.ts,
then create frontend forms in components/auth/, then add tests,
then validate, then fix issues.
```

✅ **Let orchestrator plan**:
```
@orchestrator Add complete authentication system with backend,
frontend forms, and comprehensive tests.
```

### 4. Review the Plan

When orchestrator shows the execution plan, review it:
- Are the dependencies correct?
- Should any tasks be done differently?
- Is anything missing?

You can modify the plan before execution starts.

## Understanding Structured Status

All workers return status like this:

```markdown
## Status: success|failure|partial|needs_input
```

- **success**: Task completed fully
- **failure**: Cannot complete as specified (needs different approach)
- **partial**: Mostly done, some parts remain
- **needs_input**: Need clarification or decision

The **Context Summary** section is critical for orchestrator - it provides concise information for the next batch.

## When NOT to Use Orchestrator

Use regular agents for:

❌ **Too small**:
```
@orchestrator Fix this typo in the README
```

✅ **Better**:
```
Fix the typo in line 5 of README.md
```

❌ **Single file**:
```
@orchestrator Update the config file
```

✅ **Better**:
```
@worker-code Add new environment variable to .env.example
```

❌ **Question**:
```
@orchestrator How does JWT authentication work?
```

✅ **Better**:
```
@worker-research Find and explain the JWT implementation
```

## Troubleshooting

### Issue: Workers don't return structured status

**Solution**: Verify worker agent files are correct:
- YAML frontmatter present
- Instructions include structured status format
- Workers are in the right directory

### Issue: Everything runs sequentially

**Solution**:
- Check if tasks are truly independent
- Orchestrator is conservative
- Try breaking down requirements more explicitly

### Issue: Context window still full

**Solution**:
- Check if summaries are being generated
- Reduce task complexity
- Break into multiple orchestrator sessions

### Issue: Tasks keep failing

**Solution**:
- Orchestrator retries 3 times automatically
- After 3 failures, it asks for help
- Provide clarification or different requirements

## Next Steps

1. **Try a simple task**:
   ```
   @worker-code Create a simple API endpoint
   ```

2. **Try a complex task**:
   ```
   @orchestrator Add user management with CRUD operations
   ```

3. **Review the output**:
   - Check structured status format
   - Look at context summaries
   - Understand the batching

4. **Experiment with workflows**:
   - Combine workers manually
   - Use orchestrator for multi-part tasks
   - See how parallelization saves time

## Getting Help

- Read the full documentation: `ORCHESTRATION_README.md`
- Join the community: https://discord.gg/opencode
- Report issues: https://github.com/anomalyco/opencode/issues

Happy orchestrating! 🚀
