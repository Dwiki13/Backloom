---
name: writing-plans
description: "Write implementation plans: bite-sized tasks, paths, code."
version: 1.1.0
author: Hermes Agent (adapted from obra/superpowers)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [planning, design, implementation, workflow, documentation]
    related_skills: [subagent-driven-development, test-driven-development, requesting-code-review]
---

# Writing Implementation Plans

## Overview

Write comprehensive implementation plans assuming the implementer has zero context for the codebase and questionable taste. Document everything they need: which files to touch, complete code, testing commands, docs to check, how to verify. Give them bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume the implementer is a skilled developer but knows almost nothing about the toolset or problem domain. Assume they don't know good test design very well.

**Core principle:** A good plan makes implementation obvious. If someone has to guess, the plan is incomplete.

## When to Use

**Always use before:**
- Implementing multi-step features
- Breaking down complex requirements
- Delegating to subagents via subagent-driven-development

**Don't skip when:**
- Feature seems simple (assumptions cause bugs)
- You plan to implement it yourself (future you needs guidance)
- Working alone (documentation matters)

## Bite-Sized Task Granularity

**Each task = 2-5 minutes of focused work.**

Every step is one action:
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

**Too big:**
```markdown
### Task 1: Build authentication system
[50 lines of code across 5 files]
```

**Right size:**
```markdown
### Task 1: Create User model with email field
[10 lines, 1 file]

### Task 2: Add password hash field to User
[8 lines, 1 file]

### Task 3: Create password hashing utility
[15 lines, 1 file]
```

## Plan Document Structure

### Header (Required)

Every plan MUST start with:

```markdown
# [Feature Name] Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### Task Structure

Each task follows this format:

````markdown
### Task N: [Descriptive Name]

**Objective:** What this task accomplishes (one sentence)

**Files:**
- Create: `exact/path/to/new_file.py`
- Modify: `exact/path/to/existing.py:45-67` (line numbers if known)
- Test: `tests/path/to/test_file.py`

**Step 1: Write failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify failure**

Run: `pytest tests/path/test.py::test_specific_behavior -v`
Expected: FAIL — "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify pass**

Run: `pytest tests/path/test.py::test_specific_behavior -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Writing Process

### Step 1: Understand Requirements

Read and understand:
- Feature requirements
- Design documents or user description
- Acceptance criteria
- Constraints

### Step 2: Explore the Codebase

Use Hermes tools to understand the project:

```python
# Understand project structure
search_files("*.py", target="files", path="src/")

# Look at similar features
search_files("similar_pattern", path="src/", file_glob="*.py")

# Check existing tests
search_files("*.py", target="files", path="tests/")

# Read key files
read_file("src/app.py")
```

### Step 3: Design Approach

Decide:
- Architecture pattern
- File organization
- Dependencies needed
- Testing strategy

### Step 4: Write Tasks

Create tasks in order:
1. Setup/infrastructure
2. Core functionality (TDD for each)
3. Edge cases
4. Integration
5. Cleanup/documentation

### Step 5: Add Complete Details

For each task, include:
- **Exact file paths** (not "the config file" but `src/config/settings.py`)
- **Complete code examples** (not "add validation" but the actual code)
- **Exact commands** with expected output
- **Verification steps** that prove the task works

### Step 6: Review the Plan

Check:
- [ ] Tasks are sequential and logical
- [ ] Each task is bite-sized (2-5 min)
- [ ] File paths are exact
- [ ] Code examples are complete (copy-pasteable)
- [ ] Commands are exact with expected output
- [ ] No missing context
- [ ] DRY, YAGNI, TDD principles applied
- [ ] State verification included (check existing state before making changes)
- [ ] Concise communication preference respected
- [ ] Manual fix verification included when applicable
- [ ] No manual cron triggers recommended
- [ ] Correct delivery channels specified

### Step 7: Save the Plan

```bash
mkdir -p .hermes/plans
# Save plan to .hermes/plans/YYYY-MM-DD-feature-name.md
```

**Note:** Save plans to `.hermes/plans/` (gitignored), NOT to the project root as `plan.md`. KII explicitly deletes `plan.md` from project dirs — plans in the project root get stale and clutter the repo. The `.hermes/` directory is the canonical location.

## Principles

### DRY (Don't Repeat Yourself)

**Bad:** Copy-paste validation in 3 places
**Good:** Extract validation function, use everywhere

### YAGNI (You Aren't Gonna Need It)

**Bad:** Add "flexibility" for future requirements
**Good:** Implement only what's needed now

```python
# Bad — YAGNI violation
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
        self.preferences = {}  # Not needed yet!
        self.metadata = {}     # Not needed yet!

# Good — YAGNI
class User:
    def __init__(self, name, email):
        self.name = name
        self.email = email
```

### TDD (Test-Driven Development)

Every task that produces code should include the full TDD cycle:
1. Write failing test
2. Run to verify failure
3. Write minimal code
4. Run to verify pass

See `test-driven-development` skill for details.

### Frequent Commits

Commit after every task:
```bash
git add [files]
git commit -m "type: description"
```

## Common Mistakes

### Negative Testing Before Design Doc

**Bad:** Jumping straight to design doc or implementation plan without considering failure modes first.

**Good:** When building a tool or product, ALWAYS run negative testing BEFORE writing the design doc. Use negative testing findings to shape the architecture — design for resilience, not just functionality.

**When:** Any tool/product design session — especially for AI agents, APIs, connectors, or anything with external dependencies.

**Negative Testing Categories (adapt to your domain):**

1. **Engine/Core Failures** — What happens when the core logic breaks? (timeouts, invalid input, resource exhaustion, dependency down)
2. **Connector/Integration Failures** — What happens when external services fail? (API down, rate limit, invalid response, authentication expiry)
3. **Data Layer Failures** — What happens when storage breaks? (disk full, corruption, concurrent write, migration fail)
4. **Auth/Security Failures** — What happens under attack? (brute force, injection, escalation, token theft)
5. **Deployment Failures** — What happens when infrastructure breaks? (port conflict, OOM, SSL expiry, DNS fail)
6. **Concurrency Failures** — What happens under load? (race conditions, deadlocks, resource contention)
7. **UX Edge Cases** — What happens when users do unexpected things? (delete mid-task, input garbage, go offline)

**Process:**
1. Brainstorm failure modes for each category (aim for 5-10 per category)
2. For each failure: define expected behavior (graceful degradation > crash)
3. Use findings to shape design doc — every critical failure mode MUST have a design response
4. Reference: negative testing for an AI agent starter kit is in `references/agentkit-negative-testing.md`

**From session (June 2026):** KII explicitly asked for negative testing before design doc for AgentKit. 81 test cases across 8 categories were generated. This pattern should be standard for all tool builds.

### Skipping DESIGN.md for UI Projects

**Bad:** Jumping straight to implementation plan for a project with user-facing UI (mobile app, web app) without first creating a `DESIGN.md`.

**Good:** When the project involves screens, user flows, or visual design, create `DESIGN.md` FIRST before the implementation plan. The DESIGN.md should cover:
- Color palette (hex codes)
- Typography (font families, sizes)
- Screen-by-screen layout description
- Navigation structure
- Component library / design system
- Style references (apps with similar aesthetic)

The implementation plan references DESIGN.md for UI decisions. Without it, subagents will guess at visual details and produce inconsistent output.

**Trigger:** User says "bikin app", "bikin mobile apps", "bikin website", or any project with UI.

### Plan File Too Large for Single Write

**Bad:** Writing a 80K+ character plan file in a single `write_file` call — it will be truncated or fail.

**Good:** For large plans, split into phase-based files:
- `docs/plans/phase-1-setup.md`
- `docs/plans/phase-2-backend.md`
- `docs/plans/phase-3-mobile.md`
- `docs/plans/phase-4-launch.md`

Or keep the master plan concise (under ~15K chars) and put detailed task breakdowns in separate phase files. Each phase file should be independently executable by a subagent.

### Skipping Next.js Version-Specific Checks

**Bad:** Copy-pasting middleware.ts from a Next.js 14/15 tutorial into Next.js 16.
**Good:** Always read `node_modules/next/dist/docs/` for the current version's file conventions. In Next.js 16, `middleware.ts` is renamed to `proxy.ts` — the export must be a named `proxy` function. See `references/nextjs16-supabase-gotchas.md` for full details.

### Vague Tasks

**Bad:** "Add authentication"
**Good:** "Create User model with email and password_hash fields"

### Incomplete Code

**Bad:** "Step 1: Add validation function"
**Good:** "Step 1: Add validation function" followed by the complete function code

### Missing Verification

**Bad:** "Step 3: Test it works"
**Good:** "Step 3: Run `pytest tests/test_auth.py -v`, expected: 3 passed"

### Missing File Paths

**Bad:** "Create the model file"
**Good:** "Create: `src/models/user.py`"

## Execution Handoff

After saving the plan, offer the execution approach:

**"Plan complete and saved. Ready to execute using subagent-driven-development — I'll dispatch a fresh subagent per task with two-stage review (spec compliance then code quality). Shall I proceed?"**

When executing, use the `subagent-driven-development` skill:
- Fresh `delegate_task` per task with full context
- Spec compliance review after each task
- Code quality review after spec passes
- Proceed only when both reviews approve

## Remember

``` 
Bite-sized tasks (2-5 min each)
Exact file paths
Complete code (copy-pasteable)
Exact commands with expected output
Verification steps
DRY, YAGNI, TDD
Frequent commits
```

### Additional Principles Learned from Session

#### Check State First (Cek Dulu Aja)

**Bad:** Making changes without inspecting existing state  
**Good:** Always verify current state before making any modifications  
- Run `git diff` to see existing changes before modifying  
- Inspect current configuration, database state, or file contents  
- Never assume state - always verify  
- If user says "cek dulu aja", only inspect - never modify  

#### Concise Communication  

**Bad:** Verbose explanations, excessive abstraction, unnecessary details  
**Good:** Direct, concise responses with concrete examples  
- Prefer terminal commands over lengthy explanations  
- Use examples rather than abstract descriptions  
- Get to the point quickly - KII prefers direct communication  
- Avoid phrases like "just to clarify" or "it's important to note"  

#### Verify After Manual Fixes  

**Bad:** Assuming manual fixes work without verification  
**Good:** Always verify after manual intervention  
- After user makes manual fixes: run `git diff` to see changes  
- Test to verify the fix works correctly  
- Only commit/push if explicitly asked after verification  
- Never assume manual fixes are correct without testing  

#### No Manual Cron Triggers  

**Bad:** Manually triggering cron jobs that should run automatically  
**Good:** Let automated systems run on their schedule  
- Manual triggers cause double signals and data corruption  
- Never manually run cron jobs unless explicitly instructed  
- Trust automated schedules for signal generation and reporting  

#### Correct Delivery Channels  

**Bad:** Sending messages to wrong topics/chats  
**Good:** Always use specified delivery targets  
- KII prefers signals delivered to Topic Trading (telegram:-1003966561389:334)  
- Cron job delivery should be "local" with explicit send_message in prompt  
- Do NOT use telegram:1724161158:334 (that's KII's DM chat, not group topic)  
- Verify delivery target before sending automated messages

#### KII's Execution Flow: Plan → OpenCode → Review

After saving the plan, KII's workflow is:
1. Save plan to `.hermes/plans/YYYY-MM-DD-feature-name.md`
2. Execute using OpenCode CLI (not direct coding): `/root/.opencode/bin/opencode run`
3. After OpenCode finishes: review changed files, run tests, commit
4. KII does NOT use subagent-driven-development for backend work — OpenCode is the coding agent

#### Alembic Verify Before Feature Work

**Bad:** Building new features before verifying DB schema is clean
**Good:** Always run Alembic verify (database audit) before starting new feature work:
- Check migration chain is clean (no orphans, correct head)
- Compare Python model columns vs PostgreSQL columns (nullable, types)
- Verify FK cascade rules match expectations
- Check enum values match between Python and DB
- Report discrepancies but don't modify without user approval

**When:** Before any feature that modifies DB schema or adds new tables/columns
