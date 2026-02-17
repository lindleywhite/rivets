# Rivets

Small pieces holding big structures together. A structured engineering workflow plugin for Claude Code.

Takes implementation work from research through validation with autonomous sub-agents, verification gates, and persistent tracking.

## What It Does

Provides a complete engineering pipeline:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> [/epic-executor OR /autonomous-executor] -> /validate_plan
```

| Stage | What Happens |
|-------|-------------|
| **Research** | 6 specialized sub-agents investigate your codebase in parallel |
| **Plan** | Interactive plan creation with YAML frontmatter and checkboxes |
| **Audit** | Health check on active plans — flags stale, done, orphaned |
| **Structure** | Converts plans into trackable work items with dependencies |
| **Execute** | Choose execution mode: supervised (epic-executor) or autonomous (autonomous-executor) |
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
- **epic-executor** — Supervised task execution with verification gates
- **autonomous-executor** — Fully autonomous execution (runs for hours/days without supervision)

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

## Execution Modes

Rivets provides two complementary execution modes:

### Supervised Execution (/epic-executor)
- **Interactive** - User monitors progress in real-time
- **Single session** - Completes in one sitting
- **Full control** - User can intervene anytime
- **Best for**: Learning, exploration, rapid iteration, complex tasks with unknowns

### Autonomous Execution (/autonomous-executor)
- **Background operation** - Runs for hours/days without supervision
- **Two-phase polling** - Cheap model checks every 5 minutes, expensive model only when work ready
- **Cost optimized** - ~$2-5/hour vs ~$50-100/hour for continuous supervised
- **Best for**: Known work, overnight execution, batch processing, long epics

**Cost Comparison**:
| Mode | Model Usage | Cost | Supervision |
|------|-------------|------|-------------|
| Supervised | Continuous Opus 4.6 | ~$50-100/hr | Full |
| Autonomous | Sonnet 4 polling + Opus work | ~$2-5/hr | None |

**Choose based on context**:
- Unknown scope → Start supervised, switch to autonomous once approach clear
- Long epic → Autonomous for sustained execution
- Learning new codebase → Supervised for interaction
- Batch of similar tasks → Autonomous for efficiency

## Decision Guide

| Scenario | Workflow |
|----------|----------|
| Multi-day feature | Full pipeline: research -> plan -> audit -> epic -> **autonomous-executor** |
| Known bug fix | Direct implementation + verification gate |
| Unclear scope | brainstorming -> create_plan -> full pipeline with **epic-executor** |
| Quick change | Direct implementation, verification gate only |
| Existing plan | audit-plans -> plan-to-epic -> **epic-executor** (try first) |
| Long epic (>10 tasks) | plan-to-epic -> **autonomous-executor** (overnight/weekend execution) |
| Learning new codebase | Use **epic-executor** for visibility and interaction |
| Batch similar tasks | **autonomous-executor** for cost efficiency |

## Companion Plugins

Rivets works well alongside:
- **[Superpowers](https://github.com/obra/superpowers)** — TDD, systematic debugging, code review, git worktrees
- **[Beads](https://github.com/steveyegge/beads)** — Persistent issue tracking (used by epic-executor when available)

## License

MIT
