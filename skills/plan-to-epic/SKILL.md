---
name: plan-to-epic
description: Use when you have an implementation plan and want to convert it into structured, trackable work items with dependencies and acceptance criteria.
---

# Plan to Epic Skill

**Trigger patterns**: "plan-to-epic", "convert plan to epic", "create tasks from plan"

**When to use**: When you have an implementation plan document and want to convert it into structured work items with dependencies and acceptance criteria.

## Usage

```bash
/plan-to-epic <path-to-plan.md>
/plan-to-epic path/to/plan.md --design path/to/design.md
```

## Tracking Mode Detection

This skill adapts based on available tools:

### Beads Mode (if `bd` command available and initialized)
To detect: run `bd doctor 2>&1 | grep -q '✓  Installation'` — this works regardless of storage location (`.beads/`, `BEADS_DB` env var, custom `db:` config).
- Creates a beads epic with `bd create --type=epic`
- Creates individual tasks with `bd create --type=task`
- Manages dependencies with `bd dep add`
- Visualizes with `bd tree`

### Fallback Mode (no beads)
- Creates a structured task tracking file at `ai/current/<plan-name>-tasks.md`
- Uses markdown checkboxes with dependency annotations
- Compatible with TodoWrite for session-level tracking
- Tasks can also be tracked via GitHub Issues if `gh` is available

## Process

### 1. Parse Plan Document

Read and extract:
- **Title**: Epic/project name (from plan filename or heading)
- **Architecture**: High-level structure and approach
- **Tasks**: Individual implementation steps
- **Dependencies**: File overlap and logical ordering
- **Acceptance Criteria**: Expected outcomes and verification steps

### 2. Create Work Structure

**With beads:**
```bash
bd create --type=epic --title "<title>" --description "<overview>"
```

**Without beads:**
Create `ai/current/<plan-name>-tasks.md`:
```markdown
# <Title> — Task Tracking

Source plan: `<plan-path>`
Created: <date>

## Tasks

### Phase 1: [Name]

- [ ] **Task 1**: [Title]
  - Dependencies: none
  - Files: `path/to/file.ext`
  - Acceptance: [criteria]

- [ ] **Task 2**: [Title]
  - Dependencies: Task 1
  - Files: `path/to/other.ext`
  - Acceptance: [criteria]

### Phase 2: [Name]
...
```

### 3. Create Tasks

For each task in the plan, capture these three fields:

1. **Description**: Implementation steps and code snippets
   - Concrete steps to complete the task
   - Code examples where helpful
   - Technical details from the plan

2. **Design**: Architecture context and decisions
   - Why this approach was chosen
   - How it fits into the overall architecture
   - Integration points with other components

3. **Acceptance Criteria**:
   - Specific, verifiable outcomes
   - Testing requirements
   - Verification commands

**With beads:**
```bash
bd create --type=task \
  --parent <epic-id> \
  --title "<title>" \
  --json '{
    "description": "...",
    "design": "...",
    "notes": "From <plan-path>, section N",
    "acceptance": "...",
    "metadata": {
      "predicted_files": ["src/path/to/file.ts", "tests/path/to/file.test.ts"]
    }
  }'
```

**Without beads:**
Add each task as a structured markdown entry in the tasks file.

### 4. Infer Dependencies

Analyze file overlap to automatically infer dependencies:
- Tasks modifying the same files should be ordered
- Backend tasks before frontend tasks (usually)
- Database migrations before code that uses them
- Shared components before features that use them

The `predicted_files` metadata is also used by autonomous-executor to verify file-disjointness when dispatching tasks in parallel. Tasks with overlapping predicted files will be serialized rather than run concurrently.

**With beads:** `bd dep add <child-id> <parent-id>`
**Without beads:** Note dependencies in markdown: `Dependencies: Task 1, Task 3`

### 5. Validate Structure

After creation:
- **With beads:** Run `bd tree <epic-id>` to visualize structure
- **Without beads:** Review the task file for completeness
- Check for circular dependencies
- Verify all tasks are linked
- Ensure acceptance criteria are clear

## Task Sizing

Good tasks are:
- **2-5 minutes** of focused work
- **One action** per step (one file change, one test, one migration)
- **Independently verifiable** — can be tested in isolation
- **TDD-ready** — can write a failing test first, then implement

## Output

After successful conversion, present:
- Epic/project ID or file path
- List of created tasks with IDs
- Dependency graph visualization
- Command to execute:
  - **With beads:** `/epic-executor <epic-id>`
  - **Without beads:** `/implement_plan <plan-path>`

## Unified Workflow

This skill is Stage 4 of the unified engineering pipeline:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```
