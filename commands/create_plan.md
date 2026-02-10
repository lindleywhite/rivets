# Implementation Plan

You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a file path or ticket reference was provided as a parameter, skip the default message
   - Immediately read any provided files FULLY
   - Begin the research process

2. **If no parameters provided**, respond with:
```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a ticket file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a file directly: `/create_plan path/to/ticket.md`
For deeper analysis, try: `/create_plan think deeply about path/to/ticket.md`
```

Then wait for the user's input.

## Process Steps

### Step 1: Context Gathering & Initial Analysis

1. **Read all mentioned files immediately and FULLY**:
   - Ticket files, research documents, related plans, data files
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: DO NOT spawn sub-tasks before reading these files yourself in the main context
   - **NEVER** read files partially - if a file is mentioned, read it completely

2. **Spawn initial research tasks to gather context**:
   Before asking the user any questions, use specialized agents to research in parallel:

   - Use the **codebase-locator** agent to find all files related to the ticket/task
   - Use the **codebase-analyzer** agent to understand how the current implementation works
   - If relevant, use the **ai-locator** agent to find any existing AI documents about this feature

   These agents will:
   - Find relevant source files, configs, and tests
   - Trace data flow and key functions
   - Return detailed explanations with file:line references

3. **Read all files identified by research tasks**:
   - After research tasks complete, read ALL files they identified as relevant
   - Read them FULLY into the main context

4. **Analyze and verify understanding**:
   - Cross-reference the ticket requirements with actual code
   - Identify any discrepancies or misunderstandings
   - Note assumptions that need verification
   - Determine true scope based on codebase reality

5. **Present informed understanding and focused questions**:
   ```
   Based on the ticket and my research of the codebase, I understand we need to [accurate summary].

   I've found that:
   - [Current implementation detail with file:line reference]
   - [Relevant pattern or constraint discovered]
   - [Potential complexity or edge case identified]

   Questions that my research couldn't answer:
   - [Specific technical question that requires human judgment]
   - [Business logic clarification]
   - [Design preference that affects implementation]
   ```

   Only ask questions that you genuinely cannot answer through code investigation.

### Step 2: Research & Discovery

After getting initial clarifications:

1. **If the user corrects any misunderstanding**:
   - DO NOT just accept the correction
   - Spawn new research tasks to verify the correct information
   - Read the specific files/directories they mention
   - Only proceed once you've verified the facts yourself

2. **Create a research todo list** using TodoWrite to track exploration tasks

3. **Spawn parallel sub-tasks for comprehensive research**:
   - Create multiple Task agents to research different aspects concurrently:
   - **codebase-locator** - Find specific files
   - **codebase-analyzer** - Understand implementation details
   - **codebase-pattern-finder** - Find similar features to model after
   - **ai-locator** - Find existing AI documents about this area
   - **ai-analyzer** - Extract key insights from the most relevant documents

4. **Wait for ALL sub-tasks to complete** before proceeding

5. **Present findings and design options**:
   ```
   Based on my research, here's what I found:

   **Current State:**
   - [Key discovery about existing code]
   - [Pattern or convention to follow]

   **Design Options:**
   1. [Option A] - [pros/cons]
   2. [Option B] - [pros/cons]

   Which approach aligns best with your vision?
   ```

### Step 3: Plan Structure Development

Once aligned on approach:

1. **Create initial plan outline** and get feedback on structure before writing details

### Step 4: Detailed Plan Writing

After structure approval:

1. **Scaffold the plan file** using the helper script (if available):
   ```bash
   bash .claude/skills/audit-plans/scripts/scaffold_plan.sh "descriptive name" --owner <owner> --tags "tag1,tag2"
   ```
   If the scaffold script isn't available, create the file manually at `ai/current/YYYY-MM-DD-{descriptive-name}.md`.

2. **Fill in the template**:

```markdown
---
date: [ISO timestamp]
status: planning
owner: [team/person]
dependencies: []
tags: [implementation, feature-name]
---

# [Feature/Task Name] Implementation Plan

## Overview

[Brief description of what we're implementing and why]

## Current State Analysis

[What exists now, what's missing, key constraints discovered]

### Key Discoveries:
- [Important finding with file:line reference]

## Desired End State

[Specification of the desired end state and how to verify it]

## What We're NOT Doing

[Explicitly list out-of-scope items to prevent scope creep]

## Implementation Approach

[High-level strategy and reasoning]

## Phase 1: [Descriptive Name]

### Overview
[What this phase accomplishes]

### Changes Required:

#### 1. [Component/File Group]
**File**: `path/to/file.ext`
**Changes**: [Summary of changes]

### Success Criteria:

#### Automated Verification:
- [ ] Tests pass
- [ ] Type checking passes
- [ ] Linting passes

#### Manual Verification:
- [ ] Feature works as expected
- [ ] No regressions in related features

---

## Phase 2: [Descriptive Name]

[Similar structure...]

---

## Testing Strategy

### Unit Tests:
- [What to test]

### Integration Tests:
- [End-to-end scenarios]

## References

- Related research: `ai/research/[relevant].md`
- Similar implementation: `[file:line]`
```

### Step 5: Sync and Review

1. **Present the draft plan location** and iterate based on feedback
2. **Continue refining** until the user is satisfied

## Important Guidelines

1. **Be Skeptical**: Question vague requirements, identify issues early, verify with code
2. **Be Interactive**: Don't write the full plan in one shot, get buy-in at each step
3. **Be Thorough**: Read all context files COMPLETELY, include specific file:line references
4. **Be Practical**: Focus on incremental, testable changes. Include "what we're NOT doing"
5. **No Open Questions in Final Plan**: Research or ask for clarification immediately. The plan must be complete and actionable.

## Success Criteria Guidelines

**Always separate success criteria into two categories:**

1. **Automated Verification** (can be run by execution agents):
   - Commands that can be run: `go test ./...`, `npm run lint`, etc.
   - Specific files that should exist
   - Code compilation/type checking

2. **Manual Verification** (requires human testing):
   - UI/UX functionality
   - Performance under real conditions
   - Edge cases that are hard to automate

## Sub-task Spawning Best Practices

- **Spawn multiple tasks in parallel** for efficiency
- **Each task should be focused** on a specific area
- **Be EXTREMELY specific about directories** in prompts
- **Wait for all tasks to complete** before synthesizing
- **Verify sub-task results** against actual codebase
