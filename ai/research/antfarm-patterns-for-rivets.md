# Antfarm Patterns for Rivets - Implementation Roadmap

Based on comprehensive research of Antfarm's multi-agent architecture, here are the patterns to adopt for Rivets, updated with discoveries from our analysis.

**Research Source**: `ai/research/2026-02-13_multi-agent-architecture.md`

---

## Executive Summary

**Key Discovery**: Beads already implements many of Antfarm's core patterns! It uses SQLite for atomic operations, JSONL for git sync, and has built-in dependency management. This means we can focus on the **autonomous execution patterns** rather than rebuilding foundational infrastructure.

**Strategic Direction**: Move epic-executor to fully autonomous operation using two-phase polling, just like Antfarm's workflow agents.

---

## Pattern Assessment Matrix

| # | Pattern | Current Status | Priority | Effort | Impact |
|---|---------|---------------|----------|--------|--------|
| 1 | Two-phase autonomous polling | ❌ Not implemented | **CRITICAL** | High | Revolutionary |
| 2 | Database-driven coordination | ✅ **Already exists** (Beads) | N/A | Done | N/A |
| 3 | Progress tracking via comments | ⚠️ Partial → ✅ **Design complete** | **HIGH** | Low | High |
| 4 | Structured verify-retry feedback | ⚠️ Partial → ✅ **Design complete** | **HIGH** | Low | High |
| 5 | Abandoned task recovery | ❌ Not implemented → ✅ **Design complete** | **HIGH** | Medium | High |
| 6 | Event-driven progress tracking | ❌ Not implemented | **MEDIUM** | Medium | Medium |
| 7 | Staggered parallel execution | ❌ Not implemented | LOW | Medium | Medium |
| 8 | Declarative workflow YAML | ❌ Not implemented | LOW | High | Medium |
| 9 | Role-based subagent access | ❌ Not implemented | LOW | N/A | Low |
| 10 | Competing hypotheses debug | ✅ Already mentioned | **MEDIUM** | Low | Medium |

**Legend:**
- ❌ Not implemented
- ⚠️ Partial implementation
- ✅ Complete or documented
- **BOLD** = Immediate priority for autonomous execution

---

## Pattern 1: Two-Phase Autonomous Polling 🔥 CRITICAL

**Status**: ❌ Not implemented → 🎯 **Ready for implementation**

**What Antfarm Does**:
- Phase 1: Cheap model (Sonnet 4) polls for work every 5 minutes (~$0.05/hour)
- Phase 2: Expensive model (Opus 4.6) spawned only when work exists (~$2-5/task)
- 40x cost reduction vs continuous expensive model
- Enables true autonomous operation for days/weeks

**Rivets Implementation**:

### Polling Agent Prompt (Sonnet 4)
```markdown
You are an autonomous epic-executor polling agent for epic <epic-id>.

Check for ready work:
```bash
bd ready --parent <epic-id> --json
```

If empty array: Reply "HEARTBEAT_OK" and exit
If tasks found: Call sessions_spawn with work agent prompt

Do NOT attempt work yourself. You are the cheap checker.
```

### Work Agent Prompt (Opus 4.6)
```markdown
You are an autonomous work agent. Execute ONE task, then exit.

1. Claim task: bd update <task-id> in_progress
2. Read learning thread: bd comments <epic-id>
3. Dispatch implementation subagent (Task tool)
4. Two-stage review
5. 5-step verification gate
6. Commit changes
7. Capture learnings: bd comments add
8. Close task: bd close <task-id>
9. Exit (polling agent handles next task)
```

### Command Interface
```bash
# Supervised (current)
/epic-executor <epic-id>

# Autonomous (new)
/epic-executor <epic-id> --autonomous

# With dashboard
/epic-executor <epic-id> --autonomous --dashboard-port 8080

# Stop
touch /tmp/epic-executor-stop-<epic-id>
```

**Benefits**:
- ✅ True autonomous execution (hours/days)
- ✅ 40x cost reduction during idle time
- ✅ Overnight/weekend execution
- ✅ No human supervision needed

**Implementation Files**:
- Design: `ai/completed/autonomous-epic-executor-design.md` ✅
- Prompts: Polling + Work templates included
- Safety: Circuit breakers, rate limiting, manual override

**Estimated Effort**: 2-3 weeks
- Week 1: Basic polling loop + work spawning
- Week 2: Safety features (circuit breaker, abandonment)
- Week 3: Monitoring (progress reports, dashboard)

**Dependencies**: None - can implement immediately

---

## Pattern 2: Database-Driven Coordination ✅ ALREADY EXISTS

**Status**: ✅ **Complete** (Beads native)

**What Antfarm Does**:
- SQLite database for ACID atomic operations
- Atomic step claiming: `UPDATE steps SET status='running' WHERE id=? AND status='pending'`
- No race conditions when multiple agents compete for work
- JSONL export for git sync (5-second debounce)

**Rivets Status**:
✅ **Beads already implements this!**
- Local SQLite database for state management
- JSONL export to `.beads/issues.jsonl` with debounce
- Auto-import after `git pull`
- Atomic task claiming built-in

**Evidence**:
```bash
bd show --help | grep "lock-timeout"
# --lock-timeout duration     SQLite busy timeout (default 30s)

# Beads uses SQLite, not just git!
```

**Conclusion**: No implementation needed. This was a key discovery - we initially thought Beads was "just git-based" but it has full SQLite coordination under the hood.

**Benefit**: Can focus on autonomous patterns instead of rebuilding coordination layer.

---

## Pattern 3: Progress Tracking via Comments 🎯 HIGH PRIORITY

**Status**: ⚠️ Partial → ✅ **Design complete** → 🔨 Ready to implement

**What Antfarm Does**:
- Shared `progress-{runId}.txt` file accumulates discoveries
- Each agent reads it, learns from previous work, appends new patterns
- Example:
  ```
  Story 1: Discovered AuthMiddleware at pkg/auth
  Story 2: Test pattern: testutil.WithTestDB(t)
  Story 3: All endpoints need RequireAuth()
  ```

**Rivets Implementation**: Use Beads comments (better than files!)

### After Each Task (Section 1.6b)
```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task bd-abc123**: Create auth endpoint
**Commit**: abc123d

**Patterns used:**
- AuthMiddleware from bd-abc122
- testutil.WithTestDB(t) for tests

**New discoveries:**
- JWT helper: internal/auth/jwt.go:GenerateToken()
- Handler response structure: {data, error, message}

**Gotchas:**
- JWT middleware MUST be before routes
- Test DB needs admin privileges

**For next tasks:**
- Use jwt.GenerateToken() - don't reinvent
- Follow handler.go:45-67 pattern
EOF
)"
```

### In Subagent Preamble (Section 1.2)
```markdown
## Learning Thread (Previous Task Discoveries)

<Insert last 5 comments:
bd comments <epic-id> --json | \
  jq -r 'sort_by(.created_at) | reverse | limit(5; .[]) |
  "[\(.created_at | split("T")[0])] \(.body)\n---"'
>

**Key Points:**
- Follow patterns from thread above
- Reuse discovered components
- Don't reinvent solutions
```

**Benefits**:
- ✅ Automatic timestamps (Beads metadata)
- ✅ Chronological thread showing evolution
- ✅ Each task sees previous discoveries
- ✅ No repeated mistakes
- ✅ Pattern reuse across tasks

**Implementation Files**:
- Complete spec: `~/labs/rivets/epic-executor-progress-enhancements.md` ✅
- 6 additions ready to copy-paste into epic-executor SKILL.md
- Includes examples, testing steps, migration guide

**Estimated Effort**: 2-3 days
- Add 6 sections to epic-executor SKILL.md
- Test with 3-task epic
- Validate comment formatting

**Dependencies**: None - can implement immediately

---

## Pattern 4: Structured Verify-Retry Feedback 🎯 HIGH PRIORITY

**Status**: ⚠️ Partial → ✅ **Design complete** → 🔨 Ready to implement

**What Antfarm Does**:
- Verifier agent can reject work with specific feedback
- Feedback stored in `verify_feedback` context variable
- Developer's next attempt automatically receives feedback
- Per-story retry limits prevent infinite loops

**Current Epic-Executor**:
- Section 1.4 mentions "dispatch fix subagent with review feedback"
- But doesn't specify HOW feedback is structured/passed

**Rivets Enhancement**:

### Two-Stage Review (Enhanced Section 1.4)
```markdown
#### Stage 1: Spec Compliance Review

If fails:
1. Store feedback: bd update <task-id> --metadata review_feedback="<issues>"
2. Dispatch fix subagent with preamble:
   ```
   PREVIOUS REVIEW FEEDBACK:
   <issues from metadata>

   Address these specific issues. Do not re-implement from scratch.
   ```
3. After fix, re-run ONLY spec review (don't restart quality)
4. Track review cycles: fail after 2 spec failures → mark blocked

#### Stage 2: Code Quality Review

(Only after spec passes)
If fails: Same feedback pattern, separate from spec feedback
```

### In Subagent Preamble
```markdown
<If task has review_feedback metadata:>

## Previous Review Feedback

This task was previously reviewed and needs corrections:

<review_feedback from: bd show <task-id> --json | jq -r '.metadata.review_feedback'>

Address these specific issues. The implementation was close but needs refinement.
```

**Benefits**:
- ✅ Clear feedback loop between review and implementation
- ✅ No wasted work - targeted fixes only
- ✅ Separate spec vs quality feedback
- ✅ Bounded retries prevent infinite loops
- ✅ Works autonomously (no human intervention)

**Implementation Files**:
- Included in: `~/labs/rivets/epic-executor-progress-enhancements.md` ✅
- Also part of autonomous design for autonomous mode

**Estimated Effort**: 1-2 days
- Enhance section 1.4 in epic-executor
- Add metadata handling for feedback
- Test with intentionally failing task

**Dependencies**: Pattern 3 (comments) recommended but not required

---

## Pattern 5: Abandoned Task Recovery 🎯 HIGH PRIORITY

**Status**: ❌ Not implemented → ✅ **Design complete** → 🔨 Ready to implement

**What Antfarm Does**:
- Detects steps stuck in "running" state beyond timeout + 5min buffer
- Separate `abandoned_count` (max 5) vs `retry_count` (max 2)
- More forgiving for timeouts/crashes, strict for explicit failures
- Automatic cleanup on every claim prevents stuck workflows

**Rivets Implementation**:

### Detection (Before Claiming Tasks)
```bash
# Find tasks stuck in in_progress > 35 minutes
ABANDONED=$(bd list --parent <epic-id> --status in_progress --json | \
  jq --arg threshold "$(date -u -d '35 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  'map(select(.updated_at < $threshold)) | .[].id')

for task_id in $ABANDONED; do
  # Get abandon count from metadata
  ABANDON_COUNT=$(bd show "$task_id" --json | jq -r '.metadata.abandon_count // 0')
  NEW_COUNT=$((ABANDON_COUNT + 1))

  if [[ $NEW_COUNT -ge 5 ]]; then
    # Too many abandons - mark blocked
    bd update "$task_id" blocked
    bd comments add <epic-id> "🚫 Task $task_id abandoned $NEW_COUNT times. Marked blocked."
  else
    # Reset to open for retry
    bd update "$task_id" open
    bd update "$task_id" --metadata abandon_count="$NEW_COUNT"
    bd comments add <epic-id> "♻️ Task $task_id reset to open (abandon $NEW_COUNT/5)."
  fi
done
```

### When to Check
- At polling loop start (autonomous mode)
- Before claiming next task (supervised mode)
- Every 10th poll cycle (~50 minutes)

**Benefits**:
- ✅ Automatic recovery from agent crashes
- ✅ Handles network timeouts gracefully
- ✅ Separate tracking for timeouts vs failures
- ✅ Prevents workflows from hanging indefinitely
- ✅ Critical for autonomous operation

**Implementation Files**:
- Included in: `~/labs/rivets/autonomous-epic-executor-design.md` ✅ (Section Phase 2)
- Threshold calculation logic
- Metadata tracking approach

**Estimated Effort**: 2-3 days
- Add cleanup function to epic-executor
- Add metadata tracking to Beads tasks
- Test with simulated timeout/crash

**Dependencies**: None, but most valuable with Pattern 1 (autonomous polling)

---

## Pattern 6: Event-Driven Progress Tracking 📊 MEDIUM PRIORITY

**Status**: ❌ Not implemented

**What Antfarm Does**:
- Emits structured events for all state transitions
- Events: `step.pending`, `step.running`, `step.done`, `step.failed`, etc.
- Dashboard subscribes to events for real-time visualization
- Analytics on task duration, failure patterns
- Audit trail for debugging

**Rivets Implementation**:

### Event Emission (After Each State Transition)
```bash
# Append to epic event log
cat >> ai/current/<epic-id>-events.jsonl <<EOF
{"ts":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","event":"task.started","task":"$TASK_ID","title":"$TITLE"}
EOF

# After review
{"ts":"...","event":"task.review.spec","task":"...","result":"pass"}
{"ts":"...","event":"task.review.quality","task":"...","result":"pass"}

# After verification
{"ts":"...","event":"task.verify","task":"...","command":"npm test","result":"pass"}

# After commit
{"ts":"...","event":"task.committed","task":"...","sha":"abc123"}

# After close
{"ts":"...","event":"task.closed","task":"..."}
```

### Dashboard Query
```bash
# Real-time progress
tail -f ai/current/<epic-id>-events.jsonl | jq -r '.event + " " + .task'

# Analytics
jq -s 'group_by(.event) | map({event: .[0].event, count: length})' \
  ai/current/<epic-id>-events.jsonl

# Task duration
jq -s 'group_by(.task) | map({
  task: .[0].task,
  duration: (.[0].ts | fromdateiso8601) - (.[-1].ts | fromdateiso8601)
})' ai/current/<epic-id>-events.jsonl
```

**Benefits**:
- ✅ Real-time progress visibility
- ✅ Analytics on task duration and patterns
- ✅ Audit trail for debugging
- ✅ Future: Web dashboard showing live progress

**Estimated Effort**: 1 week
- Add JSONL event logging to epic-executor
- Create dashboard viewing script
- Add analytics queries

**Dependencies**: None, but most valuable with Pattern 1 (autonomous mode needs monitoring)

**Priority**: Medium - valuable for monitoring autonomous execution, but comments already provide progress tracking

---

## Pattern 7: Staggered Parallel Execution 📉 LOW PRIORITY

**Status**: ❌ Not implemented

**What Antfarm Does**:
- When multiple agents exist, stagger polling by 1 minute each
- Agent 0: polls at :00, :05, :10
- Agent 1: polls at :01, :06, :11
- Agent 2: polls at :02, :07, :12
- Prevents thundering herd on database/filesystem

**Rivets Potential Use**:
If epic-executor manages multiple sub-tasks simultaneously:
```bash
# Identify independent task groups
INDEPENDENT_TASKS=$(analyze_dependencies <epic-id>)

# Spawn with staggered delays
for i in "${!INDEPENDENT_TASKS[@]}"; do
  DELAY=$((i * 30))  # 30 seconds apart
  (sleep $DELAY && execute_task "${INDEPENDENT_TASKS[$i]}") &
done
```

**Benefits**:
- ✅ Prevents resource contention
- ✅ Smoother load on git/filesystem
- ✅ Reduces chance of merge conflicts

**Estimated Effort**: 3-4 days
- Add dependency analysis
- Identify truly independent tasks
- Add staggered spawning logic
- Handle conflicts gracefully

**Dependencies**: Pattern 1 (autonomous polling)

**Priority**: Low - most epics process tasks sequentially; parallel execution is edge case

---

## Pattern 8: Declarative Workflow YAML 📄 LOW PRIORITY

**Status**: ❌ Not implemented

**What Antfarm Does**:
- Workflows defined in YAML: agents, steps, loop config, verify-retry policies
- Example: `workflow.yml` defines entire multi-agent pipeline
- Enables reusable workflow templates

**Rivets Potential**:
```yaml
# ai/workflows/feature-implementation.yml
id: feature-implementation
name: Feature Implementation Workflow

agents:
  - id: implementer
    role: coding
    model: claude-opus-4-6
  - id: reviewer
    role: verification
    model: claude-sonnet-4

steps:
  - id: implement
    agent: implementer
    type: loop
    loop:
      over: tasks
      verify_each: true
      verify_step: review
    max_retries: 2

  - id: review
    agent: reviewer
    on_fail:
      retry_step: implement
      max_retries: 2
```

**Benefits**:
- ✅ Non-programmer accessibility
- ✅ Version-controlled workflows
- ✅ Reusable templates
- ✅ Multiple workflow presets

**Estimated Effort**: 2-3 weeks
- Design YAML schema
- Create parser/validator
- Implement workflow engine
- Migrate epic-executor to use YAML

**Dependencies**: Pattern 1 (works best with autonomous execution)

**Priority**: Low - epic-executor skill is already declarative enough for most use cases

---

## Pattern 9: Role-Based Subagent Access Control 🔒 LOW PRIORITY

**Status**: ❌ Not implemented (needs platform support)

**What Antfarm Does**:
- Agent roles define tool access: `analysis`, `coding`, `verification`, `testing`
- Verification role: Read + Exec, but **NO Write**
- Ensures verifier can't "fix" issues instead of sending back to developer
- Enforces principle of least privilege

**Rivets Current**:
All epic-executor subagents are `general-purpose` with full tool access

**Potential Enhancement**:
```markdown
### 1.3 Dispatch Fresh Subagent (Enhanced)

Choose subagent type based on phase:

| Phase | Subagent Type | Tools |
|-------|--------------|-------|
| Implementation | general-purpose | Full read/write/exec |
| Spec Review | analysis | Read + limited exec |
| Quality Review | verification | Read + exec, NO write |
| Debug | explore | Read-only, optimized search |
```

**Blocker**: Claude Code would need to support tool restrictions per subagent type

**Benefits**:
- ✅ Prevents reviewer from fixing issues
- ✅ Enforces proper verify-retry flow
- ✅ Better security boundaries

**Estimated Effort**: N/A - requires platform feature

**Priority**: Low - nice-to-have, but workarounds exist (prompt-based instructions)

---

## Pattern 10: Competing Hypotheses Debug 🔬 MEDIUM PRIORITY

**Status**: ⚠️ Mentioned in Phase 3.3 → ✅ Can enhance

**What Antfarm Does**:
- After 2 failures on same issue, spawn 3 debug agents in parallel
- Each explores different hypothesis
- Compare findings, apply strongest fix

**Current Epic-Executor**:
Phase 3.3 mentions this but could be more detailed

**Enhancement**:
```markdown
### 3.3 Competing Hypotheses (Enhanced)

If verification fails 2+ times on same issue:

**Step 1: Generate Hypotheses**
Based on error pattern:
- Hypothesis A: <most likely cause>
- Hypothesis B: <second likely cause>
- Hypothesis C: <edge case possibility>

**Step 2: Spawn 3 Debug Agents in Parallel**
```
Use Task tool (parallel):
Task 1: "Investigate Hypothesis A: <description>"
Task 2: "Investigate Hypothesis B: <description>"
Task 3: "Investigate Hypothesis C: <description>"
```

**Step 3: Wait for All to Complete**
Do not proceed until all 3 report back

**Step 4: Score Hypotheses**
- Evidence strength: weak/moderate/strong
- Fix complexity: simple/medium/complex
- Risk level: low/medium/high

**Step 5: Apply Best Fix**
Implement fix from highest-scoring hypothesis

**Step 6: If All Fail**
Hard stop, escalate to human with all 3 reports
```

**Benefits**:
- ✅ Breaks out of stuck debugging loops
- ✅ Parallel investigation saves time
- ✅ Multiple perspectives increase success rate
- ✅ Critical for autonomous operation

**Estimated Effort**: 2-3 days
- Enhance Phase 3.3 in epic-executor
- Add hypothesis generation logic
- Add scoring system

**Dependencies**: None

**Priority**: Medium - valuable for autonomous reliability

---

## Implementation Priority Order

Based on autonomous execution strategy:

### Phase 1: Foundation (Week 1-2)
**Goal**: Enable autonomous execution with basic safety

1. **Pattern 3**: Progress tracking via comments ✅ Design complete
   - 2-3 days implementation
   - Copy-paste from `epic-executor-progress-enhancements.md`

2. **Pattern 4**: Structured verify-retry feedback ✅ Design complete
   - 1-2 days implementation
   - Included in progress enhancements

3. **Pattern 1**: Two-phase autonomous polling ✅ Design complete
   - 1 week core implementation
   - Polling + work agent prompts from `autonomous-epic-executor-design.md`

### Phase 2: Safety & Reliability (Week 3-4)
**Goal**: Production-ready autonomous operation

4. **Pattern 5**: Abandoned task recovery ✅ Design complete
   - 2-3 days implementation
   - Critical for autonomous reliability

5. **Pattern 10**: Enhanced competing hypotheses
   - 2-3 days implementation
   - Improves autonomous debugging

### Phase 3: Monitoring & Analytics (Week 5-6)
**Goal**: Observability for long-running autonomous execution

6. **Pattern 6**: Event-driven progress tracking
   - 1 week implementation
   - Dashboard for monitoring autonomous runs

### Phase 4: Advanced Features (Future)
**Goal**: Optimization and scale

7. **Pattern 7**: Staggered parallel execution (if needed)
8. **Pattern 8**: Declarative workflow YAML (if needed)
9. **Pattern 9**: Role-based access (pending platform support)

---

## Success Metrics

### Phase 1 Success Criteria
- [ ] Epic-executor runs autonomously for 8+ hours
- [ ] Completes 10+ tasks without intervention
- [ ] Learning thread properly accumulates knowledge
- [ ] Cost <$5/hour (vs $50+/hour for continuous Opus)

### Phase 2 Success Criteria
- [ ] Automatic recovery from 2+ abandoned tasks
- [ ] Circuit breaker prevents runaway failures
- [ ] Manual stop/pause/resume works reliably
- [ ] Zero stuck workflows (all terminate cleanly)

### Phase 3 Success Criteria
- [ ] Real-time dashboard shows current progress
- [ ] Event log enables post-mortem analysis
- [ ] Analytics show task duration patterns
- [ ] Can monitor 5+ epics simultaneously

---

## Cost Analysis

### Current (Supervised)
- User runs epic-executor once
- Opus 4.6 runs continuously
- Cost: ~$50-100/hour for large epics
- Requires constant supervision

### After Pattern 1 (Autonomous)
- Polling: Sonnet 4 @ $0.05/hour
- Work: Opus 4.6 only when tasks ready @ $2-5/task
- Typical: ~$2-5/hour average
- **40x cost reduction during idle time**
- Zero supervision needed

---

## Documentation Status

| Pattern | Design Doc | Implementation Guide | Examples | Tests |
|---------|-----------|---------------------|----------|-------|
| 1. Autonomous polling | ✅ Complete | ✅ Ready | ✅ Included | ⚠️ TODO |
| 2. Database coordination | ✅ N/A (exists) | N/A | N/A | N/A |
| 3. Progress comments | ✅ Complete | ✅ Ready | ✅ Included | ⚠️ TODO |
| 4. Verify-retry feedback | ✅ Complete | ✅ Ready | ✅ Included | ⚠️ TODO |
| 5. Abandoned recovery | ✅ Complete | ✅ Ready | ✅ Included | ⚠️ TODO |
| 6. Event tracking | ⚠️ Outlined | ⚠️ TODO | ⚠️ TODO | ⚠️ TODO |
| 7. Staggered parallel | ⚠️ Outlined | ⚠️ TODO | ❌ None | ⚠️ TODO |
| 8. Declarative YAML | ⚠️ Outlined | ❌ TODO | ❌ None | ⚠️ TODO |
| 9. Role-based access | ⚠️ Outlined | ❌ Blocked | ❌ None | N/A |
| 10. Competing hypotheses | ⚠️ Outlined | ⚠️ TODO | ⚠️ TODO | ⚠️ TODO |

---

## Next Actions

### Immediate (This Week)
1. ✅ Review `epic-executor-progress-enhancements.md`
2. ✅ Review `autonomous-epic-executor-design.md`
3. 📝 Implement Pattern 3 (progress comments) - 2-3 days
4. 📝 Implement Pattern 4 (verify-retry feedback) - 1-2 days

### Near-Term (Next 2 Weeks)
5. 📝 Implement Pattern 1 (autonomous polling) - 1 week
6. 📝 Implement Pattern 5 (abandoned recovery) - 2-3 days
7. 🧪 Test with real epic (10+ tasks)
8. 📝 Document autonomous usage

### Mid-Term (Next Month)
9. 📝 Implement Pattern 6 (event tracking)
10. 📝 Enhance Pattern 10 (competing hypotheses)
11. 📝 Create monitoring dashboard
12. 📊 Gather metrics and optimize

---

## Key Insights from Research

1. **Beads is Perfect Foundation** ✅
   - Already has SQLite for atomic operations
   - Already has dependency management
   - Already has git integration
   - Just need autonomous layer on top

2. **Comments > Notes for Progress** ✅
   - Automatic timestamps
   - Native threading
   - Better for chronological learning
   - Easier to query

3. **Two-Phase is Key to Autonomy** ✅
   - Cheap polling enables continuous monitoring
   - Expensive work only when needed
   - 40x cost reduction
   - Makes days-long execution feasible

4. **Safety Must Be Built-In** ✅
   - Circuit breakers prevent runaway failures
   - Abandoned task recovery critical
   - Rate limiting prevents resource exhaustion
   - Manual override always available

5. **Fresh Context per Task** ✅
   - Already part of epic-executor philosophy
   - Prevents context pollution
   - Learning thread provides continuity
   - Perfect for autonomous operation

---

## Comparison: Rivets vs Antfarm

| Aspect | Antfarm | Rivets (Current) | Rivets (After Patterns) |
|--------|---------|------------------|------------------------|
| **Foundation** | SQLite + cron | Beads (SQLite + JSONL) | Same |
| **Execution** | Fully autonomous | Supervised | Fully autonomous ✅ |
| **Cost Model** | 2-phase polling | Continuous expensive | 2-phase polling ✅ |
| **Learning** | progress.txt file | Manual | Comment thread ✅ |
| **Recovery** | Auto-abandon detect | Manual intervention | Auto-abandon detect ✅ |
| **Monitoring** | Events + dashboard | Terminal output | Events + dashboard ✅ |
| **Duration** | Days/weeks | Single session | Days/weeks ✅ |
| **Use Case** | Full CI/CD automation | Interactive planning | Full autonomous execution ✅ |

**Result**: Rivets will match or exceed Antfarm's autonomous capabilities while keeping the interactive planning and brainstorming strengths!

---

## Credits

Research: `ai/research/2026-02-13_multi-agent-architecture.md`
Design Documents:
- `ai/completed/epic-executor-progress-enhancements.md`
- `ai/completed/autonomous-epic-executor-design.md`

Inspired by Antfarm's multi-agent workflow system, adapted for Rivets' Beads-based tracking and verification-first philosophy.
