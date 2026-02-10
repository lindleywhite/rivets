# Rivets

Small pieces holding big structures together. A structured engineering workflow plugin for Claude Code.

Takes implementation work from research through validation with autonomous sub-agents, verification gates, and persistent tracking.

## What It Does

Provides a complete engineering pipeline:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```

| Stage | What Happens |
|-------|-------------|
| **Research** | 6 specialized sub-agents investigate your codebase in parallel |
| **Plan** | Interactive plan creation with YAML frontmatter and checkboxes |
| **Audit** | Health check on active plans — flags stale, done, orphaned |
| **Structure** | Converts plans into trackable work items with dependencies |
| **Execute** | Autonomous task execution with fresh sub-agents per task, two-stage code review, 5-step verification gate |
| **Validate** | Verifies implementation matches the plan |

## Installation

### Via Plugin Marketplace (when available)

```bash
# In Claude Code:
/plugin marketplace add lindleywhite/rivets-marketplace
/plugin install rivets@rivets-marketplace
```

### Manual Installation

Clone and register as a local plugin:

```bash
git clone https://github.com/lindleywhite/rivets.git ~/.claude/plugins/rivets
```

Then in your Claude Code settings, add the plugin path.

## Requirements

- **Claude Code** — the CLI tool from Anthropic
- **Git** — for commit tracking and history

### Optional (but recommended)

- **[Beads](https://github.com/steveyegge/beads)** — Git-backed issue tracker for persistent multi-session tracking
  ```bash
  curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/install.sh | bash
  bd init  # in your project
  ```
- **GitHub CLI** (`gh`) — for PR creation and issue cross-referencing
- **[Superpowers](https://github.com/obra/superpowers)** — complementary plugin for TDD, debugging, and code review skills

## Project Setup

After installing the plugin, set up the directory structure in your project:

```bash
mkdir -p ai/{current,completed,research,reference,templates}
```

Optionally copy the templates:
```bash
cp ~/.claude/plugins/rivets/templates/* ai/templates/
```

## What's Included

### Skills (auto-trigger based on context)
- **brainstorming** — Explore requirements and design before implementation
- **audit-plans** — Health check on `ai/current/` plans
- **plan-to-epic** — Convert plans into structured work items
- **epic-executor** — Autonomous task execution with verification gates

### Commands (invoke with `/command`)
- `/research_codebase` — Deep codebase investigation
- `/create_plan` — Interactive plan creation
- `/implement_plan` — Direct plan implementation
- `/validate_plan` — Post-implementation verification

### Agents (specialized sub-agents)
- **codebase-locator** — Find where files and components live
- **codebase-analyzer** — Understand how specific code works
- **codebase-pattern-finder** — Find similar implementations to model after
- **ai-locator** — Discover relevant AI documentation
- **ai-analyzer** — Deep dive on AI documents
- **web-search-researcher** — Research external documentation

### Templates
- Implementation plan template
- Analysis template
- Task list template

## Tracking Modes

Rivets automatically adapts based on what's available:

### With Beads (recommended for multi-session work)
- Persistent tracking across sessions and context compaction
- Dependency management between tasks
- Epic grouping and tree visualization
- Automatic sync with git

### Without Beads (works everywhere)
- Markdown-based task tracking in `ai/current/`
- Checkbox progress tracking
- TodoWrite for session-level execution
- Zero additional dependencies

## Key Concepts

### 5-Step Verification Gate
Every task must pass before being marked complete:
1. **IDENTIFY** — State the verification command needed
2. **RUN** — Execute it
3. **READ** — Read the full output
4. **VERIFY** — Confirm it proves the task is done
5. **CLAIM** — Only now mark complete

### Two-Stage Review
1. **Spec Compliance** — Does it meet acceptance criteria?
2. **Code Quality** — Security, performance, maintainability (only after spec passes)

### YAGNI Enforcement
During execution, discovered work is filed as issues (beads or follow-up list), never implemented mid-task. The plan defines the scope.

### Context Isolation
Each task gets a fresh sub-agent to prevent context pollution between tasks.

## Decision Guide

| Scenario | Workflow |
|----------|----------|
| Multi-day feature | Full pipeline: research -> plan -> audit -> epic -> execute -> validate |
| Known bug fix | Direct implementation + verification gate |
| Unclear scope | brainstorming -> create_plan -> full pipeline |
| Quick change | Direct implementation, verification gate only |
| Existing plan | audit-plans -> plan-to-epic -> epic-executor |

## Companion Plugins

Rivets works well alongside:
- **[Superpowers](https://github.com/obra/superpowers)** — TDD, systematic debugging, code review, git worktrees
- **[Beads](https://github.com/steveyegge/beads)** — Persistent issue tracking (used by epic-executor when available)

## License

MIT
