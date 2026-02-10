---
name: brainstorming
description: You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation.
---

# Brainstorming Skill

**Trigger patterns**: "brainstorm", "explore idea", "design this feature"

**When to use**: When the user wants to explore and refine an idea into a concrete design before implementation. This skill guides collaborative dialogue to understand requirements, explore approaches, and create a detailed design.

## Process

### Phase 1: Understanding
- Review project context and existing codebase
- Ask questions **one at a time** to refine the idea
- Listen carefully to user responses
- Build shared understanding of the problem space

### Phase 2: Exploration
- Present 2-3 different approaches
- Discuss trade-offs conversationally (not as a formal comparison)
- Guide the user toward the best approach based on:
  - Project architecture and patterns
  - Technical constraints
  - Maintenance considerations
  - User requirements

### Phase 3: Design Presentation
Present the design in **200-300 word sections** with validation checkpoints:

1. **Architecture Overview**
   - High-level structure
   - Key components and their relationships
   - Integration points with existing code

2. **Component Details**
   - Individual component responsibilities
   - APIs and interfaces
   - Data structures

3. **Data Flow**
   - How data moves through the system
   - State management
   - External interactions

4. **Error Handling**
   - Expected error scenarios
   - Recovery strategies
   - User feedback mechanisms

After each section:
- Pause for user validation
- Incorporate feedback before continuing
- Adjust subsequent sections based on feedback

### Phase 4: Documentation
After design approval:
- Offer to save the design to a documentation file
- Include architecture diagrams if helpful
- Document key decisions and rationale

### Phase 5: Transition to Implementation
Once design is complete and documented:

1. **Create Implementation Plan**
   - "Now that we have the design, shall I create an implementation plan?"
   - If yes, use `/create_plan` to produce a plan in `ai/current/`

2. **Plan Review**
   - Present the plan for user approval
   - Make adjustments as needed

3. **Convert to Trackable Work**

   **If beads is available** (`bd` command installed and initialized — detect via `bd doctor`):
   - "Shall I convert this plan to a beads epic?"
   - If yes, use `/plan-to-epic <path-to-plan.md> --design <path-to-design.md>`

   **If beads is not available:**
   - "Shall I set up task tracking for this plan?"
   - If yes, create a structured task list using TodoWrite based on the plan phases

4. **Execute**
   - **With beads**: "Ready to execute? I can run the epic autonomously." → `/epic-executor <epic-id>`
   - **Without beads**: "Ready to implement? I can work through the plan phase by phase." → `/implement_plan <plan-path>`

> **Unified Workflow**: This skill is the entry point of the engineering pipeline. See the plugin's `references/unified-workflow-guide.md` for how brainstorming feeds into the full workflow.

## Key Principles

- **Incremental validation**: Never present the entire design at once
- **One question at a time**: Don't overwhelm with multiple questions
- **Conversational exploration**: Make trade-off discussions feel natural
- **Context awareness**: Reference existing code patterns and conventions
- **Chainable workflow**: Seamlessly transition to planning and execution
