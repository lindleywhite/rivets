# Unified Engineering Workflow Guide

**Purpose:** Single canonical reference for how implementation work flows through this plugin. All skills and commands point here.

## The Pipeline

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```

| Stage | Tool | Purpose |
|-------|------|---------|
| 1. Research | `/research_codebase` | Deep investigation with 6 specialized sub-agents |
| 2. Plan | `/create_plan` | Produce plan in `ai/current/` with YAML frontmatter + checkboxes |
| 3. Audit | `/audit-plans` | Health check on `ai/current/` — classify, archive, triage |
| 4. Structure | `/plan-to-epic` | Convert plan into trackable work items with dependencies |
| 5. Execute | `/epic-executor` | Autonomous task execution with fresh sub-agents |
| 6. Validate | `/validate_plan` | Verify implementation correctness post-execution |

## Tracking Modes

This workflow supports two tracking backends:

### Beads Mode (recommended for multi-session work)
When the [beads](https://github.com/steveyegge/beads) issue tracker is installed:
- Persistent tracking across sessions and context compaction
- Dependency management between tasks
- Epic grouping and tree visualization
- Automatic sync with git

### File Mode (works everywhere)
When beads is not available:
- Markdown-based task tracking in `ai/current/<plan>-tasks.md`
- Checkbox-based progress tracking
- TodoWrite for session-level execution
- Compatible with any project

The workflow skills automatically detect which mode to use.

## Core Principles

### Research-Driven Planning
- **6 specialized sub-agents** for codebase research (patterns, architecture, testing, etc.)
- **Plans in `ai/current/`** with YAML frontmatter and checkbox tracking
- **Autonomous execution** via epic-executor with two-stage review

### Verification-First Execution
- **Fresh context per task** — new sub-agent per task, no context pollution
- **5-step verification gate** — every task completion must pass: IDENTIFY -> RUN -> READ -> VERIFY -> CLAIM
- **Two-stage review** — spec compliance first, then code quality
- **YAGNI** — implement only what's in the plan; file issues for everything else
- **Bite-sized tasks** — 2-5 minutes each, one action per step

## 5-Step Verification Gate

Before claiming ANY task is complete, you MUST execute these steps in order:

1. **IDENTIFY** — State the specific verification command or check needed
2. **RUN** — Execute the verification (test, build, lint, manual check)
3. **READ** — Read the full output, don't skim or assume
4. **VERIFY** — Confirm the output proves the task is done (not just "no errors")
5. **CLAIM** — Only now mark the task as complete

```
# Example
IDENTIFY: Run the auth handler tests to verify the new endpoint
RUN: go test -v ./internal/handlers/ -run TestAuthHandler
READ: [read full output]
VERIFY: TestAuthHandler_GetToken PASS, TestAuthHandler_RefreshToken PASS
CLAIM: Task complete
```

**If any step fails, DO NOT proceed to the next step.** Fix the issue and restart from step 1.

## Two-Stage Review

Applied during `/epic-executor` task completion:

### Stage 1: Spec Compliance
- Does the implementation meet acceptance criteria?
- Are all required features present?
- Does it match design decisions?
- Are edge cases handled?

### Stage 2: Code Quality
Only after Stage 1 passes:
- Code quality and maintainability
- Security (OWASP top 10)
- Performance concerns
- Test coverage

## Decision Guide: When to Use What

| Scenario | Workflow |
|----------|----------|
| Multi-day feature | Full pipeline: research -> plan -> audit -> epic -> execute -> validate |
| Known bug fix | Direct implementation with 5-step verification gate |
| Unclear scope | Start with `/brainstorming`, then -> `/create_plan` -> full pipeline |
| Quick one-off change | Direct implementation, verification gate only |
| Existing plan needs execution | `/audit-plans` -> `/plan-to-epic` -> `/epic-executor` |
| Session start / context recovery | `/audit-plans` to see what's active and what needs attention |

## Plan Lifecycle

```
ai/current/           ->  structured work  ->  implemented  ->  ai/completed/
(planning/in-progress)    (beads or file)     (validated)      (archived)
```

1. Plans are created in `ai/current/` with YAML frontmatter
2. `/audit-plans` monitors health — flags stale, done, orphaned plans
3. `/plan-to-epic` converts ready plans into structured work items
4. `/epic-executor` runs tasks with fresh sub-agents + verification gates
5. `/validate_plan` confirms implementation correctness
6. Completed plans are archived to `ai/completed/`

## YAGNI Enforcement

During execution, if you discover:
- Technical debt -> file an issue (beads or follow-up list), continue current task
- Out-of-scope improvement -> file an issue, continue current task
- Missing feature -> file an issue, continue current task
- Bug in existing code -> file an issue, continue current task

**Never expand scope mid-task.** The plan defines the work. Everything else is a future issue.

## Task Sizing

Good tasks are:
- **2-5 minutes** of focused work
- **One action** per step (one file change, one test, one migration)
- **Independently verifiable** — can be tested in isolation
- **TDD-ready** — can write a failing test first, then implement

Bad tasks are:
- "Implement the entire feature" (too large)
- "Refactor and add tests and update docs" (multiple actions)
- "Make it work" (not verifiable)

## Setup for New Projects

To use this workflow in a new project:

1. **Install the plugin** (see README)
2. **Create the ai/ directory structure:**
   ```bash
   mkdir -p ai/{current,completed,research,reference,templates}
   ```
3. **Optionally install beads** for persistent tracking:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/install.sh | bash
   bd init
   ```
4. Start with `/research_codebase` or `/brainstorming`

## File References

| File | Purpose |
|------|---------|
| `skills/audit-plans/SKILL.md` | Plan health auditing |
| `skills/brainstorming/SKILL.md` | Idea exploration and design |
| `skills/epic-executor/SKILL.md` | Autonomous task execution |
| `skills/plan-to-epic/SKILL.md` | Plan -> work item conversion |
| `commands/create_plan.md` | Plan creation |
| `commands/validate_plan.md` | Post-implementation verification |
| `commands/implement_plan.md` | Direct plan implementation |
| `commands/research_codebase.md` | Deep codebase research |
