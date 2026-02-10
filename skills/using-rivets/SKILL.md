---
name: using-rivets
description: Introduction to the Rivets structured engineering workflow system. Loaded automatically at session start.
---

# Using Rivets

You have access to Rivets — a structured engineering workflow that guides implementation from research through validation. This skill teaches you how to use it.

## Available Skills

These skills trigger automatically based on context, or can be invoked explicitly:

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `rivets:brainstorming` | Before creative/feature work | Explore requirements and design before implementation |
| `rivets:audit-plans` | "audit plans", "check plans" | Health check on `ai/current/` plans |
| `rivets:plan-to-epic` | "convert plan to epic" | Convert plan into trackable work items |
| `rivets:epic-executor` | "execute epic", "run tasks" | Autonomous task execution with verification |

## Available Commands

Invoke these with `/command-name`:

| Command | Purpose |
|---------|---------|
| `/research_codebase` | Deep codebase investigation with 6 specialized sub-agents |
| `/create_plan` | Interactive plan creation in `ai/current/` |
| `/implement_plan` | Direct plan implementation with verification |
| `/validate_plan` | Verify implementation matches plan |

## Available Agents

Use these as `subagent_type` with the Task tool:

| Agent | When to Use |
|-------|------------|
| `codebase-locator` | Find WHERE files and components live |
| `codebase-analyzer` | Understand HOW specific code works |
| `codebase-pattern-finder` | Find similar implementations to model after |
| `ai-locator` | Discover relevant AI documentation |
| `ai-analyzer` | Deep dive on specific AI documents |
| `web-search-researcher` | Research external documentation and resources |

## The Pipeline

The full workflow flows through these stages:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```

Not every task needs the full pipeline. See the decision guide:

| Scenario | Workflow |
|----------|----------|
| Multi-day feature | Full pipeline |
| Known bug fix | Direct implementation + verification gate |
| Unclear scope | Start with brainstorming -> create_plan -> full pipeline |
| Quick one-off | Direct implementation, verification gate only |
| Existing plan | audit-plans -> plan-to-epic -> epic-executor |

## Tracking Modes

The workflow automatically adapts based on what's available:

- **With beads** (`bd` command available and initialized): Full persistent tracking with epics, dependencies, and cross-session context
- **Without beads**: Markdown-based task tracking in `ai/current/`, TodoWrite for session tracking

## Directory Structure

The workflow uses this directory convention (create if needed):

```
ai/
├── current/      # Active implementation plans
├── completed/    # Archived completed plans
├── research/     # Research documents
├── reference/    # Architectural patterns and guides
└── templates/    # Document templates
```

## Key Principles

1. **5-Step Verification Gate**: IDENTIFY -> RUN -> READ -> VERIFY -> CLAIM. Never skip steps.
2. **Two-Stage Review**: Spec compliance first, then code quality.
3. **YAGNI**: Implement only what's in the plan. File issues for everything else.
4. **Fresh Context**: Each task gets a new subagent. No context pollution.
5. **Incremental Commits**: Commit after each verified task.

## When to Use Skills

- **Before building anything new**: Use `rivets:brainstorming` to explore the design
- **Before implementing a plan**: Use `rivets:plan-to-epic` to structure the work
- **To check plan health**: Use `rivets:audit-plans` periodically
- **To execute structured work**: Use `rivets:epic-executor` for autonomous execution

For the full workflow guide, see `references/unified-workflow-guide.md` in this plugin.
