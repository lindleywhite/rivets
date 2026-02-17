# Autonomous Epic-Executor Design

Moving epic-executor from supervised execution to fully autonomous operation, inspired by Antfarm's multi-agent architecture.

**Goal**: Launch epic-executor once, have it work autonomously for hours/days, checking for ready tasks, executing them, verifying, committing, and reporting progress without human intervention.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│  Phase 1: Polling Loop (Cheap Model - Sonnet 4)        │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Every 5 minutes:                                        │
│  1. Check: bd ready --parent <epic-id>                  │
│  2. If no work → HEARTBEAT_OK, sleep 5 min             │
│  3. If work found → Spawn Phase 2                       │
└─────────────────────────────────────────────────────────┘
                          ↓ (work found)
┌─────────────────────────────────────────────────────────┐
│  Phase 2: Work Execution (Expensive Model - Opus 4.6)  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  1. Claim task (mark in_progress)                       │
│  2. Read learning thread                                │
│  3. Dispatch implementation subagent (fresh context)    │
│  4. Two-stage review                                    │
│  5. 5-step verification gate                            │
│  6. Commit changes                                      │
│  7. Capture learnings (comment)                         │
│  8. Close task                                          │
│  9. Return to Phase 1                                   │
└─────────────────────────────────────────────────────────┘
                          ↓ (repeat)
```

---

## Phase 1: Autonomous Polling Loop

### 1.1 Polling Agent Prompt (Cheap Model)

This runs continuously every 5 minutes:

```markdown
You are an autonomous epic-executor polling agent for epic <epic-id>.

Your job: Check for ready work and spawn work agents when needed.

## Check for Ready Work

Run this command:
```bash
bd ready --parent <epic-id> --json
```

## Decision Logic

**If output is empty array `[]`:**
- Reply: "HEARTBEAT_OK - No ready tasks. Polling continues."
- You will be invoked again in 5 minutes
- Do not spawn any agents

**If output contains tasks:**
- Parse the JSON to get first ready task
- Call `sessions_spawn` tool with these parameters:
  - agentId: "epic-executor-worker-<epic-id>"
  - model: "claude-opus-4-6"
  - task: The work prompt below + claimed task JSON

## Work Prompt to Spawn

When work is found, spawn a session with this prompt:

---START WORK PROMPT---
{WORK_PROMPT_TEMPLATE}
---END WORK PROMPT---

## Critical Rules

1. Only spawn ONE work agent per polling cycle
2. Do NOT attempt to do the work yourself
3. Keep this session short (<30 seconds)
4. You are the cheap checker, not the expensive worker

Reply with either:
- "HEARTBEAT_OK" (no work)
- "SPAWNED: <task-id>" (work agent launched)
```

### 1.2 Work Prompt Template

This is what the expensive work agent receives:

```markdown
You are an autonomous epic-executor work agent.

## Epic Context

**Epic**: <epic-id> - <epic-title>
**Mode**: Autonomous execution (no human supervision)

## Your Mission

Execute ONE task from this epic, then exit. The polling agent will handle the next task.

## Step 1: Claim Next Ready Task

```bash
# Get ready tasks
READY_TASKS=$(bd ready --parent <epic-id> --json)

# If empty, exit (someone else might have claimed it)
if [[ $(echo "$READY_TASKS" | jq 'length') -eq 0 ]]; then
  echo "NO_WORK - Task was claimed by another agent"
  exit 0
fi

# Get first ready task
TASK_ID=$(echo "$READY_TASKS" | jq -r '.[0].id')
TASK_TITLE=$(echo "$READY_TASKS" | jq -r '.[0].title')

# Claim it atomically
bd update "$TASK_ID" in_progress
echo "CLAIMED: $TASK_ID - $TASK_TITLE"
```

## Step 2: Load Task Context

```bash
# Get full task details
TASK_JSON=$(bd show "$TASK_ID" --json)
DESCRIPTION=$(echo "$TASK_JSON" | jq -r '.description')
ACCEPTANCE=$(echo "$TASK_JSON" | jq -r '.acceptance_criteria')
DESIGN=$(echo "$TASK_JSON" | jq -r '.design // ""')

# Load learning thread (last 5 task comments)
LEARNING_THREAD=$(bd comments <epic-id> --json | \
  jq -r 'sort_by(.created_at) | reverse | limit(5; .[]) |
  "[\(.created_at | split("T")[0])] \(.body)\n---\n"')
```

## Step 3: Execute Task

Dispatch implementation subagent using Task tool:

**Subagent prompt:**
```
## Task Assignment

**Task**: $TASK_ID - $TASK_TITLE

**Description:**
$DESCRIPTION

**Acceptance Criteria:**
$ACCEPTANCE

**Design Context:**
$DESIGN

## Learning Thread (Previous Task Discoveries)

$LEARNING_THREAD

**Key Points:**
- Follow patterns from the learning thread
- Reuse components already discovered
- Don't reinvent solutions

## Standard Instructions

1. Read CLAUDE.md first for project conventions
2. Read existing code before writing anything
3. Follow patterns from learning thread above
4. Focus ONLY on this task - no scope creep
5. Do NOT commit - leave changes staged
6. Run tests after implementation
7. Keep it simple - minimum to satisfy criteria
```

Wait for subagent to complete.

## Step 4: Two-Stage Review

### Stage 1: Spec Compliance
- Does implementation meet every acceptance criterion?
- Are all required features present?
- Does it match design decisions?

If fails: Dispatch fix subagent with feedback, retry (max 2 attempts).

### Stage 2: Code Quality
Only after spec passes:
- Security (OWASP, injection, auth)
- Performance (N+1, caching)
- Maintainability (patterns, naming)

If fails: Dispatch targeted fix subagent (max 2 attempts).

## Step 5: 5-Step Verification Gate

1. **IDENTIFY**: State verification command needed
2. **RUN**: Execute it (tests, build, lint)
3. **READ**: Read FULL output
4. **VERIFY**: Confirm output proves task complete
5. **CLAIM**: Mark task done

If verification fails: Fix and restart (max 3 attempts total).

## Step 6: Commit Changes

```bash
# Stage specific files
git add <specific-files>

# Commit with conventional format
git commit -m "$(cat <<'EOF'
feat(module): description

Implements [specific thing]. Includes [tests].

Task: $TASK_ID
EOF
)"

COMMIT_SHA=$(git rev-parse --short HEAD)
echo "COMMITTED: $COMMIT_SHA"
```

## Step 7: Capture Learnings

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task $TASK_ID**: $TASK_TITLE
**Commit**: $COMMIT_SHA

**Patterns used:**
- <from learning thread>

**New discoveries:**
- <new patterns>

**Gotchas:**
- <issues encountered>

**For next tasks:**
- <recommendations>
EOF
)"
```

## Step 8: Close Task

```bash
bd close "$TASK_ID" "Completed autonomously"
echo "TASK_CLOSED: $TASK_ID"
```

## Step 9: Report & Exit

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Task $TASK_ID complete"
echo "Commit: $COMMIT_SHA"
echo "Next: Polling agent will claim next ready task"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
```

## Error Handling

If ANY step fails after retries:
1. Mark task as blocked: `bd update $TASK_ID blocked`
2. Add comment explaining failure
3. File issue for the blocker (if not already exists)
4. Exit cleanly (polling agent will skip and find next task)

**NEVER leave task in in_progress state if you can't complete it.**

## Autonomous Rules

1. **No human questions** - make best judgment from context
2. **Document assumptions** - in task comments
3. **Fail gracefully** - mark blocked, explain, move on
4. **Stay focused** - one task per session
5. **Clean exit** - always update task status before exiting
```

### 1.3 Polling Loop Lifecycle

**Start autonomously:**

```bash
# Launch autonomous epic-executor
/epic-executor <epic-id> --autonomous

# This creates a monitoring loop that:
# 1. Spawns polling agent (cheap model)
# 2. Polling agent checks every 5 minutes
# 3. Spawns work agents when tasks ready
# 4. Continues until epic complete or manual stop
```

**Stop conditions:**

```bash
# Check epic status every poll
EPIC_STATUS=$(bd show <epic-id> --json | jq -r '.status')

if [[ "$EPIC_STATUS" == "closed" ]]; then
  echo "EPIC_COMPLETE - Stopping autonomous execution"
  exit 0
fi

# Also stop if stop-file exists
if [[ -f /tmp/epic-executor-stop-<epic-id> ]]; then
  echo "STOP_REQUESTED - Exiting gracefully"
  exit 0
fi
```

**Manual stop:**

```bash
# User can stop anytime
touch /tmp/epic-executor-stop-<epic-id>

# Or kill the polling process
ps aux | grep "epic-executor.*<epic-id>" | awk '{print $2}' | xargs kill
```

---

## Phase 2: Abandoned Task Recovery

Just like Antfarm, detect and recover stuck tasks:

```markdown
### 2.1 Abandoned Task Detection

Before claiming new work, check for abandoned tasks:

```bash
# Find tasks stuck in in_progress for > 35 minutes
ABANDONED=$(bd list --parent <epic-id> --status in_progress --json | \
  jq --arg threshold "$(date -u -d '35 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  'map(select(.updated_at < $threshold)) | .[].id')

for task_id in $ABANDONED; do
  echo "⚠️  Detected abandoned task: $task_id"

  # Get abandon count
  ABANDON_COUNT=$(bd show "$task_id" --json | jq -r '.metadata.abandon_count // 0')
  NEW_COUNT=$((ABANDON_COUNT + 1))

  if [[ $NEW_COUNT -ge 5 ]]; then
    # Too many abandons - mark blocked
    bd update "$task_id" blocked
    bd comments add <epic-id> "🚫 Task $task_id abandoned $NEW_COUNT times. Marked as blocked. Needs investigation."
    echo "Task $task_id marked blocked after $NEW_COUNT abandons"
  else
    # Reset to open for retry
    bd update "$task_id" open
    bd update "$task_id" --metadata abandon_count="$NEW_COUNT"
    bd comments add <epic-id> "♻️ Task $task_id abandoned (attempt $NEW_COUNT/5). Reset to open for retry."
    echo "Task $task_id reset to open (abandon $NEW_COUNT/5)"
  fi
done
```

**Separate tracking:**
- `abandon_count` - for timeouts/crashes (max 5)
- `retry_count` - for explicit failures (max 2)

This gives more chances for transient issues while being strict about persistent problems.

### 2.2 When to Check

Check for abandoned tasks:
1. At polling loop start (before claiming)
2. Every 10th poll cycle (every ~50 minutes)
3. After any task completion (cleanup)

```bash
POLL_COUNT=0

while true; do
  POLL_COUNT=$((POLL_COUNT + 1))

  # Every 10th poll, do abandoned task check
  if [[ $((POLL_COUNT % 10)) -eq 0 ]]; then
    cleanup_abandoned_tasks
  fi

  # Normal polling
  check_for_ready_work

  sleep 300  # 5 minutes
done
```
```

---

## Phase 3: Progress Monitoring & Reporting

### 3.1 Periodic Status Reports

Every 5 completed tasks, post status update:

```bash
# Check if multiple of 5 tasks closed
CLOSED_COUNT=$(bd list --parent <epic-id> --status closed --json | jq 'length')

if [[ $((CLOSED_COUNT % 5)) -eq 0 ]] && [[ $CLOSED_COUNT -gt 0 ]]; then
  # Generate status report
  TOTAL=$(bd list --parent <epic-id> --json | jq 'length')
  REMAINING=$((TOTAL - CLOSED_COUNT))

  bd comments add <epic-id> "$(cat <<EOF
📊 **Progress Checkpoint** ($CLOSED_COUNT/$TOTAL tasks complete)

Remaining: $REMAINING tasks
Last 3 completed:
$(bd list --parent <epic-id> --status closed --json | \
  jq -r 'sort_by(.closed_at) | reverse | limit(3; .[]) |
  "- [\(.id)] \(.title)"')

Autonomous execution continues...
EOF
)"
fi
```

### 3.2 Phase Boundary Detection

Detect when dependency layers complete:

```bash
# Check if all tasks at current level are done
CURRENT_LEVEL_OPEN=$(bd list --parent <epic-id> --json | \
  jq '[.[] | select(.status != "closed" and (.depends_on | length) == 0)] | length')

if [[ $CURRENT_LEVEL_OPEN -eq 0 ]]; then
  echo "🎯 Phase boundary detected - all current level tasks complete"

  # Run full test suite
  echo "Running full verification suite..."
  npm test && npm run build && npm run lint

  if [[ $? -eq 0 ]]; then
    bd comments add <epic-id> "✅ **Phase Boundary Passed** - All current level tasks complete and verified"
  else
    bd comments add <epic-id> "🚫 **Phase Boundary Failed** - Verification suite failed. Stopping autonomous execution."
    exit 1
  fi
fi
```

### 3.3 Dashboard Integration (Future)

Expose real-time status via HTTP endpoint:

```bash
# Start status server (optional)
/epic-executor <epic-id> --autonomous --dashboard-port 8080

# Check status
curl http://localhost:8080/status
{
  "epic_id": "bd-abc123",
  "status": "running",
  "completed": 12,
  "total": 45,
  "current_task": "bd-def456",
  "uptime": "3h 24m",
  "last_activity": "2026-02-13T18:45:00Z"
}
```

---

## Phase 4: Epic Completion

### 4.1 Detect Completion

Polling agent checks after every work session:

```bash
# Check if all tasks closed
OPEN_COUNT=$(bd list --parent <epic-id> --status open,in_progress,blocked --json | jq 'length')

if [[ $OPEN_COUNT -eq 0 ]]; then
  echo "🎉 All tasks complete - initiating epic completion"

  # Run final verification
  run_final_verification

  # Generate summary
  generate_completion_summary

  # Close epic
  bd close <epic-id> "Completed autonomously"

  # Stop polling
  exit 0
fi
```

### 4.2 Final Verification Suite

```bash
function run_final_verification() {
  echo "Running final verification suite..."

  # Full test suite
  npm test
  TEST_EXIT=$?

  # Build
  npm run build
  BUILD_EXIT=$?

  # Lint
  npm run lint
  LINT_EXIT=$?

  # Type check
  npm run typecheck
  TYPE_EXIT=$?

  if [[ $TEST_EXIT -eq 0 ]] && [[ $BUILD_EXIT -eq 0 ]] && [[ $LINT_EXIT -eq 0 ]] && [[ $TYPE_EXIT -eq 0 ]]; then
    echo "✅ All verification passed"
    return 0
  else
    echo "🚫 Verification failed"
    bd comments add <epic-id> "🚫 **Final Verification Failed** - See logs for details. Manual intervention required."
    exit 1
  fi
}
```

### 4.3 Completion Summary

```bash
function generate_completion_summary() {
  BASE_SHA=$(cat /tmp/epic-base-sha-<epic-id>.txt)
  HEAD_SHA=$(git rev-parse HEAD)
  COMMIT_COUNT=$(git rev-list --count ${BASE_SHA}..${HEAD_SHA})

  TASK_COUNT=$(bd list --parent <epic-id> --status closed --json | jq 'length')
  START_TIME=$(bd show <epic-id> --json | jq -r '.created_at')
  END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  bd comments add <epic-id> "$(cat <<EOF
🎉 **Epic Complete**

**Execution**: Fully autonomous
**Tasks**: $TASK_COUNT completed
**Commits**: $COMMIT_COUNT ($BASE_SHA..$HEAD_SHA)
**Duration**: $START_TIME to $END_TIME

**Final Verification:**
- Tests: PASS
- Build: PASS
- Lint: PASS
- TypeCheck: PASS

**Learning Thread:**
$TASK_COUNT knowledge entries captured

View thread: bd show <epic-id> --thread
Commit range: git log ${BASE_SHA}..${HEAD_SHA}
EOF
)"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 Epic <epic-id> completed autonomously!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
```

---

## Implementation Comparison

| Aspect | Current Epic-Executor | Autonomous Epic-Executor | Antfarm |
|--------|----------------------|-------------------------|---------|
| **Trigger** | User runs command | Autonomous polling loop | Cron job |
| **Supervision** | User monitors | None - fully autonomous | None |
| **Task claiming** | Sequential manual | Autonomous with retry | Autonomous |
| **Verification** | User-supervised | Automated gates | Automated |
| **Failure handling** | User intervention | Automatic retry/block | Automatic retry |
| **Duration** | Single session | Hours/days continuous | Days/weeks |
| **Stop condition** | User stops | Epic complete or manual stop | Run complete |
| **Progress tracking** | User sees in terminal | Comments + optional dashboard | Events + dashboard |

---

## New Epic-Executor Command Flags

```bash
# Current: Supervised execution
/epic-executor <epic-id>

# New: Fully autonomous
/epic-executor <epic-id> --autonomous

# With monitoring dashboard
/epic-executor <epic-id> --autonomous --dashboard-port 8080

# Resume autonomous execution
/epic-executor <epic-id> --autonomous --resume

# Dry run to see execution plan
/epic-executor <epic-id> --autonomous --dry-run
```

---

## Safety Features

### 1. Circuit Breakers

```bash
# Stop if too many failures
FAILED_COUNT=$(bd list --parent <epic-id> --status blocked --json | jq 'length')
TOTAL=$(bd list --parent <epic-id> --json | jq 'length')
FAILURE_RATE=$(echo "scale=2; $FAILED_COUNT / $TOTAL" | bc)

if (( $(echo "$FAILURE_RATE > 0.3" | bc -l) )); then
  echo "🚫 CIRCUIT BREAKER: >30% tasks blocked. Stopping autonomous execution."
  bd comments add <epic-id> "🚫 **Circuit Breaker Triggered** - $FAILED_COUNT/$TOTAL tasks blocked. Manual intervention required."
  exit 1
fi
```

### 2. Rate Limiting

```bash
# Max 1 task per 10 minutes (prevent runaway)
LAST_TASK_TIME=$(bd list --parent <epic-id> --status closed --json | \
  jq -r 'sort_by(.closed_at) | reverse | .[0].closed_at')

TIME_SINCE_LAST=$(($(date +%s) - $(date -d "$LAST_TASK_TIME" +%s)))

if [[ $TIME_SINCE_LAST -lt 600 ]]; then
  echo "Rate limit: Last task completed ${TIME_SINCE_LAST}s ago. Waiting..."
  sleep $((600 - TIME_SINCE_LAST))
fi
```

### 3. Manual Override

```bash
# User can leave instructions
if [[ -f /tmp/epic-executor-pause-<epic-id> ]]; then
  echo "⏸️  PAUSE requested. Waiting for resume..."
  while [[ -f /tmp/epic-executor-pause-<epic-id> ]]; do
    sleep 60
  done
  echo "▶️  Resuming autonomous execution..."
fi
```

---

## Cost Optimization

| Phase | Model | Frequency | Cost/Hour* |
|-------|-------|-----------|------------|
| Polling | Sonnet 4 | Every 5 min | ~$0.05 |
| Work execution | Opus 4.6 | Per task | ~$2-5 |
| **Total** | Mixed | Continuous | **$2-5/hr** |

*Estimated based on typical task complexity

**Cost savings vs continuous Opus:**
- Polling with Sonnet: 95% cheaper
- Work only spawned when needed
- ~40x cost reduction for idle time

---

## Migration Path

### Week 1: Add Autonomous Flag
```markdown
Add `--autonomous` flag to epic-executor
- Falls back to current supervised mode without flag
- Implements basic polling loop
- No safety features yet
```

### Week 2: Add Safety Features
```markdown
- Circuit breakers
- Abandoned task recovery
- Rate limiting
- Manual override controls
```

### Week 3: Add Monitoring
```markdown
- Progress reports in comments
- Phase boundary detection
- Optional dashboard endpoint
```

### Week 4: Production Ready
```markdown
- Comprehensive error handling
- Rollback capabilities
- Full logging and audit trail
- Documentation and examples
```

---

## Example Session

```bash
# User starts autonomous execution
$ /epic-executor bd-feature-auth --autonomous
Epic: bd-feature-auth "Authentication System"
Tasks: 23 total, 23 ready

Starting autonomous execution...
Polling interval: 5 minutes
Stop with: touch /tmp/epic-executor-stop-bd-feature-auth

[18:00] Polling agent started
[18:00] Found 1 ready task: bd-task-001 "Create User model"
[18:00] Spawning work agent...
[18:03] ✅ bd-task-001 complete (commit: abc123d)
[18:03] Learning captured in epic thread
[18:03] Polling resumes...

[18:08] Found 1 ready task: bd-task-002 "Create auth service"
[18:08] Spawning work agent...
[18:11] ✅ bd-task-002 complete (commit: def456e)
[18:11] Polling resumes...

[18:16] No ready tasks (dependencies not met)
[18:16] HEARTBEAT_OK - Polling continues...

[18:21] No ready tasks
[18:21] HEARTBEAT_OK - Polling continues...

[18:26] Found 1 ready task: bd-task-003 "Add auth endpoints"
...

# User can check status anytime
$ bd show bd-feature-auth --thread
# See all progress updates

# User can stop anytime
$ touch /tmp/epic-executor-stop-bd-feature-auth
[19:45] STOP_REQUESTED - Exiting gracefully
[19:45] Tasks completed: 8/23
[19:45] Autonomous execution stopped
```

---

## Open Questions

1. **Context persistence**: How to maintain state across polling sessions?
   - Option A: Use Beads metadata
   - Option B: Use temp files (current approach)
   - Option C: Add epic-executor DB table

2. **Multi-epic support**: Can multiple epics run autonomously simultaneously?
   - Each gets own polling loop
   - Need resource contention handling
   - Potential git merge conflicts

3. **Integration with CI/CD**: Should autonomous execution trigger on PR merge?
   - Epic auto-starts when base branch updates
   - Tasks adapt to codebase changes
   - Auto-rebase on conflicts

4. **Learning consolidation**: When to synthesize comment thread into patterns?
   - After every 10 tasks?
   - At phase boundaries?
   - On demand via command?

---

## Next Steps

To implement autonomous epic-executor:

1. **Add autonomous polling skeleton** to epic-executor SKILL.md
2. **Create two prompts**: polling prompt + work prompt
3. **Test with simple 3-task epic** to validate loop
4. **Add abandoned task recovery**
5. **Add progress monitoring**
6. **Add safety features** (circuit breakers, rate limits)
7. **Document usage** and examples
8. **Iterate based on real usage**

---

## Credits

Architecture inspired by Antfarm's autonomous multi-agent workflow system, adapted for Rivets' Beads-based tracking and epic-executor's verification-first approach.
