---
name: epic-executor
description: Use when you have structured work items (beads epic or task tracking file) ready to execute autonomously. Handles sequential task execution with two-stage code review, incremental commits, verification gates, and knowledge capture.
---

# Epic Executor Skill v2

**Trigger patterns**: "epic-executor", "execute epic", "run epic", "execute tasks"

**When to use**: When you have structured work items ready to execute autonomously. This skill handles sequential task execution with two-stage code review, incremental commits, living plan updates, phase boundary reviews, and knowledge capture.

## Usage

```bash
# With beads
/epic-executor <epic-id>
/epic-executor bd-a1b2c3 --resume
/epic-executor bd-a1b2c3 --dry-run
/epic-executor bd-a1b2c3 --tasks bd-g7h8i9,bd-j0k1l2

# Without beads (task tracking file)
/epic-executor ai/current/<plan-name>-tasks.md
/epic-executor ai/current/<plan-name>-tasks.md --resume
```

## Tracking Mode Detection

At startup, detect which tracking mode to use:

**Beads mode**: If argument looks like a beads ID (e.g., `bd-a1b2c3`) AND `bd` command is available
**File mode**: If argument is a file path to a task tracking markdown file

All phases below describe both modes. Use the one that matches your environment.

---

## Phase Overview

| Phase | Name | Purpose |
|-------|------|---------|
| 0 | **Validate & Clarify** | Read tasks, assess risk, get user approval |
| 1 | **Execute** | Core loop: dispatch, review, verify, commit, repeat |
| 2 | **Review** | Phase boundary checkpoints |
| 3 | **Verify** | Full suite verification, commit history review |
| 4 | **Ship** | Close work, create PR, capture knowledge, archive plan |

---

## Phase 0: Validate & Clarify

Before touching any code, understand the full scope and get explicit user approval.

### 0.1 Read All Tasks

**Beads mode:**
```bash
bd show <epic-id>
bd tree <epic-id>
# Then for each task:
bd show <task-id>
```

**File mode:**
Read the task tracking file completely. Parse all tasks, their dependencies, and acceptance criteria.

### 0.2 Locate Source Plan

Find and read the source plan document referenced by the epic/task file. Check:
- Epic description/notes for plan path (typically `ai/current/*.md`)
- `ai/current/` directory for matching plan files

Read the full plan to understand architectural decisions, constraints, and implementation order.

### 0.3 Risk Assessment

Scan task titles, descriptions, and keywords. Flag tasks as HIGH risk if they contain:

| Keyword Pattern | Risk Category |
|----------------|---------------|
| `migration`, `schema`, `alter table` | Data integrity |
| `auth`, `session`, `token`, `password`, `rbac` | Security |
| `delete`, `drop`, `remove`, `destroy` | Destructive |
| `deploy`, `infrastructure`, `helm` | Operational |
| `payment`, `billing`, `stripe` | Financial |

### 0.4 Present Summary & Get Approval

```
Epic: <title> (<id or file>)
Tasks: <count> total, <ready> ready, <blocked> blocked
Source Plan: <path>

Risk Flags:
  - HIGH: <task> "<title>" — <risk category>

Proposed execution order:
  1. <task>: <title>
  2. <task>: <title>
  ...

Proceed? (waiting for user confirmation)
```

**Do NOT proceed to Phase 1 until the user explicitly approves.**

### 0.5 Record Base State

```bash
git rev-parse HEAD > /tmp/epic-base-sha.txt
```

---

## Phase 1: Execute

The core execution loop. For each task: dispatch, review, verify, commit, update plan, report.

### 1.1 Get Next Ready Task

**Beads mode:**
```bash
bd ready
```
Select first ready task from the epic. If no tasks ready, check `bd blocked`.

**File mode:**
Scan the task file for the first unchecked task whose dependencies are all checked.

### 1.2 Subagent Preamble Template

Every subagent receives this standard preamble:

```
## Standard Instructions

1. Read CLAUDE.md first for project conventions, commands, and architecture
2. Read existing code in the area you're modifying BEFORE writing anything
3. Follow existing patterns — match naming, structure, error handling, and test patterns
   from adjacent files. Reuse existing components/utilities rather than creating new ones
4. Focus ONLY on this task — do not refactor surrounding code, add features not requested,
   or "improve" things outside scope. If you discover issues, note them but do not fix them
5. Do NOT commit — leave changes staged or unstaged. The orchestrator handles commits
6. Run tests after implementation to verify your work
7. Keep it simple — implement the minimum needed to satisfy acceptance criteria
```

### 1.3 Dispatch Fresh Subagent

**CRITICAL**: Launch a NEW subagent for each task to prevent context pollution.

Use the Task tool with `subagent_type: "general-purpose"`. Provide:
- Preamble from 1.2
- Task title, description, design context, acceptance criteria
- Current state (relevant git status, recent changes)

**Context isolation rule**: Never tell the subagent about other tasks. It should only know about its own task.

### 1.4 Two-Stage Review

After subagent completes:

#### Stage 1: Spec Compliance Review
- Does implementation meet every acceptance criterion?
- Are all required features present?
- Does it match the design decisions from the plan?

If spec review fails: dispatch a fix subagent with review feedback, re-run spec review.

#### Stage 2: Domain-Specific Quality Review

Only after spec review passes. Focus based on task type:

| Task Type | Review Focus |
|-----------|-------------|
| Migration | Data integrity, reversibility, rollback plan |
| Auth | OWASP top 10, injection, session management |
| Backend | N+1 queries, error handling, transaction boundaries |
| UI | Accessibility, component reuse, responsive behavior |
| **All tasks** | YAGNI violations, unnecessary abstraction, dead code |

If quality review fails: dispatch targeted fix subagent, re-run only the failed stage.

### 1.5 Verification Gate (5-Step)

After both reviews pass. **Never skip steps.**

1. **IDENTIFY** — State the specific verification command(s) needed
2. **RUN** — Execute verification (test, build, lint, type-check)
3. **READ** — Read the FULL output. Do not skim or truncate
4. **VERIFY** — Confirm the output *proves* the task is done
5. **CLAIM** — Only now mark the task as complete

If ANY step fails: **stop**. Fix and restart from step 1.

### 1.6 Incremental Commit

After verification passes:

- Stage specific files only. **Never use `git add .` or `git add -A`**
- Use conventional commit format:

```bash
git add <specific-files>
git commit -m "$(cat <<'EOF'
feat(module): description of change

Implements [specific thing]. Includes [test/validation details].

Task: <task-id or task-title>
EOF
)"
```

- Prefixes: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `migration`

### 1.7 Living Plan Update

After closing a task, update the source plan document:
- Find the corresponding `- [ ]` checkbox
- Update to `- [x]`

### 1.8 Progress Reporting

```
[3/19] <task> closed (Backend — Repository Layer). Next: <next-task> "Title"
```

### 1.9 Close Task

**Beads mode:**
```bash
bd close <task-id>
```

**File mode:**
Check off the task in the task tracking file: `- [x] **Task N**: ...`

### 1.10 Loop

Return to 1.1. Continue until all tasks are closed or a hard blocker is encountered.

---

## Phase 2: Review — Phase Boundary Checkpoints

Phase boundaries occur when:
- All tasks in a dependency layer are complete
- There's a domain shift (e.g., backend complete, moving to frontend)
- A natural grouping finishes

### 2.1 Full Build & Test at Boundary

Run the complete verification suite. If anything fails: **hard stop**. Fix before continuing.

### 2.2 Record Boundary

```bash
git rev-parse HEAD > /tmp/epic-boundary-sha.txt
```

---

## Phase 3: Verify

When all tasks are closed, run final verification.

### 3.1 Full Test Suite

All project tests, builds, type checks, and linting must pass. No exceptions.

### 3.2 Commit History Review

```bash
git log --oneline $(cat /tmp/epic-base-sha.txt)..HEAD
```

Check for: no WIP commits, proper conventional messages, atomic commits, task references.

### 3.3 Competing Hypotheses (Debug Failures)

If verification fails **2+ times** on the same issue, spawn 3 debug subagents in parallel with different hypotheses. Compare findings, apply the strongest fix.

---

## Phase 4: Ship

All tasks closed, all tests passing.

### 4.1 Close Epic & Sync

**Beads mode:**
```bash
bd close <epic-id>
bd sync
```

**File mode:**
Update the task tracking file header to show completion. Commit the final state.

### 4.2 Summary Report

```
Epic Complete: <title>

Tasks: <completed>/<total> completed
Commits: <count> (<base-sha>..<head-sha>)
Follow-ups filed: <count>

Test Results:
  Backend: PASS
  Build: PASS
  TypeCheck: PASS
  Lint: PASS
```

### 4.3 PR Creation Flow

Offer to create a pull request:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Changes
<key changes by domain>

## Testing
- [ ] All tests pass
- [ ] Build succeeds
- [ ] Type checking passes

## Commit Range
`<base-sha>..<head-sha>`
EOF
)"
```

### 4.4 Knowledge Capture

Reflect on the execution:
1. Recurring patterns that worked well?
2. Repeated failures or surprising blockers?
3. Plan gaps that required mid-execution adjustments?
4. New conventions or patterns established?

If the project has a MEMORY.md or similar, capture lessons there.

### 4.5 Plan Archival

Move the source plan from `ai/current/` to `ai/completed/`:
1. Update frontmatter status to `completed`
2. Move file to `ai/completed/`

---

## Key Principles

### Context Isolation
**Never carry context between tasks.** Each gets a fresh subagent.

### YAGNI (You Aren't Gonna Need It)
**Implement only what's in the plan.** When you discover extra work:

**With beads:** File a beads issue, continue current task.
**Without beads:** Note it in a `## Follow-up Items` section of the task file, continue current task.

**Never expand scope mid-task.**

### Evidence-Based Completion
**Never close a task without verification.** Both review stages must pass, tests must pass, changes must be committed.

### Sequential by Default
**Default to one task at a time.** Parallel execution only for truly independent tasks with no shared files.

### Incremental Commits
**Commit after each verified task.** Easy to bisect, clear attribution, reviewable units.

### Living Plan
**Update the source plan as tasks complete.** The plan stays useful as documentation.

---

## Error Handling

| Failure Count | Action |
|--------------|--------|
| 1st | Analyze error, retry with more context |
| 2nd | File an issue for the blocker, try a third time with constraints |
| 3rd | **Competing hypotheses**: 3 debug subagents in parallel |
| 4th | **Hard stop**. Mark task blocked, report to user, move to next ready task |

---

## Advanced Features

### Resume Capability
```bash
/epic-executor <id-or-file> --resume
```
- Reads current state (closed tasks in beads, or checked items in file)
- Skips completed tasks
- Resumes from next ready task

### Dry Run Mode
```bash
/epic-executor <id-or-file> --dry-run
```
- Shows execution order, blockers, risk flags, phase boundaries
- No code changes, no commits

---

## Dependencies

This skill requires:
- Git repository with clean working tree
- Project build/test commands configured
- Source plan document accessible
- **Optional**: Beads (`bd` command) for persistent issue tracking
- **Optional**: GitHub CLI (`gh`) for PR creation

---

## Unified Workflow

This skill is Stage 5 of the unified engineering pipeline:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```
