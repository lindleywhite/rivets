# Validate Plan

You are tasked with validating that an implementation plan was correctly executed, verifying all success criteria and identifying any deviations or issues.

## Initial Setup

When invoked:
1. **Determine context** - Are you in an existing conversation or starting fresh?
   - If existing: Review what was implemented in this session
   - If fresh: Need to discover what was done through git and codebase analysis

2. **Locate the plan**:
   - If plan path provided, use it
   - Otherwise, search recent commits for plan references or ask user

3. **Gather implementation evidence**:
   ```bash
   git log --oneline -n 20
   git diff HEAD~N..HEAD
   ```

## Validation Process

### Step 1: Context Discovery

If starting fresh or need more context:

1. **Read the implementation plan** completely
2. **Identify what should have changed**:
   - List all files that should be modified
   - Note all success criteria (automated and manual)
   - Identify key functionality to verify

3. **Spawn parallel research tasks** to discover implementation:
   - Task 1: Verify database/schema changes match plan
   - Task 2: Verify code changes match plan specifications
   - Task 3: Verify test coverage was added as specified

### Step 2: Systematic Validation

For each phase in the plan:

1. **Check completion status**:
   - Look for checkmarks in the plan (- [x])
   - Verify the actual code matches claimed completion

2. **Run automated verification**:
   - Execute each command from "Automated Verification"
   - Document pass/fail status
   - If failures, investigate root cause

3. **Assess manual criteria**:
   - List what needs manual testing
   - Provide clear steps for user verification

4. **Think deeply about edge cases**:
   - Were error conditions handled?
   - Are there missing validations?
   - Could the implementation break existing functionality?

### Step 3: Generate Validation Report

Create comprehensive validation summary:

```markdown
## Validation Report: [Plan Name]

### Implementation Status
[checkmark] Phase 1: [Name] - Fully implemented
[warning] Phase 3: [Name] - Partially implemented (see issues)

### Automated Verification Results
[checkmark] Build passes
[checkmark] Tests pass
[x] Linting issues: 3 warnings

### Code Review Findings

#### Matches Plan:
- [What was implemented correctly]

#### Deviations from Plan:
- [Differences from spec]

#### Potential Issues:
- [Concerns discovered]

### Manual Testing Required:
1. [Specific manual test steps]

### Recommendations:
- [Actionable next steps]
```

## Important Guidelines

1. **Be thorough but practical** - Focus on what matters
2. **Run all automated checks** - Don't skip verification commands
3. **Document everything** - Both successes and issues
4. **Think critically** - Question if the implementation truly solves the problem
5. **Consider maintenance** - Will this be maintainable long-term?

## Relationship to Other Commands

This command is **Stage 6** of the unified engineering pipeline:

```
/research_codebase -> /create_plan -> /audit-plans -> /plan-to-epic -> /epic-executor -> /validate_plan
```

**Typical usage paths:**
- After `/epic-executor` completes an epic - validate the full implementation
- After `/implement_plan` - validate a direct implementation
- Standalone - audit any plan's implementation status

See the plugin's `references/unified-workflow-guide.md` for the full workflow and decision guide.
