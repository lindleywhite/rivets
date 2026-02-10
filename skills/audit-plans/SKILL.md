---
name: audit-plans
description: Use when you need to assess the health and status of implementation plans in ai/current/. Identifies completed plans that should be archived, stale plans that need attention, and orphaned plans with no tracking.
---

# Audit Plans Skill

**Trigger patterns**: "audit-plans", "audit plans", "check plans", "plan health"

**When to use**: When you need to assess the health and status of implementation plans in `ai/current/`. Identifies completed plans that should be archived, stale plans that need attention, and orphaned plans with no tracking.

## Usage

```bash
/audit-plans              # Quick mode (default)
/audit-plans --thorough   # Cross-reference issue tracker + git history
```

## Modes

### Quick Mode (default)

Parse all plans in `ai/current/` and classify them:

1. **Run the parse helper script** to gather frontmatter and checkbox data:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$(dirname $(dirname $0))}/skills/audit-plans/scripts/parse_plan_frontmatter.sh"
   ```
   If the script isn't available, manually scan `ai/current/*.md` files for frontmatter and checkboxes.

2. **Classify each plan** using this logic:

   | Status | Criteria |
   |--------|----------|
   | DONE | Frontmatter `status` is `implemented`, `completed`, or `closed`; OR 100% checkboxes checked |
   | IN-PROGRESS | Mix of checked/unchecked checkboxes, or `phase-N-completed` / partial status |
   | STALE | Would be IN-PROGRESS but plan date is >60 days old with no recent git activity on the file |
   | NEVER-STARTED | Status is `planning` with zero checked checkboxes (or no checkboxes at all) |

3. **Output a summary table** grouped by classification:

   ```
   ## Plan Health Report

   ### DONE (ready to archive)
   | Plan | Status | Checkboxes | Date |
   |------|--------|------------|------|
   | quick-entry-line-items | completed | 12/12 (100%) | 2025-12-26 |

   ### IN-PROGRESS
   | Plan | Status | Checkboxes | Date |
   |------|--------|------------|------|
   | auth-waterfall-optimization | planning | 3/8 (38%) | 2026-01-24 |

   ### STALE (>60 days, no recent git activity)
   | Plan | Status | Checkboxes | Last Git Activity |
   |------|--------|------------|-------------------|

   ### NEVER-STARTED
   | Plan | Status | Date |
   |------|--------|------|
   ```

### Thorough Mode (`--thorough`)

Everything from Quick mode, plus:

1. **Cross-reference issue tracker**:

   **If beads is available:**
   ```bash
   bd list --status=open | grep -i "<plan-keywords>"
   bd list --status=in_progress | grep -i "<plan-keywords>"
   ```

   **If beads is not available:**
   - Check for GitHub issues via `gh issue list` if available
   - Search git log for commits referencing the plan
   - Flag plans with no external tracking as "orphaned"

2. **Add cross-reference column** to the output table:
   ```
   | Plan | Status | Checkboxes | Tracker Issue | Last Activity |
   ```

## Actions Offered After Report

After displaying the report, offer these actions:

1. **Archive DONE plans**: Move completed plans to `ai/completed/`
   ```bash
   mv ai/current/<plan> ai/completed/
   ```

2. **Update stale plan statuses**: Set frontmatter status to `stale` for flagged plans

3. **Convert orphaned plans to tracked work**:

   **With beads**: "Shall I run /plan-to-epic on any of these orphaned plans?"
   **Without beads**: "Shall I create a task list for any of these plans?"

4. **Deep-verify a specific plan**: "Shall I run /validate_plan on a specific plan?"

## Classification Details

### Frontmatter Parsing

Plans may use YAML frontmatter (between `---` delimiters) or inline key-value pairs.

**YAML frontmatter fields to extract:**
- `status` — primary classification signal
- `date` — plan creation date
- `completed_date` — when the plan was finished
- `owner` — who owns the plan
- `tags` — for keyword matching
- `merged_pr` — indicates completion

### Checkbox Counting

Count all markdown checkboxes in the plan:
- Checked: `- [x]` or `- [X]`
- Unchecked: `- [ ]`
- Percentage: `checked / total * 100`

Plans with no checkboxes rely solely on frontmatter `status` for classification.

## Key Principles

- **Non-destructive by default**: Report only; actions require explicit user approval
- **Quick mode is fast**: No git or tracker lookups, just file parsing
- **Thorough mode is comprehensive**: Full cross-referencing for session planning
- **Actionable output**: Every classification suggests a next step

## Relationship to Unified Workflow

This skill is Stage 3 of the unified engineering workflow:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```

Use `/audit-plans` regularly to keep `ai/current/` healthy and ensure plans flow through the pipeline.
