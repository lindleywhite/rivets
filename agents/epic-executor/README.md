# Epic-Executor Specialized Agents

Specialized agents for domain-specific task execution within the epic-executor workflow.

## Agent Types

### Tier 1: Critical Specialists (High Risk)
- **migration-specialist**: Database migrations, schema changes, data integrity
- **security-specialist**: Authentication, authorization, OWASP compliance

### Tier 2: Domain Specialists (Medium Risk)
- **backend-specialist**: API endpoints, handlers, business logic
- **frontend-specialist**: UI components, state management, accessibility
- **refactor-specialist**: Safe refactoring, impact analysis

### Tier 3: Quality Specialists (Low Risk)
- **test-specialist**: Test implementation, TDD patterns, coverage

### Special Agents (Not Task Executors)
- **verification-agent**: Reference implementation for the quality review process that work agents follow (not dispatched as separate subagent; defines review standards in Step 6 of autonomous-executor workflow)
- **learning-agent**: Pattern extraction and knowledge synthesis (runs after epic completion in background as separate subagent)

## Agent Structure

Each agent definition includes:

```yaml
---
name: agent-name
type: epic-executor-agent
triggers: [keyword, patterns, that, activate, this, agent]
risk_level: [low|medium|high]
---

# Agent Name

## Role
[Role identity and expertise area]

## Goal
[Primary objective and success criteria]

## Backstory
[Context and experience that shapes behavior]

## Core Competencies
[Key capabilities and knowledge areas]

## Mandatory Checks
[Required validations before implementation]

## Tools & Patterns
[Specific tools, utilities, and approaches to use]

## Learning Contribution Format
[How this agent structures discoveries for the epic comment thread]

## Red Flags
[Conditions that require escalation or user confirmation]

## Integration with Progress Enhancement
[How agent uses and contributes to the learning thread]
```

## Usage

Epic-executor automatically selects the appropriate agent based on task analysis:

1. **Task Classification**: Analyzes task title, description, and metadata
2. **Agent Selection**: Matches keywords/patterns to agent triggers
3. **Preamble Construction**: Combines learning thread + agent instructions
4. **Dispatch**: Launches specialized agent with focused context
5. **Verification**: Work agent applies verification-agent quality standards
6. **Knowledge Capture**: Agent contributes structured discoveries to epic thread

## Selection Logic

Agents are selected based on keyword matching, ordered by specificity:

```bash
# Keyword-based classification (ordered by specificity)
TASK_TEXT="$TASK_TITLE $TASK_DESC"

# High-risk specialists (most specific)
if [[ "$TASK_TEXT" =~ (migration|schema|alter table|database|add column|drop column|create table|index|constraint|foreign key|rollback) ]]; then
  AGENT="migration-specialist"
elif [[ "$TASK_TEXT" =~ (auth|authentication|authorization|security|token|password|session|oauth|jwt|rbac|permission|credential|secret|csrf|xss|injection) ]]; then
  AGENT="security-specialist"

# Domain specialists (medium risk)
elif [[ "$TASK_TEXT" =~ (api|endpoint|handler|route|controller|service|repository|backend|server|rest|graphql|grpc) ]]; then
  AGENT="backend-specialist"
elif [[ "$TASK_TEXT" =~ (frontend|ui|component|react|vue|svelte|angular|interface|browser|client|jsx|tsx) ]]; then
  AGENT="frontend-specialist"
elif [[ "$TASK_TEXT" =~ (refactor|cleanup|reorganize|restructure|simplify|extract|deduplicate) ]]; then
  AGENT="refactor-specialist"

# Test specialist (low risk)
elif [[ "$TASK_TEXT" =~ (test|spec|testing|coverage|unit test|integration test|e2e|fixture|mock|stub) ]]; then
  AGENT="test-specialist"

# General purpose (no specialist match)
else
  AGENT="general-purpose"
fi
```

**Special agents** (verification-agent, learning-agent) are not part of this selection logic:
- **verification-agent**: Reference implementation for quality review process (work agents follow its standards; not dispatched separately)
- **learning-agent**: Automatically runs after epic completion (background as separate subagent)

## Verification Flow

All implementation agents are followed by quality review (work agent applies verification-agent standards):

```
Implementation Agent (specialized)
  ↓
Quality Review (work agent follows verification-agent process)
  ↓
[PASS] → Close task + capture learnings
[FAIL] → Fix issues → Re-verify
```

## Knowledge Thread Integration

Each agent contributes to the epic's beads comment thread:

1. **Reads** previous task discoveries from thread
2. **Applies** patterns and gotchas from earlier tasks
3. **Contributes** new discoveries in structured format
4. **References** specific code locations for future tasks

This creates institutional knowledge that improves with each task.

## Development

To add a new specialist:

1. Create `agents/epic-executor/new-specialist.md`
2. Follow the agent structure template above
3. Define clear triggers and domain knowledge
4. Specify learning contribution format
5. Add to selection logic in epic-executor skill
6. Test with real tasks matching the trigger patterns

## References

- Research: `ai/research/specialized-agents-research.md`
- Epic-executor skill: `skills/epic-executor/SKILL.md`
- Progress enhancements: `epic-executor-progress-enhancements.md`
