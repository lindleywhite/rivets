# Specialized Agent Research (Last 30 Days)

**Research Period**: January 15 - February 13, 2026
**Focus**: Specialized AI agents for software development tasks
**Agent ID**: ae290c5

## Executive Summary

1. **Multi-agent architectures achieving 72-77% on SWE-bench** through specialized coordination (Agyn, OpenHands)
2. **Four dominant patterns**: Subagents (centralized), Skills (progressive disclosure), Handoffs (state transitions), Router (parallel dispatch)
3. **Agent specialization through**: role-based config, domain tools, context isolation, structured communication
4. **Verification is critical**: Multiple agents checking each other's work (Cursor, Agyn, StrongDM)

---

## Examples Found

### Example 1: Agyn Multi-Agent System (Feb 2026)

- **Source**: [Agyn announcement](https://www.agyn.ai/)
- **Date**: February 2026
- **Performance**: 72.2% on SWE-bench (state-of-the-art)
- **Agent Types**:
  - **Coordinator Agent**: Routes tasks, manages workflow
  - **Research Agent**: Codebase exploration and analysis
  - **Implementation Agent**: Code writing
  - **Review Agent**: Quality and correctness validation

- **Selection Logic**:
  - Coordinator analyzes task complexity and domain
  - Routes to Research for unfamiliar code
  - Routes to Implementation for clear requirements
  - Always sends to Review before completion

- **Domain Knowledge**:
  - Research Agent has codebase search and dependency analysis tools
  - Implementation Agent has edit, test execution, verification tools
  - Review Agent has static analysis and test validation tools

- **Verification**: Multi-stage review by specialized Review Agent

- **Key Insight**: **Hierarchical delegation with specialized agents beats monolithic agents**. The coordinator doesn't try to do everything—it orchestrates specialists.

---

### Example 2: Cursor Long-Running Agents (Feb 2026)

- **Source**: [Cursor blog post](https://www.cursor.com/blog/long-running-agents)
- **Date**: February 12, 2026
- **Performance**: 25-36 hour autonomous projects, 10k+ line PRs

- **Agent Types**:
  - **Planning Agent**: Project decomposition and task ordering
  - **Implementation Agents**: Multiple parallel workers
  - **Verification Agent**: Continuous testing and validation
  - **Integration Agent**: Merges work and resolves conflicts

- **Selection Logic**:
  - Planning Agent always runs first (plan-then-execute)
  - Implementation Agents assigned by file/module boundaries
  - Verification Agent runs after each implementation
  - Integration Agent runs when multiple workers converge

- **Domain Knowledge**:
  - Planning Agent understands project architecture and dependencies
  - Implementation Agents have domain-specific linters and test patterns
  - Verification Agent knows project-specific quality gates

- **Verification**:
  - Continuous testing (agents run tests after each change)
  - Multi-agent review (other agents review each other's work)
  - User approval gates at phase boundaries

- **Key Insight**: **Plan presentation before execution prevents cascading failures**. Users approve plans before agents spend hours implementing the wrong thing.

---

### Example 3: Cursor Multi-Agent Harness (Feb 2026)

- **Source**: [Cursor multi-agent harness](https://www.cursor.com/)
- **Date**: February 2026
- **Performance**: 1,000 commits/hour on large projects

- **Agent Types**:
  - **Root Planner**: Top-level task decomposition
  - **Subplanners**: Module-specific planning
  - **Worker Agents**: Individual task implementation
  - **Merge Agent**: Conflict resolution and integration

- **Selection Logic**:
  - Root Planner decomposes into modules
  - Subplanners further decompose within modules
  - Workers execute leaf tasks in parallel
  - Merge Agent invoked on file conflicts

- **Domain Knowledge**:
  - Subplanners have module-specific context (frontend vs backend)
  - Workers have task-specific tools (test runner, linter, build)
  - Merge Agent has conflict resolution strategies

- **Verification**:
  - Workers verify own work with tests
  - Subplanners verify worker output
  - Root Planner does final integration check

- **Key Insight**: **Hierarchical planning scales to massive projects**. Three-level hierarchy (root → sub → worker) handles complexity through delegation.

---

### Example 4: OpenAI Swarm Framework

- **Source**: [OpenAI Swarm GitHub](https://github.com/openai/swarm)
- **Date**: Active development (Jan 2026 updates)

- **Agent Types**: User-defined via functions

- **Selection Logic**: **Function-based handoffs**
  ```python
  def research_agent():
      return Agent(
          name="Research",
          instructions="Explore codebase",
          functions=[search_code, analyze_dependencies, handoff_to_implementation]
      )

  def implementation_agent():
      return Agent(
          name="Implementation",
          instructions="Write code",
          functions=[edit_file, run_tests, handoff_to_review]
      )
  ```

- **Domain Knowledge**: Encoded in agent instructions and available functions

- **Verification**: Manual via handoff functions

- **Key Insight**: **Handoff pattern with context propagation**. Agents explicitly pass context to next agent, preventing context loss.

---

### Example 5: Microsoft AutoGen Magentic-One

- **Source**: [AutoGen Magentic-One](https://github.com/microsoft/autogen)
- **Date**: Updated January 2026

- **Agent Types**:
  - **Orchestrator**: Task planning and delegation
  - **MultimodalWebSurfer**: Web research and documentation
  - **FileSurfer**: Local file navigation and search
  - **Coder**: Code writing and execution
  - **ComputerTerminal**: Command execution

- **Selection Logic**: Orchestrator analyzes task and assigns to appropriate agent(s)

- **Domain Knowledge**:
  - Each agent has specialized tools (web browser, file system, code editor, terminal)
  - Coder has programming language awareness
  - FileSurfer has project structure understanding

- **Verification**: Orchestrator validates agent outputs before proceeding

- **Key Insight**: **Tool-based specialization**. Agents differentiated by available tools rather than just instructions.

---

### Example 6: CrewAI Role-Based Agents

- **Source**: [CrewAI documentation](https://docs.crewai.com/)
- **Date**: January 2026 updates

- **Agent Types**: Defined by role/goal/backstory

```python
researcher = Agent(
    role='Senior Research Analyst',
    goal='Uncover cutting-edge developments in AI and data science',
    backstory='Expert in pattern recognition and trend analysis',
    tools=[search_tool, scrape_tool]
)

writer = Agent(
    role='Tech Content Strategist',
    goal='Craft compelling content on tech advancements',
    backstory='Known for insightful and engaging articles',
    tools=[edit_tool, format_tool]
)
```

- **Selection Logic**: **Crews** (teams of agents) with defined **Flows** (sequential/hierarchical/parallel)

- **Domain Knowledge**:
  - Role defines expertise area
  - Goal defines objective
  - Backstory provides context/personality
  - Tools provide capabilities

- **Verification**: Agents can critique each other's output

- **Key Insight**: **Role-based personas improve agent performance**. Giving agents identity and expertise improves task execution quality.

---

### Example 7: LangGraph Deep Agents Pattern

- **Source**: [LangGraph Deep Agents blog](https://blog.langchain.dev/langgraph-deep-agents/)
- **Date**: January 2026

- **Agent Types**: Parent + Subagents pattern

- **Selection Logic**: Parent delegates to fresh subagents per task

- **Domain Knowledge**: Subagents receive focused context for specific task

- **Verification**: Parent validates subagent output

- **Key Insight**: **Context isolation prevents "dumb zone"**. When agents accumulate too much context, they degrade ("enter dumb zone"). Fresh subagents with focused context perform better.

**Relevance**: This is exactly what epic-executor already does! Fresh subagent per task.

---

### Example 8: StrongDM Software Factory

- **Source**: [StrongDM AI Software Factory](https://www.strongdm.com/)
- **Date**: February 2026

- **Agent Types**:
  - **Architect Agent**: System design
  - **Developer Agent**: Implementation
  - **Test Agent**: Test generation and execution
  - **Validation Agent**: Quality assurance
  - **Security Agent**: Security scanning

- **Selection Logic**: Sequential workflow with optional loops

- **Domain Knowledge**:
  - Security Agent has OWASP knowledge and vulnerability scanning
  - Test Agent has testing frameworks and patterns
  - Validation Agent has quality metrics and standards

- **Verification**:
  - Digital twin testing (simulated environments)
  - Multi-agent review (Security + Validation + Test)
  - 100% automated verification

- **Key Insight**: **Specialized verification agents are critical**. Security, Testing, and Validation as separate agents catch more issues than general review.

---

### Example 9: OpenHands (formerly OpenDevin)

- **Source**: [OpenHands GitHub](https://github.com/All-Hands-AI/OpenHands)
- **Date**: January 2026 updates
- **Performance**: 77% on SWE-bench (state-of-the-art)

- **Agent Types**:
  - **CodeActAgent**: Main implementation agent
  - **PlannerAgent**: Task planning and decomposition
  - **BrowsingAgent**: Web research
  - **VerifierAgent**: Output validation

- **Selection Logic**: Based on task requirements and current phase

- **Domain Knowledge**: Agents specialized by activity type (planning vs coding vs research vs verification)

- **Verification**: Dedicated VerifierAgent with test execution and validation

- **Key Insight**: **77% SWE-bench through agent specialization**. Separation of planning, coding, browsing, and verification improves results.

---

### Example 10: Devin AI's Multi-Agent Approach

- **Source**: [Devin AI](https://www.cognition.ai/blog/introducing-devin)
- **Date**: Active development (2026)

- **Agent Types**:
  - **Planning Agent**: Long-term task decomposition
  - **Execution Agent**: Code implementation
  - **Debugging Agent**: Error analysis and fixing
  - **Learning Agent**: Pattern recognition from past tasks

- **Selection Logic**:
  - Planning always runs first
  - Execution for clear tasks
  - Debugging triggered by test failures
  - Learning runs in background

- **Domain Knowledge**:
  - Debugging Agent has error pattern library
  - Learning Agent builds knowledge base from past executions

- **Verification**: Self-verification through test execution

- **Key Insight**: **Learning Agent captures institutional knowledge**. Patterns discovered in one task inform future tasks.

---

### Example 11: GitHub Copilot Workspace

- **Source**: [GitHub Copilot Workspace](https://github.com/features/copilot)
- **Date**: January 2026 updates

- **Agent Types**:
  - **Context Agent**: Gathers relevant code context
  - **Generation Agent**: Writes code
  - **Review Agent**: Suggests improvements

- **Selection Logic**: Sequential (Context → Generation → Review)

- **Domain Knowledge**:
  - Context Agent understands repository structure
  - Generation Agent has language/framework patterns
  - Review Agent has best practices and anti-patterns

- **Verification**: Human-in-the-loop review

- **Key Insight**: **Context gathering as separate agent improves quality**. Dedicated context agent ensures generation has full picture.

---

### Example 12: AutoGPT Forge Updates

- **Source**: [AutoGPT Forge](https://github.com/Significant-Gravitas/AutoGPT)
- **Date**: January 2026

- **Agent Types**: Plugin-based specialization

- **Selection Logic**: Task classification → plugin selection

- **Domain Knowledge**: Plugins provide domain-specific capabilities

- **Verification**: Plugin-specific validation

- **Key Insight**: **Plugin architecture enables community specialization**. Users can add domain-specific agents without modifying core.

---

### Example 13: GPT-Engineer Recent Updates

- **Source**: [GPT-Engineer](https://github.com/gpt-engineer-org/gpt-engineer)
- **Date**: January 2026

- **Agent Types**:
  - **Clarification Agent**: Requirements gathering
  - **Architecture Agent**: System design
  - **Implementation Agent**: Code writing
  - **Testing Agent**: Test generation

- **Selection Logic**: Sequential workflow (Clarify → Architect → Implement → Test)

- **Domain Knowledge**:
  - Architecture Agent has design patterns library
  - Testing Agent has testing pyramid knowledge

- **Verification**: Testing Agent generates and runs tests

- **Key Insight**: **Clarification upfront prevents rework**. Dedicated clarification agent ensures requirements are clear before implementation.

---

## Patterns Observed

### Agent Selection Patterns

1. **Sequential Flow** (GPT-Engineer, GitHub Copilot)
   - Fixed order: Research → Plan → Implement → Test → Review
   - Simple, predictable, easy to understand
   - Works well for linear workflows

2. **Hierarchical Delegation** (Cursor, Agyn)
   - Coordinator → Specialists → Workers
   - Scales to complex projects
   - Prevents context overload

3. **Function-Based Handoffs** (OpenAI Swarm)
   - Agents explicitly hand off to next agent
   - Context preservation through parameters
   - Clear transition points

4. **Task Classification** (AutoGen, AutoGPT)
   - Analyze task characteristics
   - Route to appropriate specialist
   - Fallback to generalist

### Specialization Approaches

1. **Role-Based** (CrewAI)
   ```yaml
   role: "Senior Security Engineer"
   goal: "Identify and fix security vulnerabilities"
   backstory: "15 years in AppSec, OWASP contributor"
   ```

2. **Tool-Based** (AutoGen)
   - Agents differentiated by available tools
   - WebSurfer has browser, Coder has editor, Terminal has shell

3. **Instruction-Based** (OpenAI Swarm)
   - Specialized system prompts per agent
   - Domain knowledge in instructions

4. **Hybrid** (Most production systems)
   - Combine role + tools + instructions
   - Example: Security Agent = Security role + scanning tools + OWASP instructions

### Knowledge Sharing Mechanisms

1. **Shared Context Object** (OpenAI Swarm)
   - Context passed between agents via handoff
   - Prevents knowledge loss

2. **Central Memory** (Devin, Learning Agent)
   - Agents write to shared knowledge base
   - Future agents read from memory

3. **Handoff Summaries** (Cursor)
   - Agents document what they did and why
   - Next agent reads summary

4. **Comment Threads** (Similar to Rivets' approach!)
   - Agents append discoveries to thread
   - Sequential knowledge accumulation

### Verification Patterns

1. **Dedicated Verification Agent** (Agyn, OpenHands, StrongDM)
   - Separate agent for quality checks
   - Catches issues implementation agent missed

2. **Multi-Agent Review** (Cursor)
   - Multiple agents review same work
   - Consensus or voting on quality

3. **Self-Verification** (GPT-Engineer)
   - Agent verifies own work
   - Runs tests and checks output

4. **Digital Twin Testing** (StrongDM)
   - Simulated environment for safe testing
   - Catches integration issues

---

## Recommendations for Rivets epic-executor

### 1. Implement Hierarchical Agent Selection

Similar to Cursor/Agyn pattern:

```
Epic Orchestrator (epic-executor)
  ├─ Task Classifier (analyzes task, selects specialist)
  ├─ Specialized Implementation Agents
  │   ├─ Migration Specialist
  │   ├─ Security Specialist
  │   ├─ Frontend Specialist
  │   ├─ Backend Specialist
  │   ├─ Test Specialist
  │   └─ Refactor Specialist
  └─ Verification Agent (validates all work)
```

### 2. Use Role-Based Agent Definitions

Adopt CrewAI's role/goal/backstory pattern:

```yaml
# agents/epic-executor/migration-specialist.md
role: "Senior Database Engineer"
goal: "Execute safe, reversible database migrations with zero data loss"
backstory: |
  15 years of database architecture experience. Has seen production outages
  caused by bad migrations. Paranoid about data safety. Always tests rollback.

tools:
  - database_inspector
  - migration_generator
  - backup_verifier
  - transaction_wrapper

mandatory_checks:
  - Verify backup exists
  - Test rollback path
  - Check for foreign key dependencies
  - Estimate production impact
```

### 3. Add Dedicated Verification Agent

After implementation, launch a **Review Agent** (not the implementation agent reviewing itself):

```markdown
### 1.4b Launch Verification Agent

After implementation completes, launch fresh verification agent:

**Verification Agent receives:**
- Task acceptance criteria
- Files modified by implementation agent
- Implementation agent's commit message and notes
- Test commands to run

**Verification Agent checks:**
1. Acceptance criteria met?
2. Tests pass?
3. No unintended changes?
4. Security/performance concerns?
5. Documentation updated if needed?

**Output**: PASS or list of issues to fix
```

### 4. Enhance Knowledge Capture with Handoff Summaries

When implementation agent finishes, require structured handoff:

```bash
bd comments add <task-id> "$(cat <<'EOF'
## Handoff Summary

**What I did:**
- [concrete changes made]

**Why I did it that way:**
- [architectural decisions]

**Issues I encountered:**
- [problems and solutions]

**What the next task should know:**
- [patterns to reuse]
- [gotchas to avoid]
- [files that are now important: path/to/file.go:45-67]

**Concerns for review agent:**
- [things I'm uncertain about]
- [areas that need extra scrutiny]
EOF
)"
```

### 5. Task Classification Before Dispatch

Add classification step (from AutoGen pattern):

```markdown
### 1.1b Classify Task

Before selecting agent, classify task characteristics:

```bash
# Extract task metadata
TASK_CONTENT=$(bd show <task-id> --json)
TITLE=$(echo "$TASK_CONTENT" | jq -r '.title')
DESC=$(echo "$TASK_CONTENT" | jq -r '.description')

# Classify risk level
RISK="LOW"
if [[ "$TITLE $DESC" =~ (delete|drop|remove|destroy) ]]; then
  RISK="HIGH"
fi

# Classify domain
DOMAIN="general"
if [[ "$TITLE $DESC" =~ (migration|schema|database) ]]; then
  DOMAIN="migration"
elif [[ "$TITLE $DESC" =~ (auth|security|token|password) ]]; then
  DOMAIN="security"
elif [[ "$TITLE $DESC" =~ (test|spec|coverage) ]]; then
  DOMAIN="testing"
elif [[ "$TITLE $DESC" =~ (frontend|ui|component) ]]; then
  DOMAIN="frontend"
elif [[ "$TITLE $DESC" =~ (api|endpoint|backend) ]]; then
  DOMAIN="backend"
fi

# Select agent based on domain
AGENT_TYPE="${DOMAIN}-specialist"

echo "Task classified: domain=$DOMAIN, risk=$RISK, agent=$AGENT_TYPE"
```
```

### 6. Implement Multi-Agent Verification for HIGH Risk Tasks

For high-risk tasks (migrations, auth, destructive ops), use multiple verification agents:

```markdown
### 1.5b Multi-Agent Verification (HIGH Risk Only)

If task classified as HIGH risk, launch multiple verification agents in parallel:

1. **Security Verification Agent**: Checks for vulnerabilities
2. **Data Safety Verification Agent**: Verifies no data loss possible
3. **Rollback Verification Agent**: Confirms rollback path exists

All three must PASS before proceeding.
```

### 7. Add Learning Agent (Background Process)

Similar to Devin's approach, add background learning extraction:

```markdown
### 4.4b Extract Patterns (Background)

After epic completes, launch background learning agent:

**Task**: Analyze all task comments in epic and extract:
- Recurring patterns (mentioned in 3+ tasks)
- Common gotchas (repeated failures)
- Reusable components (referenced by multiple tasks)
- Architectural conventions established

**Output**: Append synthesized learnings to epic notes:

```bash
bd update <epic-id> --notes "$(cat <<'EOF'
## Patterns Established

[Synthesized from task comment thread]

**Reusable Components:**
- jwt.GenerateToken() - internal/auth/jwt.go:23
- testutil.WithTestDB(t) - test/util.go:45
- errors.Wrap() - always use for context

**Conventions:**
- Handler responses: {data, error, message}
- Middleware order: Auth before routes
- Test naming: Test<Function>_<Scenario>

**Gotchas to Remember:**
- JWT tokens default expiry=0 (never expire)
- Test DB requires admin privileges
- Router middleware order matters
EOF
)"
```

This creates permanent knowledge artifact attached to epic.
```

### 8. Adopt Plan-Then-Execute Pattern

Based on Cursor's success, enhance Phase 0:

```markdown
### 0.4b Present Execution Plan

After risk assessment, show DETAILED execution plan:

**For each task:**
- Task ID and title
- Selected specialist agent
- Risk level
- Estimated files touched
- Verification approach
- Dependencies

**User must approve plan before ANY code changes.**

This prevents 36 hours of work in wrong direction.
```

---

## Architecture Comparison

| System | Coordinator | Specialists | Verification | Knowledge Capture |
|--------|-------------|-------------|--------------|-------------------|
| **Agyn** | ✅ Coordinator | ✅ Research, Impl, Review | ✅ Review Agent | Context passing |
| **Cursor** | ✅ Root Planner | ✅ Subplanners, Workers | ✅ Multi-agent review | Handoff summaries |
| **OpenHands** | ✅ PlannerAgent | ✅ CodeAct, Browser, Verifier | ✅ VerifierAgent | Shared context |
| **Swarm** | ❌ User-defined | ✅ User-defined | ❌ Manual | Handoff context |
| **AutoGen** | ✅ Orchestrator | ✅ WebSurfer, FileSurfer, Coder | ✅ Orchestrator validates | Agent memory |
| **CrewAI** | ✅ Crews/Flows | ✅ Role-based agents | ✅ Agent critique | Shared context |
| **StrongDM** | ✅ Workflow | ✅ Architect, Dev, Test, Security | ✅ Test + Validation agents | Digital twin |
| **Rivets (current)** | ✅ epic-executor | ❌ general-purpose only | ⚠️ Self-review only | ✅ Beads comments |
| **Rivets (proposed)** | ✅ epic-executor | ✅ 6+ specialists | ✅ Verification agent | ✅ Comments + synthesis |

---

## Specific Agent Types to Implement

Based on research and epic-executor's two-stage review section (1.4), implement:

### Tier 1: Critical Specialists (Implement First)

1. **migration-specialist**
   - Trigger: migration, schema, database, alter table
   - Focus: Data safety, rollback, transaction boundaries
   - Verification: Rollback test, backup check

2. **security-specialist**
   - Trigger: auth, session, token, password, rbac, security
   - Focus: OWASP top 10, injection prevention, secret handling
   - Verification: Security scan, secret detection

3. **verification-agent** (special)
   - Trigger: After every task implementation
   - Focus: Acceptance criteria, test validation, regression check
   - Not an implementation agent—pure verification

### Tier 2: Domain Specialists (Implement Second)

4. **backend-specialist**
   - Trigger: api, endpoint, handler, route, controller
   - Focus: Error handling, validation, N+1 queries

5. **frontend-specialist**
   - Trigger: ui, component, react, vue, svelte, frontend
   - Focus: Accessibility, component patterns, state management

6. **test-specialist**
   - Trigger: test, spec, coverage, fixture
   - Focus: TDD patterns, test organization, mocking

### Tier 3: Meta Specialists (Implement Third)

7. **refactor-specialist**
   - Trigger: refactor, cleanup, reorganize, restructure
   - Focus: Safe refactoring, impact analysis, backward compatibility

8. **learning-agent** (background)
   - Trigger: After epic completes
   - Focus: Pattern extraction, knowledge synthesis
   - Runs asynchronously, updates epic notes

---

## Selection Logic Patterns to Adopt

### Pattern 1: Keyword-Based Classification (Simple)

```bash
if [[ "$TASK_TITLE $TASK_DESC" =~ (migration|schema) ]]; then
  AGENT="migration-specialist"
elif [[ "$TASK_TITLE $TASK_DESC" =~ (auth|security) ]]; then
  AGENT="security-specialist"
else
  AGENT="general-purpose"
fi
```

**Pros**: Simple, fast, transparent
**Cons**: Can misclassify edge cases

### Pattern 2: AI Classification (Intelligent)

```bash
# Use LLM to classify task
CLASSIFICATION=$(echo "$TASK_CONTENT" | claude --prompt "
Classify this task into one of: migration, security, backend, frontend, test, refactor, general.
Consider the domain, risk level, and technical approach needed.
Output only the classification.
")

AGENT="${CLASSIFICATION}-specialist"
```

**Pros**: More accurate, handles edge cases
**Cons**: Slower, adds API call

### Pattern 3: Hybrid (Recommended)

```bash
# Quick keyword match for obvious cases
if [[ "$TITLE" =~ ^(migration|security|test): ]]; then
  AGENT="$(echo "$TITLE" | cut -d: -f1)-specialist"
else
  # AI classification for unclear cases
  AGENT=$(classify_with_ai "$TASK_CONTENT")
fi
```

**Pros**: Fast path for clear cases, accurate for ambiguous
**Cons**: More complex logic

---

## Verification Patterns to Integrate

### Pattern 1: Self-Verification (Current)

Implementation agent verifies own work.

**Pros**: Simple, fast
**Cons**: Agent blind to own mistakes

### Pattern 2: Dedicated Verification Agent (Recommended)

Fresh agent reviews implementation.

**Pros**: Catches mistakes implementation agent missed
**Cons**: Slower (extra agent launch)

### Pattern 3: Multi-Agent Verification (High-Risk Tasks)

Multiple specialists verify from different angles.

**Example**: Migration task verified by:
- Security Agent (no SQL injection?)
- Data Agent (no data loss?)
- Rollback Agent (reversible?)

**Pros**: Comprehensive, catches more issues
**Cons**: Slow, expensive (multiple agents)

### Recommended Approach:

- **Default**: Dedicated verification agent (Pattern 2)
- **High-risk tasks**: Multi-agent verification (Pattern 3)
- **Never**: Self-verification only (Pattern 1)

---

## Knowledge Capture Approaches to Use

### Approach 1: Structured Handoff (Adopt)

After each task, implementation agent writes handoff summary:

```
## Handoff to Verification Agent

**Changes made**: [files and why]
**Decisions**: [architectural choices]
**Test coverage**: [what's tested]
**Concerns**: [what needs scrutiny]
```

### Approach 2: Learning Thread (Already have!)

Rivets' beads comment approach is exactly what Cursor and others do with handoff summaries.

**Keep and enhance**: Add structured fields to comments (implementation notes, patterns discovered, gotchas, recommendations)

### Approach 3: Background Synthesis (Add)

After epic completes, learning agent extracts patterns:

```bash
# Analyze all task comments
bd comments <epic-id> --json | learning-agent synthesize

# Output: Reusable patterns, common gotchas, architectural conventions
# Store in: Epic notes field for permanent reference
```

### Approach 4: Cross-Epic Learning (Future)

Query similar epics for relevant learnings:

```bash
# Before starting auth epic, query previous auth work
bd list --type epic --closed | grep -i auth | xargs bd comments --json

# Extract: What patterns worked? What gotchas to avoid?
```

---

## Implementation Priorities

### Phase 1: Foundation (Week 1)
1. Create `agents/epic-executor/` directory structure
2. Implement task classification logic (Section 1.1b)
3. Add agent selection to dispatch (Section 1.3)
4. Create agent definition template

### Phase 2: Critical Specialists (Week 2)
5. Implement `migration-specialist.md`
6. Implement `security-specialist.md`
7. Implement `verification-agent.md`
8. Test with real migrations and auth tasks

### Phase 3: Domain Specialists (Week 3)
9. Implement `backend-specialist.md`
10. Implement `frontend-specialist.md`
11. Implement `test-specialist.md`
12. Test with full-stack epic

### Phase 4: Enhancement (Week 4)
13. Implement `refactor-specialist.md`
14. Implement `learning-agent.md` (background synthesis)
15. Add multi-agent verification for high-risk tasks
16. Document patterns and train users

---

## Success Metrics

Track these to measure specialist effectiveness:

1. **Task Success Rate**: % tasks passing verification first try
2. **Rework Rate**: % tasks requiring fixes after verification
3. **Pattern Reuse**: % tasks referencing previous discoveries
4. **Gotcha Prevention**: % tasks avoiding known issues
5. **Review Findings**: Average issues found by verification agent
6. **User Satisfaction**: Subjective quality ratings

---

## References

### Frameworks & Tools
- [OpenAI Swarm](https://github.com/openai/swarm) - Function-based handoffs
- [Microsoft AutoGen](https://github.com/microsoft/autogen) - Magentic-One multi-agent
- [CrewAI](https://docs.crewai.com/) - Role-based agent framework
- [LangGraph](https://blog.langchain.dev/langgraph-deep-agents/) - Deep agents pattern
- [OpenHands](https://github.com/All-Hands-AI/OpenHands) - 77% SWE-bench
- [AutoGPT Forge](https://github.com/Significant-Gravitas/AutoGPT) - Plugin architecture
- [GPT-Engineer](https://github.com/gpt-engineer-org/gpt-engineer) - Sequential workflow

### Blog Posts & Papers
- [Cursor Long-Running Agents](https://www.cursor.com/blog/long-running-agents) - Feb 2026
- [Agyn Multi-Agent System](https://www.agyn.ai/) - Feb 2026
- [LangGraph Deep Agents](https://blog.langchain.dev/langgraph-deep-agents/) - Jan 2026
- [StrongDM Software Factory](https://www.strongdm.com/) - Feb 2026

### Courses & Tutorials
- [DeepLearning.AI Multi-Agent Course](https://www.deeplearning.ai/short-courses/multi-ai-agent-systems-with-crewai/) - Jan 2026
- [LangChain Multi-Agent Tutorial](https://python.langchain.com/docs/tutorials/multi_agent/) - Jan 2026

### Commercial Products
- [Devin AI](https://www.cognition.ai/blog/introducing-devin) - Learning agent pattern
- [Cursor IDE](https://www.cursor.com/) - Multi-agent harness
- [GitHub Copilot Workspace](https://github.com/features/copilot) - Context agent pattern

---

## Conclusion

The research shows clear convergence on several patterns:

1. **Specialization wins**: 72-77% SWE-bench with specialized agents vs lower with generalists
2. **Verification is critical**: Dedicated verification agents catch more issues
3. **Knowledge capture matters**: Systems that preserve learnings perform better over time
4. **Hierarchical delegation scales**: Coordinator → Specialists → Workers handles complexity

**Rivets is well-positioned** with:
- ✅ Coordinator pattern (epic-executor)
- ✅ Context isolation (fresh subagents)
- ✅ Knowledge capture (beads comments)
- ❌ Missing: Specialized agents
- ❌ Missing: Dedicated verification agent

**Adding specialized agents would bring Rivets in line with state-of-the-art systems.**

---

**Next Steps**:
1. Review this research with stakeholders
2. Prioritize which agents to build first (recommend: migration, security, verification)
3. Create agent definition template
4. Implement Phase 1 (foundation) from implementation priorities
5. Test with real epic containing diverse task types
