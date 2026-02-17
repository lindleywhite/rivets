---
name: autonomous-executor
description: Fully autonomous epic execution with two-phase polling. Launch once, runs for hours/days executing tasks without supervision. Uses cheap polling model to check for work, spawns expensive work model only when needed.
---

# Autonomous Executor Skill

**Trigger patterns**: "autonomous-executor", "run epic autonomously", "start autonomous execution"

**When to use**: When you want epic-executor to run autonomously for hours or days without human supervision. The system will poll for ready tasks, execute them with verification gates, and continue until the epic is complete.

---

## Overview

This skill implements a **two-phase autonomous execution loop**:

1. **Phase 1 - Polling** (Sonnet 4, every 5 minutes): Check for ready tasks
2. **Phase 2 - Work Execution** (Opus 4.6): Execute task when found, then return to polling

**Cost optimization**: ~$0.05/hour for polling, ~$2-5/task for work. Total ~$2-5/hour vs $50-100/hour for continuous supervised execution.

**Duration**: Can run for hours, days, or weeks until epic completes.

---

## Usage

```bash
# Start autonomous execution
/autonomous-executor <epic-id>

# With optional dashboard
/autonomous-executor <epic-id> --dashboard-port 8080

# Resume after stop
/autonomous-executor <epic-id> --resume

# Dry run (show what would happen)
/autonomous-executor <epic-id> --dry-run
```

**Stop execution**:
```bash
# Graceful stop
touch /tmp/autonomous-executor-stop-<epic-id>

# Or add comment to epic
bd comments add <epic-id> "STOP_REQUESTED"

# Or close the epic
bd close <epic-id>
```

---

## Phase 0: Initialization & Approval

### 0.1 Validate Prerequisites

Check that system is ready for autonomous operation:

```bash
# Check epic exists and is open
EPIC_STATUS=$(bd show <epic-id> --json 2>/dev/null | jq -r '.status // "not_found"')
if [[ "$EPIC_STATUS" != "open" ]]; then
  echo "Error: Epic <epic-id> is not open (status: $EPIC_STATUS)"
  exit 1
fi

# Check for ready tasks
READY_COUNT=$(bd ready --parent <epic-id> --json | jq 'length')
if [[ $READY_COUNT -eq 0 ]]; then
  echo "Warning: No ready tasks currently. Will poll until tasks become ready."
fi

# Check git working tree is clean
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working tree is not clean. Commit or stash changes first."
  exit 1
fi

# Check source plan exists (referenced in epic description or notes)
PLAN_PATH=$(bd show <epic-id> --json | jq -r '.description + "\n" + (.notes // "")' | grep -oE 'ai/current/[^[:space:]]+\.md' | head -1)
if [[ -n "$PLAN_PATH" ]] && [[ ! -f "$PLAN_PATH" ]]; then
  echo "Warning: Source plan $PLAN_PATH not found. Execution will continue without plan reference."
fi
```

### 0.2 Load Epic Context

```bash
# Get epic details
EPIC_JSON=$(bd show <epic-id> --json)
EPIC_TITLE=$(echo "$EPIC_JSON" | jq -r '.title')
EPIC_DESC=$(echo "$EPIC_JSON" | jq -r '.description')
TOTAL_TASKS=$(bd list --parent <epic-id> --json | jq 'length')
READY_TASKS=$(bd ready --parent <epic-id> --json | jq 'length')
BLOCKED_TASKS=$(bd blocked --parent <epic-id> --json | jq 'length')

# Record base state for commit tracking
git rev-parse HEAD > /tmp/autonomous-executor-base-<epic-id>.txt
date -u +%Y-%m-%dT%H:%M:%SZ > /tmp/autonomous-executor-start-<epic-id>.txt
```

### 0.3 Risk Assessment

Scan task titles for high-risk keywords:

```bash
# Check for risky tasks
HIGH_RISK=$(bd list --parent <epic-id> --json | \
  jq -r '.[] | select(
    .title | test("migration|schema|alter table|delete|drop|auth|session|token|password|payment|billing"; "i")
  ) | .id + ": " + .title')

if [[ -n "$HIGH_RISK" ]]; then
  echo "⚠️  High-risk tasks detected:"
  echo "$HIGH_RISK"
fi
```

### 0.4 Present Summary & Get Approval

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTONOMOUS EXECUTION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Epic: <epic-title> (<epic-id>)
Tasks: <total> total, <ready> ready, <blocked> blocked
Source Plan: <path-if-found>

Execution Mode: AUTONOMOUS (no human supervision)
Polling Interval: Every 5 minutes
Cost Model: ~$0.05/hour polling + ~$2-5/task execution

High-Risk Tasks:
<list if any, otherwise "None detected">

Safety Features:
✓ Circuit breaker (stops if >30% tasks fail)
✓ Abandoned task recovery (auto-retry timeouts)
✓ Rate limiting (max 1 task/10 minutes)
✓ Manual stop available anytime

Stop Conditions:
- All tasks complete (epic closes automatically)
- Manual stop: touch /tmp/autonomous-executor-stop-<epic-id>
- Circuit breaker triggered
- Epic closed externally

Monitoring:
- Progress: bd show <epic-id> --thread
- Status: cat /tmp/autonomous-executor-status-<epic-id>.json
<if dashboard: - Dashboard: http://localhost:<port>>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This will run autonomously until complete or stopped.
Proceed? (y/n)
```

**Wait for explicit user approval before continuing.**

### 0.5 Initialize Tracking

If approved:

```bash
# Initialize progress tracking
COMMENT_COUNT=$(bd comments <epic-id> --json 2>/dev/null | jq 'length' || echo 0)
if [[ "$COMMENT_COUNT" -eq 0 ]]; then
  bd comments add <epic-id> "🤖 **Autonomous Execution Started**

Mode: Fully autonomous
Polling interval: 5 minutes
Base commit: $(cat /tmp/autonomous-executor-base-<epic-id>.txt)

Cross-task learning enabled. Ready tasks will be claimed and executed automatically."
fi

# Initialize status file
cat > /tmp/autonomous-executor-status-<epic-id>.json <<EOF
{
  "epic_id": "<epic-id>",
  "status": "initializing",
  "started_at": "$(cat /tmp/autonomous-executor-start-<epic-id>.txt)",
  "base_commit": "$(cat /tmp/autonomous-executor-base-<epic-id>.txt)",
  "total_tasks": $TOTAL_TASKS,
  "completed_tasks": 0,
  "failed_tasks": 0,
  "current_task": null,
  "poll_count": 0,
  "last_activity": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
```

---

## Phase 1: Autonomous Polling Loop

This is the **main coordinator**. It runs in the current session and manages the polling loop.

**Implementation Note**: The bash code below is CONCEPTUAL - it shows the polling pattern and logic. Implement this using the Task tool to spawn polling agents repeatedly, not by literally executing this bash loop.

### 1.1 Polling Loop Pattern

The polling loop follows this pattern:

1. Increment poll count and update status file
2. Check for stop conditions (exit if stop requested)
3. Every 10th poll, run maintenance (cleanup abandoned tasks, check circuit breaker)
4. Spawn a polling agent (Task tool with Sonnet 4) to check for ready work
5. Handle polling result:
   - If `HEARTBEAT_OK`: No work found, sleep 5 minutes, continue
   - If `SPAWNED:<task-id>`: Work agent spawned, wait for completion, enforce rate limiting
6. Repeat until epic complete or stop requested

**Conceptual bash (shows the logic pattern)**:

```bash
POLL_COUNT=0
CONSECUTIVE_NO_WORK=0

while true; do
  POLL_COUNT=$((POLL_COUNT + 1))

  # Update status
  jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --arg count "$POLL_COUNT" \
     '.poll_count = ($count | tonumber) | .last_activity = $ts | .status = "polling"' \
     /tmp/autonomous-executor-status-<epic-id>.json > /tmp/tmp.$$.json && \
     mv /tmp/tmp.$$.json /tmp/autonomous-executor-status-<epic-id>.json

  echo "[$(date '+%H:%M:%S')] Poll #$POLL_COUNT - Checking for work..."

  # Check for stop conditions
  if check_stop_conditions; then
    echo "Stop condition detected. Exiting gracefully..."
    break
  fi

  # Every 10th poll, do maintenance
  if [[ $((POLL_COUNT % 10)) -eq 0 ]]; then
    cleanup_abandoned_tasks
    check_circuit_breaker
  fi

  # Spawn polling agent
  POLL_RESULT=$(spawn_polling_agent)

  if [[ "$POLL_RESULT" == "HEARTBEAT_OK" ]]; then
    CONSECUTIVE_NO_WORK=$((CONSECUTIVE_NO_WORK + 1))
    echo "[$(date '+%H:%M:%S')] No ready tasks. Sleeping 5 minutes..."

    # If no work for 1 hour, post status update
    if [[ $CONSECUTIVE_NO_WORK -eq 12 ]]; then
      bd comments add <epic-id> "⏳ Polling continues - no ready tasks for 1 hour. Still monitoring..."
      CONSECUTIVE_NO_WORK=0
    fi

    sleep 300  # 5 minutes
    continue
  fi

  if [[ "$POLL_RESULT" =~ ^SPAWNED:.+ ]]; then
    CONSECUTIVE_NO_WORK=0
    TASK_ID=$(echo "$POLL_RESULT" | cut -d: -f2 | xargs)
    echo "[$(date '+%H:%M:%S')] Work agent spawned for task: $TASK_ID"

    # Wait for work agent to complete
    wait_for_work_agent "$TASK_ID"

    # Update status
    COMPLETED=$(bd list --parent <epic-id> --status closed --json | jq 'length')
    jq --arg completed "$COMPLETED" \
       '.completed_tasks = ($completed | tonumber) | .current_task = null' \
       /tmp/autonomous-executor-status-<epic-id>.json > /tmp/tmp.$$.json && \
       mv /tmp/tmp.$$.json /tmp/autonomous-executor-status-<epic-id>.json

    # Check for completion
    if check_epic_complete; then
      echo "Epic complete! Initiating shutdown..."
      break
    fi

    # Rate limiting: enforce minimum 10 minutes between tasks
    echo "[$(date '+%H:%M:%S')] Rate limiting: waiting 10 minutes before next task..."
    sleep 600
  fi
done

# Cleanup and final report
shutdown_autonomous_execution
```

### 1.2 Check Stop Conditions

Check for stop signals before each poll. Stop execution if any condition is met:

1. **Stop file exists**: Check for `/tmp/autonomous-executor-stop-<epic-id>`
2. **Stop comment**: Check for "STOP_REQUESTED" in epic comments
3. **Epic closed**: Check if epic status is "closed"

Execute these checks using bash:

```bash
# Check for stop file
test -f /tmp/autonomous-executor-stop-<epic-id>

# Check for STOP_REQUESTED comment
bd comments <epic-id> --json | jq -r '.[] | select(.body | contains("STOP_REQUESTED")) | .id' | tail -1

# Check epic status
bd show <epic-id> --json | jq -r '.status'
```

If any condition is met, exit the polling loop gracefully.

### 1.3 Cleanup Abandoned Tasks

Run maintenance every 10th poll to find and recover abandoned tasks.

**Abandoned task detection**: Tasks stuck in `in_progress` status for >35 minutes (likely from crashed work agents).

**Recovery process**:

1. Find abandoned tasks using bash:
   ```bash
   bd list --parent <epic-id> --status in_progress --json | \
     jq --arg threshold "$(date -u -d '35 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
     'map(select(.updated_at < $threshold)) | .[].id'
   ```

2. For each abandoned task:
   - Get abandon count: `bd show "$task_id" --json | jq -r '.metadata.abandon_count // 0'`
   - Increment abandon count
   - If abandoned ≥5 times:
     - Mark blocked: `bd update "$task_id" blocked`
     - Add comment explaining why
     - Update failed task count in status file
   - Otherwise:
     - Reset to open: `bd update "$task_id" open`
     - Update abandon count metadata
     - Add comment: "Task reset to open (abandon X/5)"

This ensures transient failures don't permanently block progress, but persistent failures are caught.

### 1.4 Circuit Breaker Check

Run safety check every 10th poll to detect systemic failures.

**Circuit breaker logic**: If >30% of tasks are blocked, stop execution to prevent wasting resources on a broken epic.

**Implementation**:

1. Calculate failure rate using bash:
   ```bash
   FAILED_COUNT=$(bd list --parent <epic-id> --status blocked --json | jq 'length')
   TOTAL=$(bd list --parent <epic-id> --json | jq 'length')
   FAILURE_RATE=$(echo "scale=2; $FAILED_COUNT / $TOTAL" | bc)
   ```

2. If failure rate >0.3 (30%):
   - Add comment to epic: "Circuit Breaker Triggered - >30% tasks blocked"

$FAILED_COUNT of $TOTAL tasks are blocked (>30% failure rate).
Autonomous execution stopped. Manual intervention required.

Failed tasks: bd list --parent <epic-id> --status blocked"

    # Update status and trigger stop
    jq '.status = "circuit_breaker_triggered"' \
       /tmp/autonomous-executor-status-<epic-id>.json > /tmp/tmp.$$.json && \
       mv /tmp/tmp.$$.json /tmp/autonomous-executor-status-<epic-id>.json

    touch /tmp/autonomous-executor-stop-<epic-id>
    return 0
  fi

  return 1
}
```

### 1.5 Check Epic Complete

Check if all tasks in the epic are complete (none are open, in_progress, or blocked).

Execute this bash command:
```bash
bd list --parent <epic-id> --status open,in_progress,blocked --json | jq 'length'
```

If the count is 0, the epic is complete. Initiate shutdown.

---

## Phase 2: Polling Agent (Cheap Model)

This agent is spawned every 5 minutes by the polling loop using the Task tool.

### 2.1 Spawn Polling Agent

Use the Task tool to spawn a polling agent with these parameters:
- `subagent_type`: "general-purpose"
- `model`: "sonnet" (cheap model for quick checks)
- `description`: "Check for ready tasks"
- `prompt`: The polling agent prompt template (see 2.2 below)

Parse the polling agent's response:
- If response contains "HEARTBEAT_OK": Return "HEARTBEAT_OK" (no work)
- If response contains "SPAWNED:": Extract and return the task ID
- Otherwise: Handle as error

**Conceptual bash (shows the logic)**:

```bash
function spawn_polling_agent() {
  # Use Task tool with cheap model
  # (This is pseudocode showing the pattern)

  RESULT=$(Task tool with:
    subagent_type: "general-purpose"
    model: "claude-sonnet-4"  # Cheap model
    description: "Check for ready tasks"
    prompt: "$(build_polling_prompt)"
  )

  # Parse result
  if [[ "$RESULT" == *"HEARTBEAT_OK"* ]]; then
    echo "HEARTBEAT_OK"
  elif [[ "$RESULT" == *"SPAWNED:"* ]]; then
    echo "$RESULT"
  else
    echo "ERROR: Unexpected polling result"
  fi
}
```

### 2.2 Polling Agent Prompt Template

```markdown
You are an autonomous polling agent for epic <epic-id>.

**Your sole job**: Check if there is work ready, and spawn a work agent if yes.

## Step 1: Check for Ready Work

Run this command:
```bash
bd ready --parent <epic-id> --json
```

## Step 2: Decision Logic

**Case A: Output is empty array `[]`**
- Reply exactly: "HEARTBEAT_OK - No ready tasks"
- Do NOT spawn any agents
- Exit immediately

**Case B: Output contains tasks (non-empty array)**
- Extract first ready task from JSON
- You MUST spawn a work agent using `sessions_spawn` tool
- Do NOT attempt to do the work yourself

## Step 3: Spawn Work Agent (if work found)

Call `sessions_spawn` with these exact parameters:
- agentId: "autonomous-executor-worker-<epic-id>"
- model: "claude-opus-4-6"
- task: The COMPLETE work prompt below + the task JSON you received

**Work Prompt to Include**:
---START WORK PROMPT---
{WORK_PROMPT_TEMPLATE}
---END WORK PROMPT---

After the work prompt, add:
---START CLAIMED TASK---
{JSON output from bd ready command}
---END CLAIMED TASK---

Reply: "SPAWNED: <task-id>"

## Critical Rules

1. Keep this session SHORT (<30 seconds)
2. You are the cheap checker, not the worker
3. Only spawn ONE work agent per poll
4. Do NOT read files, do NOT analyze code
5. Your ONLY job: check bd ready → spawn if work exists

## Examples

**Example 1: No work**
```bash
$ bd ready --parent bd-epic-123 --json
[]
```
Your reply: "HEARTBEAT_OK - No ready tasks"

**Example 2: Work found**
```bash
$ bd ready --parent bd-epic-123 --json
[{"id":"bd-task-456","title":"Create auth endpoint",...}]
```
Your actions:
1. Call sessions_spawn with work prompt + task JSON
2. Reply: "SPAWNED: bd-task-456"
```

---

## Phase 3: Work Agent (Expensive Model)

This agent is spawned by the polling agent when work exists. The prompt below is passed to the work agent subagent.

**Implementation Note**: Use the Task tool to spawn the work agent with:
- `subagent_type`: Selected specialist (or "general-purpose")
- `model`: "opus" (expensive model for implementation)
- `description`: "Execute task <task-id>"
- `prompt`: The template below

### 3.1 Work Agent Prompt Template

**This is the prompt text you pass to the subagent**:

```markdown
You are an autonomous work agent. Execute ONE task from epic <epic-id>, then exit.

The polling agent will handle the next task. Your job: do this ONE task completely.

## Claimed Task JSON

The polling agent provided this task:
---START CLAIMED TASK---
{CLAIMED_TASK_JSON}
---END CLAIMED TASK---

## Step 1: Parse Task JSON

```bash
TASK_JSON='<json from above>'
TASK_ID=$(echo "$TASK_JSON" | jq -r '.[0].id')
TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.[0].title')
TASK_DESC=$(echo "$TASK_JSON" | jq -r '.[0].description')
TASK_ACCEPTANCE=$(echo "$TASK_JSON" | jq -r '.[0].acceptance_criteria // ""')

echo "Claimed: $TASK_ID - $TASK_TITLE"
```

## Step 2: Claim Task Atomically

```bash
# Mark as in_progress
bd update "$TASK_ID" in_progress

# Verify claim succeeded (another agent might have claimed it)
CLAIMED_STATUS=$(bd show "$TASK_ID" --json | jq -r '.status')
if [[ "$CLAIMED_STATUS" != "in_progress" ]]; then
  echo "Task was claimed by another agent. Exiting."
  exit 0
fi
```

## Step 3: Load Context

```bash
# Get full task details
FULL_TASK=$(bd show "$TASK_ID" --json)
DESIGN=$(echo "$FULL_TASK" | jq -r '.design // ""')

# Load learning thread (last 5 completed tasks)
LEARNING_THREAD=$(bd comments <epic-id> --json | \
  jq -r 'sort_by(.created_at) | reverse | limit(5; .[]) |
  "[\(.created_at | split("T")[0])] \(.body)\n---\n"')

# Check for previous review feedback
REVIEW_FEEDBACK=$(echo "$FULL_TASK" | jq -r '.metadata.review_feedback // ""')
```

## Step 4: Select Specialist Agent

Analyze the task title and description to select the appropriate specialist agent. Match keywords in order of specificity:

### High-Risk Specialists (check first)

**Migration Specialist** - If task mentions:
- Keywords: `migration`, `schema`, `alter table`, `database`, `add column`, `drop column`, `create table`, `index`, `constraint`, `foreign key`, `rollback`
- Agent path: `agents/epic-executor/migration-specialist.md`
- Risk level: HIGH

**Security Specialist** - If task mentions:
- Keywords: `auth`, `authentication`, `authorization`, `security`, `token`, `password`, `session`, `oauth`, `jwt`, `rbac`, `permission`, `credential`, `secret`, `csrf`, `xss`, `injection`
- Agent path: `agents/epic-executor/security-specialist.md`
- Risk level: HIGH

### Domain Specialists (medium risk)

**Backend Specialist** - If task mentions:
- Keywords: `api`, `endpoint`, `handler`, `route`, `controller`, `service`, `repository`, `backend`, `server`, `rest`, `graphql`, `grpc`
- Agent path: `agents/epic-executor/backend-specialist.md`
- Risk level: MEDIUM

**Frontend Specialist** - If task mentions:
- Keywords: `frontend`, `ui`, `component`, `react`, `vue`, `svelte`, `angular`, `interface`, `browser`, `client`, `jsx`, `tsx`
- Agent path: `agents/epic-executor/frontend-specialist.md`
- Risk level: MEDIUM

**Refactor Specialist** - If task mentions:
- Keywords: `refactor`, `cleanup`, `reorganize`, `restructure`, `simplify`, `extract`, `deduplicate`
- Agent path: `agents/epic-executor/refactor-specialist.md`
- Risk level: MEDIUM

### Quality Specialists (low risk)

**Test Specialist** - If task mentions:
- Keywords: `test`, `spec`, `testing`, `coverage`, `unit test`, `integration test`, `e2e`, `fixture`, `mock`, `stub`
- Agent path: `agents/epic-executor/test-specialist.md`
- Risk level: LOW

### Default

**General Purpose** - If no keywords match:
- Agent path: none (use general implementation approach)
- Risk level: MEDIUM

### Loading Specialist Instructions

If a specialist was selected:
1. Use the Read tool to load the specialist's instructions from the agent path
2. Include these instructions in the implementation subagent prompt (Step 5)

If general-purpose:
1. Use standard implementation approach
2. No additional specialist instructions needed

## Step 5: Dispatch Implementation Subagent

Use the Task tool to spawn a fresh implementation subagent with specialist context:

**Subagent Prompt**:
```
## Task Assignment

**Task**: $TASK_ID - $TASK_TITLE
**Agent**: $AGENT

**Description:**
$TASK_DESC

**Acceptance Criteria:**
$TASK_ACCEPTANCE

**Design Context:**
$DESIGN

<If SPECIALIST_INSTRUCTIONS exists:>
## Specialist Instructions

You have been assigned to this task because it matches the $AGENT domain.
Follow these specialized guidelines:

$SPECIALIST_INSTRUCTIONS

</If>

<If REVIEW_FEEDBACK exists:>
## Previous Review Feedback

This task was previously reviewed and needs corrections:

$REVIEW_FEEDBACK

Address these specific issues. The implementation was close but needs refinement.
</If>

## Learning Thread (Previous Task Discoveries)

$LEARNING_THREAD

**Key Points from Thread:**
- Follow patterns discovered by previous tasks
- Reuse components already found
- Don't reinvent solutions already documented
- Add new discoveries to the thread after completion

## Standard Instructions

1. Read CLAUDE.md first for project conventions
2. Read existing code in the area you're modifying BEFORE writing
3. Follow patterns from learning thread above
4. Focus ONLY on this task - no scope creep
5. Do NOT commit - leave changes staged
6. Run tests after implementation to verify
7. Keep it simple - minimum to satisfy acceptance criteria

## Completion

When done, reply with structured output:
```
STATUS: done
IMPLEMENTATION: <brief summary>
FILES_CHANGED: <list>
TESTS_RUN: <commands executed>
```
```

Wait for subagent to complete. Parse its output.

## Step 6: Two-Stage Review

### Stage 1: Spec Compliance
Check if implementation meets ALL acceptance criteria AND specialist requirements (if applicable):

```bash
# Review the implementation
SPEC_PASS=true

# Check each criterion
for criterion in $TASK_ACCEPTANCE; do
  # Verify criterion is met
  if ! verify_criterion "$criterion"; then
    SPEC_PASS=false
    SPEC_ISSUES+="- Criterion not met: $criterion\n"
  fi
done

if [[ "$SPEC_PASS" == false ]]; then
  # Store feedback and retry
  bd update "$TASK_ID" --metadata review_feedback="$SPEC_ISSUES"

  # Dispatch fix subagent (max 2 attempts)
  RETRY_COUNT=$(echo "$FULL_TASK" | jq -r '.metadata.spec_retry_count // 0')
  NEW_RETRY=$((RETRY_COUNT + 1))

  if [[ $NEW_RETRY -gt 2 ]]; then
    bd update "$TASK_ID" blocked
    bd comments add <epic-id> "🚫 Task $TASK_ID failed spec review after 2 retries. Marked blocked."
    exit 1
  fi

  bd update "$TASK_ID" --metadata spec_retry_count="$NEW_RETRY"
  # Re-dispatch implementation subagent (it will see review_feedback)
  # ... (loop back to Step 4)
fi
```

### Stage 2: Domain-Specific Quality

Only after spec passes, apply specialist-specific quality checks based on which agent was selected:

#### Migration Specialist Quality Checks
- [ ] Rollback migration exists and tested?
- [ ] Transaction wrapping verified?
- [ ] Lock time acceptable (<5 seconds)?
- [ ] Backup verification completed?
- [ ] Data integrity preserved?
- [ ] No data loss in forward migration?

#### Security Specialist Quality Checks
- [ ] OWASP Top 10 coverage?
- [ ] No hardcoded secrets (use Grep to search for passwords/keys)?
- [ ] Input validation present at boundaries?
- [ ] SQL injection prevention (parameterized queries)?
- [ ] XSS prevention (output encoding)?
- [ ] Rate limiting on auth endpoints?
- [ ] Authorization checks on protected endpoints?
- [ ] Security tests pass?

#### Backend Specialist Quality Checks
- [ ] Input validation at API boundary?
- [ ] Error handling with context wrapping?
- [ ] Transaction boundaries correct?
- [ ] No N+1 queries?
- [ ] HTTP status codes appropriate?
- [ ] Response format consistent?
- [ ] Unit and integration tests present?

#### Frontend Specialist Quality Checks
- [ ] Semantic HTML used (not all divs)?
- [ ] Keyboard navigation works?
- [ ] ARIA labels for accessibility?
- [ ] Loading/error/empty states handled?
- [ ] Responsive design (mobile/tablet/desktop)?
- [ ] Component tests cover user interactions?
- [ ] No axe accessibility violations?

#### Test Specialist Quality Checks
- [ ] Tests follow naming convention?
- [ ] Happy path, error paths, edge cases covered?
- [ ] Tests independent (no shared state)?
- [ ] Unit tests fast (<10ms each)?
- [ ] Clear assertions with meaningful messages?
- [ ] Tests actually test behavior (not implementation)?
- [ ] No flaky tests?

#### Refactor Specialist Quality Checks
- [ ] All tests still pass (no behavior change)?
- [ ] Public API unchanged (backward compatible)?
- [ ] Complexity actually reduced (not just moved)?
- [ ] Dead code removed (not just commented)?
- [ ] Changes committed incrementally?
- [ ] Each commit has passing tests?

#### General Purpose Quality Checks
- Standard code review for readability, maintainability, and best practices

### Universal Quality Checks (Always Apply)

**YAGNI Check**:
- [ ] No unnecessary abstractions or premature optimizations
- [ ] Implementation matches acceptance criteria scope
- [ ] No "might need later" code added

**Scope Check**:
- [ ] No unrelated changes
- [ ] All changes directly support acceptance criteria
- [ ] No feature creep beyond task definition

### General Code Quality
After specialist checks pass:

```bash
QUALITY_PASS=true
QUALITY_ISSUES=""

# Check based on task type
if [[ "$TASK_TITLE" =~ migration|schema ]]; then
  # Data integrity checks
  check_migration_safety || QUALITY_PASS=false
elif [[ "$TASK_TITLE" =~ auth|session|token ]]; then
  # Security checks
  check_owasp_compliance || QUALITY_PASS=false
fi

# Always check YAGNI
if has_unnecessary_abstraction; then
  QUALITY_ISSUES+="- Over-engineered: unnecessary abstraction detected\n"
  QUALITY_PASS=false
fi

if [[ "$QUALITY_PASS" == false ]]; then
  # Similar retry logic as spec review
  # ... (max 2 attempts)
fi
```

## Step 7: 5-Step Verification Gate

After both reviews pass:

```bash
# 1. IDENTIFY
VERIFY_COMMAND="npm test && npm run build && npm run lint"
echo "IDENTIFY: Running verification: $VERIFY_COMMAND"

# 2. RUN
echo "RUN: Executing verification..."
VERIFY_OUTPUT=$($VERIFY_COMMAND 2>&1)
VERIFY_EXIT=$?

# 3. READ
echo "READ: Full output:"
echo "$VERIFY_OUTPUT"

# 4. VERIFY
if [[ $VERIFY_EXIT -eq 0 ]]; then
  echo "VERIFY: All checks passed ✓"
else
  echo "VERIFY: Verification failed ✗"

  # Retry logic (max 3 total attempts)
  VERIFY_RETRY=$(echo "$FULL_TASK" | jq -r '.metadata.verify_retry_count // 0')
  NEW_VERIFY=$((VERIFY_RETRY + 1))

  if [[ $NEW_VERIFY -gt 3 ]]; then
    bd update "$TASK_ID" blocked
    bd comments add <epic-id> "🚫 Task $TASK_ID failed verification after 3 attempts. Marked blocked."
    exit 1
  fi

  bd update "$TASK_ID" --metadata verify_retry_count="$NEW_VERIFY"
  # Fix and retry from Step 4
  exit 1
fi

# 5. CLAIM
echo "CLAIM: Task verified and ready for commit"
```

## Step 8: Commit Changes

```bash
# Stage specific files only
git add <specific-files-changed>

# Create commit with conventional format
COMMIT_SHA=$(git commit -m "$(cat <<'EOF'
feat(module): $(echo "$TASK_TITLE" | cut -c1-50)

Implements <specific thing>. Includes tests and verification.

Task: $TASK_ID
Autonomous execution
EOF
)" && git rev-parse --short HEAD)

echo "COMMITTED: $COMMIT_SHA"
```

## Step 9: Capture Learnings

Capture discoveries using specialist-specific format:

Based on the specialist agent that was used, add a learning comment using the appropriate format template.

### Migration Specialist Learning Format

Use this format when the migration-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: migration-specialist

**Migration Details:**
- Type: <schema change|data migration|index|constraint>
- Tables: <affected tables and row counts>
- Lock time: <measured duration>
- Rollback tested: YES (see <down-migration-file>)

**Safety Measures:**
- Backup verified: <command/result>
- Transaction scope: <what's in BEGIN/COMMIT>
- Rollback plan: <down-migration-file>

**Patterns Discovered:**
- <migration helpers: path/to/file:lines>

**Gotchas:**
- <database-specific issues>
- <lock time surprises>

**For Next Migrations:**
- <reusable helpers and patterns>
EOF
)"
```

### Security Specialist Learning Format

Use this format when the security-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: security-specialist

**Security Implementation:**
- Auth mechanism: <JWT|Session|OAuth>
- Validation: <library/pattern>
- Secret storage: <env|vault|KMS>
- Rate limiting: <approach and limits>

**OWASP Coverage:**
- A01 Access Control: <mitigation>
- A02 Crypto: <mitigation>
- A03 Injection: <parameterized queries>
- A07 Auth: <rate limiting/session management>

**Security Tests:**
- SQL injection: <test file>
- XSS: <test file>
- Authorization: <test file>

**Vulnerabilities Prevented:**
- <specific attack vectors blocked>

**For Next Auth Tasks:**
- <reusable auth middleware: path:lines>
EOF
)"
```

### Backend Specialist Learning Format

Use this format when the backend-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: backend-specialist

**Implementation:**
- Endpoint: <HTTP method> <path>
- Handler: <path/to/handler.go:lines>
- Service: <path/to/service.go:lines>
- Repository: <path/to/repo.go:lines>

**Patterns Discovered:**
- Handler structure: <path:lines>
- Service pattern: <path:lines>
- Repository helper: <path:lines>

**Query Optimization:**
- Avoided N+1: <how>
- Used joins: <where>

**Gotchas:**
- Transaction rollback: <issue and solution>
- Query performance: <problem and fix>

**For Next Backend Tasks:**
- Reuse handler pattern: <path:lines>
EOF
)"
```

### Frontend Specialist Learning Format

Use this format when the frontend-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: frontend-specialist

**Implementation:**
- Component: <path/to/Component.tsx:lines>
- Tests: <path/to/Component.test.tsx>
- State management: <local|context|redux>

**Accessibility:**
- Semantic HTML: <elements used>
- Keyboard navigation: <keys supported>
- ARIA attributes: <labels, roles>

**Component Reuse:**
- Base components: <which ones used>
- New reusable: <if created>

**Gotchas:**
- State management: <issue and solution>
- Accessibility: <challenge and approach>

**For Next Frontend Tasks:**
- Reuse component: <path/to/Component.tsx>
EOF
)"
```

### Test Specialist Learning Format

Use this format when the test-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: test-specialist

**Tests Added:**
- Unit tests: <path/to/file_test.go> (X tests)
- Integration tests: <path/to/integration_test.go> (Y tests)
- Coverage: <before>% → <after>%

**Edge Cases Covered:**
- Boundary: <empty input, nil values>
- Error paths: <invalid input, failures>

**Patterns Discovered:**
- Test helper: <path/to/testutil/helper.go:lines>
- Fixture builder: <path/to/fixtures/user.go:lines>

**Gotchas:**
- Test isolation: <issue and solution>
- Flakiness: <problem and fix>

**For Next Test Tasks:**
- Reuse fixtures: <path/to/fixtures/>
EOF
)"
```

### Refactor Specialist Learning Format

Use this format when the refactor-specialist was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA
**Agent**: refactor-specialist

**Refactoring:**
- Type: <extract function|remove duplication|simplify>
- Files: <files modified>
- Lines: <before> → <after>

**Refactorings Applied:**
- Extracted functions: <list with line numbers>
- Removed duplication: <where>
- Simplified conditionals: <where>

**Safety Measures:**
- Tests before: <count passing>
- Tests after: <count passing>
- Behavior verified: <how>

**Improvements:**
- Readability: <specific improvement>
- Complexity reduced: <metric>

**For Next Refactors:**
- Pattern to reuse: <path:lines>
EOF
)"
```

### General Purpose Learning Format

Use this format when general-purpose (no specialist) was selected:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA

**Implementation:**
- Files: <list files changed>
- Tests: <test commands run>

**Patterns used:**
- <from learning thread>

**New discoveries:**
- <new patterns: path/to/file:lines>

**Gotchas:**
- <issues encountered>

**For next tasks:**
- <recommendations>
EOF
)"
```

## Step 10: Close Task & Update Status

```bash
# Close task
bd close "$TASK_ID" "Completed autonomously"

# Update status file
COMPLETED=$(bd list --parent <epic-id> --status closed --json | jq 'length')
jq --arg completed "$COMPLETED" \
   --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.completed_tasks = ($completed | tonumber) | .last_activity = $ts' \
   /tmp/autonomous-executor-status-<epic-id>.json > /tmp/tmp.$$.json && \
   mv /tmp/tmp.$$.json /tmp/autonomous-executor-status-<epic-id>.json

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Task $TASK_ID complete"
echo "Commit: $COMMIT_SHA"
echo "Progress: $COMPLETED tasks done"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

## Step 11: Exit

```bash
# Exit cleanly - polling loop will handle next task
exit 0
```

## Error Handling

If ANY step fails after retries:

```bash
# Mark task as blocked
bd update "$TASK_ID" blocked

# Add detailed comment
bd comments add <epic-id> "🚫 **Task $TASK_ID Failed**

Stage: <which stage failed>
Attempts: <retry count>
Error: <error message>

Manual intervention required.
See task for details: bd show $TASK_ID"

# Update status
jq '.failed_tasks = (.failed_tasks + 1)' \
   /tmp/autonomous-executor-status-<epic-id>.json > /tmp/tmp.$$.json && \
   mv /tmp/tmp.$$.json /tmp/autonomous-executor-status-<epic-id>.json

exit 1
```

**Critical**: Always update task status before exiting. Never leave tasks in `in_progress` if you can't complete them.
```

---

## Phase 4: Completion & Shutdown

### 4.1 Shutdown Function

```bash
function shutdown_autonomous_execution() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "AUTONOMOUS EXECUTION SHUTDOWN"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Load final status
  STATUS=$(cat /tmp/autonomous-executor-status-<epic-id>.json)
  COMPLETED=$(echo "$STATUS" | jq -r '.completed_tasks')
  FAILED=$(echo "$STATUS" | jq -r '.failed_tasks')
  POLL_COUNT=$(echo "$STATUS" | jq -r '.poll_count')

  BASE_SHA=$(cat /tmp/autonomous-executor-base-<epic-id>.txt)
  HEAD_SHA=$(git rev-parse HEAD)
  COMMIT_COUNT=$(git rev-list --count ${BASE_SHA}..${HEAD_SHA})

  START_TIME=$(cat /tmp/autonomous-executor-start-<epic-id>.txt)
  END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Run final verification if epic complete
  EPIC_STATUS=$(bd show <epic-id> --json | jq -r '.status')
  if [[ "$EPIC_STATUS" == "closed" ]] || check_epic_complete; then
    run_final_verification

    # Close epic if not already closed
    if [[ "$EPIC_STATUS" != "closed" ]]; then
      bd close <epic-id> "Completed autonomously"
    fi
  fi

  # Generate final report
  bd comments add <epic-id> "$(cat <<EOF
🤖 **Autonomous Execution Complete**

**Summary:**
- Tasks completed: $COMPLETED
- Tasks failed: $FAILED
- Commits: $COMMIT_COUNT ($BASE_SHA..$HEAD_SHA)
- Poll cycles: $POLL_COUNT
- Duration: $START_TIME to $END_TIME

**Final Verification:**
$(final_verification_status)

**Learning Thread:**
$COMPLETED knowledge entries captured

View thread: bd show <epic-id> --thread
Commit history: git log ${BASE_SHA}..${HEAD_SHA}
EOF
)"

  # Cleanup
  rm -f /tmp/autonomous-executor-base-<epic-id>.txt
  rm -f /tmp/autonomous-executor-start-<epic-id>.txt
  rm -f /tmp/autonomous-executor-status-<epic-id>.json
  rm -f /tmp/autonomous-executor-stop-<epic-id>

  echo ""
  echo "Final Status: $EPIC_STATUS"
  echo "Tasks Completed: $COMPLETED"
  echo "Tasks Failed: $FAILED"
  echo "Commits: $COMMIT_COUNT"
  echo ""
  echo "Full report: bd show <epic-id> --thread"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
```

### 4.2 Final Verification

```bash
function run_final_verification() {
  echo "Running final verification suite..."

  npm test && npm run build && npm run lint && npm run typecheck
  VERIFY_EXIT=$?

  if [[ $VERIFY_EXIT -eq 0 ]]; then
    echo "✅ All verification passed"
    return 0
  else
    echo "🚫 Final verification failed"
    bd comments add <epic-id> "🚫 **Final Verification Failed** - Manual review required."
    return 1
  fi
}
```

### 4.3 Launch Learning Agent (Background)

After epic completion, optionally launch the learning-agent to synthesize knowledge:

```bash
function launch_learning_synthesis() {
  echo "🧠 Launching learning-agent for knowledge synthesis..."

  # Launch in background (doesn't block completion)
  nohup claude code --skill rivets:learning-synthesis <epic-id> \
    > /tmp/learning-agent-<epic-id>.log 2>&1 &

  LEARNING_PID=$!

  bd comments add <epic-id> "🧠 **Learning Agent**: Knowledge synthesis started (PID: $LEARNING_PID)"

  echo "Learning agent running in background."
  echo "View progress: tail -f /tmp/learning-agent-<epic-id>.log"
  echo ""
  echo "The learning agent will:"
  echo "  - Analyze all task comments from this epic"
  echo "  - Extract patterns, reusable components, and gotchas"
  echo "  - Generate synthesized knowledge summary"
  echo "  - Update epic notes with findings"
  echo ""
  echo "Estimated completion: 5-10 minutes"
}

# Call during shutdown if epic complete
if check_epic_complete; then
  launch_learning_synthesis
fi
```

**Note**: The learning-agent is a special background agent that runs after epic completion. It:
- Analyzes the entire epic comment thread
- Extracts reusable patterns and components
- Identifies common gotchas
- Documents conventions established
- Updates epic notes with synthesized knowledge

This happens asynchronously and doesn't block the main autonomous executor shutdown.

---

## Specialist Agent Reference

The autonomous executor uses domain-specific specialist agents for targeted tasks:

### Implementation Specialists

| Agent | Triggers | Risk Level | Purpose |
|-------|----------|------------|---------|
| **migration-specialist** | migration, schema, alter table, database | HIGH | Safe database migrations with rollback |
| **security-specialist** | auth, security, token, password, oauth | HIGH | OWASP-compliant security implementation |
| **backend-specialist** | api, endpoint, handler, service, rest | MEDIUM | Backend services and data access |
| **frontend-specialist** | ui, component, react, vue, interface | MEDIUM | Accessible UI components |
| **test-specialist** | test, spec, coverage, mock, fixture | LOW | Comprehensive test implementation |
| **refactor-specialist** | refactor, cleanup, simplify, extract | MEDIUM | Safe refactoring with test preservation |

### Special Agents (Not in Normal Flow)

| Agent | When Used | Purpose |
|-------|-----------|---------|
| **verification-agent** | After each implementation | Independent quality review and acceptance testing |
| **learning-agent** | After epic completion (background) | Pattern extraction and knowledge synthesis |

Each specialist brings:
- Domain-specific checks and validation
- Specialized learning contribution format
- Patterns and best practices for that domain
- Red flags and safety checks

See `agents/epic-executor/` directory for full specialist definitions.

---

## Monitoring & Status

### Check Status Anytime

```bash
# View current status
cat /tmp/autonomous-executor-status-<epic-id>.json | jq

# Watch real-time
watch -n 10 'cat /tmp/autonomous-executor-status-<epic-id>.json | jq'

# View learning thread
bd show <epic-id> --thread

# View progress
bd stats --parent <epic-id>
```

### Optional Dashboard (if --dashboard-port provided)

```bash
# Start simple HTTP server
if [[ -n "$DASHBOARD_PORT" ]]; then
  (
    while true; do
      STATUS=$(cat /tmp/autonomous-executor-status-<epic-id>.json)
      echo -e "HTTP/1.1 200 OK\nContent-Type: application/json\n\n$STATUS" | \
        nc -l -p $DASHBOARD_PORT -q 1
    done
  ) &
  DASHBOARD_PID=$!
  echo "Dashboard: http://localhost:$DASHBOARD_PORT"
fi
```

---

## Safety Features

### 1. Circuit Breaker
Stops execution if >30% of tasks fail (blocked status)

### 2. Abandoned Task Recovery
Automatically detects and recovers tasks stuck in `in_progress` for >35 minutes

### 3. Rate Limiting
Maximum 1 task per 10 minutes to prevent resource exhaustion

### 4. Manual Override
Multiple ways to stop:
- Stop file: `touch /tmp/autonomous-executor-stop-<epic-id>`
- Comment: `bd comments add <epic-id> "STOP_REQUESTED"`
- Close epic: `bd close <epic-id>`

### 5. Separate Retry Tracking
- `abandon_count`: For timeouts/crashes (max 5)
- `spec_retry_count`: For spec review failures (max 2)
- `verify_retry_count`: For verification failures (max 3)

---

## Comparison to Epic-Executor

| Aspect | epic-executor | autonomous-executor |
|--------|---------------|---------------------|
| **Mode** | Supervised | Autonomous |
| **Duration** | Single session | Hours/days |
| **Cost** | $50-100/hour | $2-5/hour |
| **Supervision** | Full | None |
| **Use case** | Interactive work | Long-running batch |
| **Stop** | User stops | Auto-complete or manual |

**When to use which**:
- Use **epic-executor** for: Interactive work, exploring unknowns, rapid iteration
- Use **autonomous-executor** for: Known work, overnight execution, batch processing

---

## Dependencies

Required:
- Beads (`bd` command) for task management
- Git repository with clean working tree
- Project build/test commands configured

Optional:
- Dashboard port (for real-time monitoring)
- OpenClaw `sessions_spawn` tool (for work agent spawning)

---

## Troubleshooting

### Polling agent keeps saying HEARTBEAT_OK but tasks exist

Check task dependencies:
```bash
bd list --parent <epic-id> --json | jq '.[] | select(.status == "open") | {id, title, depends_on}'
```

### Circuit breaker triggered too early

Adjust threshold in check_circuit_breaker function (default: 30%)

### Tasks abandoned repeatedly

Check timeout values match task complexity. Increase max_timeout in work agent prompt.

### Can't stop execution

Force stop:
```bash
touch /tmp/autonomous-executor-stop-<epic-id>
# If polling loop still running:
pkill -f "autonomous-executor.*<epic-id>"
```

---

## Credits

Architecture inspired by Antfarm's autonomous multi-agent workflow system. Adapted for Rivets' Beads-based tracking and verification-first approach.
