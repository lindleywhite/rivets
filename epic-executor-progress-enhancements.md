# Epic-Executor Progress Tracking Enhancements

Complete additions for integrating Beads comment-based cross-task learning into epic-executor.

**Source**: Antfarm research on progress file pattern, adapted for Beads comments.

---

## Addition 1: Initialize Progress Tracking

**Location**: After Section 0.2 (line ~72)
**Insert after**: "Read the full plan to understand architectural decisions, constraints, and implementation order."

```markdown
### 0.2b Initialize Progress Tracking (Beads mode only)

Set up the epic for cross-task learning by adding an initial comment:

```bash
# Check if epic already has comments
COMMENT_COUNT=$(bd comments <epic-id> --json 2>/dev/null | jq 'length' || echo 0)

# If no comments yet, add initialization comment
if [[ "$COMMENT_COUNT" -eq 0 ]]; then
  bd comments add <epic-id> "$(cat <<'EOF'
📋 **Epic Initialized**

Cross-task learning enabled. Each completed task will append:
- Patterns discovered
- Gotchas encountered
- Reusable components

Future tasks will read this thread to avoid repeating discoveries.
EOF
)"
fi
```

This creates a comment thread that accumulates knowledge throughout epic execution.

**File mode:**

Create initial progress file:

```bash
if [[ ! -f ai/current/<epic-name>-progress.md ]]; then
  cat > ai/current/<epic-name>-progress.md <<'EOF'
# Epic Progress: <epic-name>

Cross-task learning log. Each completed task appends discoveries here.

---
EOF
fi
```
```

---

## Addition 2: Enhanced Subagent Preamble with Learning Thread

**Location**: Replace Section 1.2 (lines ~129-145)
**Replace entire section with**:

```markdown
### 1.2 Subagent Preamble Template

Every subagent receives this enhanced preamble with accumulated learning from previous tasks.

**Beads mode:**

```
## Epic Context

**Epic**: <epic-id> - <epic-title>
**Current Task**: <task-id> - <task-title>

## Learning Thread (Previous Task Discoveries)

<Insert content from last 5 completed task comments:

bd comments <epic-id> --json 2>/dev/null | \
  jq -r 'sort_by(.created_at) | reverse | limit(5; .[]) |
  "[\(.created_at | split("T")[0])] \(.body)\n---\n"' || \
  echo "No previous learnings yet - you're the first task!"

>

**Key Points from Thread:**
- Read the patterns and gotchas above before starting
- Reuse components and approaches already discovered
- Don't reinvent solutions that previous tasks already found
- If you discover new patterns, they'll be added to this thread

## Standard Instructions

1. Read CLAUDE.md first for project conventions, commands, and architecture
2. Read existing code in the area you're modifying BEFORE writing anything
3. **Follow patterns from the learning thread above** - these were discovered by previous tasks
4. Focus ONLY on this task — do not refactor surrounding code, add features not requested,
   or "improve" things outside scope. If you discover issues, note them but do not fix them
5. Do NOT commit — leave changes staged or unstaged. The orchestrator handles commits
6. Run tests after implementation to verify your work
7. Keep it simple — implement the minimum needed to satisfy acceptance criteria
```

**File mode:**

```
## Task Context

**Task**: <task-number> - <task-title>
**File**: <task-tracking-file>

## Previous Progress (if exists)

<Insert content from: cat ai/current/<epic-name>-progress.md 2>/dev/null || echo "None yet">

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

**Rationale**: Fresh subagents now see the accumulated knowledge without needing to query multiple sources. The learning thread is automatically chronological and timestamped.
```

---

## Addition 3: Capture Task Learnings in Comment Thread

**Location**: After Section 1.6 (line ~214)
**Insert after**: Incremental Commit section, before 1.7

```markdown
### 1.6b Capture Task Learnings

After successful commit, add this task's discoveries to the learning thread.

**Beads mode:**

Add a structured comment to the epic:

```bash
bd comments add <epic-id> "$(cat <<'EOF'
✅ **Task <task-id>**: <task-title>
**Commit**: <short-sha>

**Implementation:**
- Files: <primary files modified>
- Time: ~<minutes> minutes
- Tests: <test files or commands>

**Patterns used from thread:**
- <which previous discoveries were applied>
- <what worked well from prior learnings>

**New patterns discovered:**
- <new reusable components or approaches>
- <architectural decisions made>
- <test patterns established>

**Gotchas encountered:**
- <issues that slowed progress>
- <non-obvious requirements>
- <things to watch for in future tasks>

**For next tasks:**
- <specific recommendations based on this work>
- <files/functions to reference: path/to/file.go:45-67>
EOF
)"
```

**Example:**

```bash
bd comments add bd-epic-auth "$(cat <<'EOF'
✅ **Task bd-a1b2c3**: Create GetToken endpoint
**Commit**: abc123d

**Implementation:**
- Files: internal/auth/handler.go, internal/auth/handler_test.go
- Time: ~8 minutes
- Tests: TestGetToken_Success, TestGetToken_InvalidCreds

**Patterns used from thread:**
- AuthMiddleware pattern from bd-a1b2c2
- testutil.WithTestDB(t) for test setup
- errors.Wrap() for error context

**New patterns discovered:**
- JWT token generation helper: internal/auth/jwt.go:GenerateToken()
- Mock auth service pattern: internal/auth/mocks/auth_service.go
- Handler response structure: Always return {data, error, message}

**Gotchas encountered:**
- JWT middleware MUST be registered before routes (order matters in router.Use())
- Test DB requires admin privileges - use testutil.RequireAdmin(t)
- Token expiry must be set or tokens never expire (default: 0)

**For next tasks:**
- Use jwt.GenerateToken() - don't create new token logic
- Follow handler response structure (see handler.go:45-67)
- All auth endpoints need RequireAuth() middleware
EOF
)"
```

Also update the task's design field for quick reference:

```bash
bd update <task-id> --design "Created GetToken endpoint using JWT helper. Established handler response pattern. See epic comment for details."
```

**File mode:**

Append to progress file:

```bash
cat >> ai/current/<epic-name>-progress.md <<'EOF'

---

## Task <N>: <task-title>
**Date**: <YYYY-MM-DD>
**Commit**: <sha>

### Patterns discovered:
- <new reusable pattern>

### Tests:
- <test approach>

### Gotchas:
- <issues encountered>

### For next tasks:
- <specific recommendations>

EOF
```

**Rationale**: Each task contributes to the collective knowledge. Future tasks read the comment thread and immediately see what's been learned, avoiding redundant discoveries and mistakes.
```

---

## Addition 4: Update Living Plan

**Location**: Replace Section 1.7 (lines ~216-220)
**Enhance existing section with**:

```markdown
### 1.7 Living Documentation Update

After closing a task, update the source plan to reflect progress.

#### 1.7a Source Plan Checkbox

Update the source plan document:
- Find the corresponding `- [ ]` checkbox
- Update to `- [x]`

This keeps the plan synchronized with actual implementation status.

#### 1.7b Verify Learning Capture (Beads mode only)

Confirm the comment was added successfully:

```bash
# Verify last comment matches this task
LAST_COMMENT=$(bd comments <epic-id> --json | jq -r 'sort_by(.created_at) | reverse | .[0] | .body')

if [[ "$LAST_COMMENT" == *"<task-id>"* ]]; then
  echo "✓ Learning captured in epic comment thread"
else
  echo "⚠ Warning: Task learning may not have been captured"
fi
```

**File mode:**

Verify progress file was updated:

```bash
if tail -5 ai/current/<epic-name>-progress.md | grep -q "Task <N>"; then
  echo "✓ Learning captured in progress file"
else
  echo "⚠ Warning: Progress file may not have been updated"
fi
```
```

---

## Addition 5: Knowledge Summary in Final Report

**Location**: After Section 4.2 (line ~314)
**Insert after**: Test Results section

```markdown
### 4.2b Knowledge Summary

Display the accumulated learning from all tasks.

**Beads mode:**

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 KNOWLEDGE ACCUMULATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show comment thread summary
COMMENT_COUNT=$(bd comments <epic-id> --json | jq 'length')
echo "Learning entries: $COMMENT_COUNT"
echo ""

# Extract key patterns from comments
echo "Key Patterns Discovered:"
bd comments <epic-id> --json | \
  jq -r '.[] | select(.body | contains("patterns discovered")) | .body' | \
  grep -A 5 "patterns discovered" | \
  grep "^-" | \
  sort -u | \
  head -10

echo ""
echo "Common Gotchas:"
bd comments <epic-id> --json | \
  jq -r '.[] | select(.body | contains("Gotchas")) | .body' | \
  grep -A 3 "Gotchas" | \
  grep "^-" | \
  sort -u | \
  head -10

echo ""
echo "Full learning thread: bd comments <epic-id> --json | jq"
echo "Or read chronologically: bd show <epic-id> --thread"
```

**File mode:**

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 KNOWLEDGE ACCUMULATED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ -f ai/current/<epic-name>-progress.md ]]; then
  ENTRY_COUNT=$(grep -c "^## Task" ai/current/<epic-name>-progress.md)
  echo "Learning entries: $ENTRY_COUNT"
  echo ""
  echo "Progress log: ai/current/<epic-name>-progress.md"
else
  echo "No progress file found"
fi
```

**Rationale**: At epic completion, show a summary of all accumulated knowledge. This helps with documentation, onboarding, and understanding what was learned during implementation.
```

---

## Addition 6: Enhanced Phase 0 Summary

**Location**: Enhance Section 0.4 (line ~86)
**Add to the summary display**:

```markdown
### 0.4 Present Summary & Get Approval

```
Epic: <title> (<id or file>)
Tasks: <count> total, <ready> ready, <blocked> blocked
Source Plan: <path>

**Beads mode only:**
Learning tracking: ENABLED (via comment thread)
Previous learnings: <N> comments (bd show <epic-id> --thread)

Risk Flags:
  - HIGH: <task> "<title>" — <risk category>

Proposed execution order:
  1. <task>: <title>
  2. <task>: <title>
  ...

Proceed? (waiting for user confirmation)
```

**Do NOT proceed to Phase 1 until the user explicitly approves.**
```

---

## Summary of Changes

| Section | Change Type | Purpose |
|---------|-------------|---------|
| 0.2b | INSERT | Initialize comment thread for learning |
| 0.4 | ENHANCE | Show learning status in approval |
| 1.2 | REPLACE | Pass learning thread to subagents |
| 1.6b | INSERT | Capture task discoveries after commit |
| 1.7 | ENHANCE | Add learning verification step |
| 4.2b | INSERT | Display accumulated knowledge summary |

---

## Benefits of This Implementation

1. **Automatic chronology** - Beads timestamps every learning entry
2. **Fresh subagent context** - Each new task sees previous discoveries
3. **No repeated mistakes** - Gotchas documented and visible
4. **Pattern reuse** - Components discovered once, used by all subsequent tasks
5. **Knowledge persistence** - Survives context compaction, stored in git
6. **Debugging support** - "What did we know after task 5?" → read comment thread up to that date
7. **Documentation by-product** - Epic comment thread becomes implementation journal

---

## Testing the Implementation

After adding these sections, test with:

```bash
# 1. Create test epic
bd create "Test Epic" --type epic --description "Testing progress tracking"

# 2. Create test task
bd create "Test Task 1" --parent <epic-id> --type task

# 3. Run epic-executor with one task
/epic-executor <epic-id>

# 4. Verify comment was added
bd show <epic-id> --thread

# 5. Create second task
bd create "Test Task 2" --parent <epic-id> --type task

# 6. Verify second task sees first task's learnings in preamble
/epic-executor <epic-id> --resume
```

---

## Migration Guide

If you have existing epics without comment-based learning:

```bash
# Convert existing progress files to comments
for epic in $(bd list --type epic --status in_progress --json | jq -r '.[].id'); do
  if [[ -f ai/current/${epic}-progress.md ]]; then
    echo "Migrating $epic"
    bd comments add "$epic" "$(cat ai/current/${epic}-progress.md)"
  fi
done
```

---

## Comparison to Antfarm

| Feature | Antfarm | Rivets (this implementation) |
|---------|---------|------------------------------|
| Storage | `progress-{runId}.txt` file | Beads comment thread |
| Structure | Freeform markdown | Structured per-task entries |
| Timestamps | Manual | Automatic (Beads metadata) |
| Query | `cat file` | `bd comments --json` |
| Persistence | File → archived | SQLite → git JSONL |
| Threading | Append-only file | Native comment thread |
| Cross-session | Via file read | Via database query |

---

## Future Enhancements

Potential additions building on this foundation:

1. **Pattern extraction**: Automated extraction of common patterns into epic notes
2. **Gotcha detection**: Warning system when task keywords match known gotchas
3. **Learning metrics**: Track discovery rate, pattern reuse frequency
4. **AI summarization**: Periodic synthesis of comment thread into consolidated doc
5. **Cross-epic learning**: Query patterns from related epics

---

## Credits

Pattern inspired by Antfarm's `progress-{runId}.txt` approach, adapted to leverage Beads' native comment threading and timestamping capabilities.
