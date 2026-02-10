# Implement Plan

You are tasked with implementing an approved technical plan from `ai/current/`. These plans contain phases with specific changes and success criteria.

## Getting Started

When given a plan path:
- Read the plan completely and check for any existing checkmarks (- [x])
- Read all files mentioned in the plan
- **Read files fully** - never use limit/offset parameters
- Think deeply about how the pieces fit together
- Create a todo list to track your progress
- Start implementing if you understand what needs to be done

If no plan path provided, ask for one.

## Implementation Philosophy

Plans are carefully designed, but reality can be messy. Your job is to:
- Follow the plan's intent while adapting to what you find
- Implement each phase fully before moving to the next
- Verify your work makes sense in the broader codebase context
- Update checkboxes in the plan as you complete sections

When things don't match the plan exactly, think about why and communicate clearly:
```
Issue in Phase [N]:
Expected: [what the plan says]
Found: [actual situation]
Why this matters: [explanation]

How should I proceed?
```

## Verification Approach

After implementing a phase:
- Run the success criteria checks
- Fix any issues before proceeding
- Update your progress in both the plan and your todos
- Check off completed items in the plan file itself using Edit

## If You Get Stuck

- First, read and understand all relevant code
- Consider if the codebase has evolved since the plan was written
- Present the mismatch clearly and ask for guidance

## Resuming Work

If the plan has existing checkmarks:
- Trust that completed work is done
- Pick up from the first unchecked item
- Verify previous work only if something seems off

## Preferred Alternative: Epic-Based Execution

For multi-step plans with persistent tracking, prefer the epic-based workflow:

**If beads (`bd` command) is available:**
1. `/plan-to-epic <plan-path>` — converts the plan into a beads epic with tasks and dependencies
2. `/epic-executor <epic-id>` — executes tasks with fresh sub-agents, two-stage review, and verification gates

**If beads is not available:**
- Use this command (`/implement_plan`) directly
- Track progress via plan checkboxes and TodoWrite
- Apply the 5-step verification gate manually at each phase

## 5-Step Verification Gate

Before claiming any phase is complete, execute:

1. **IDENTIFY** — State the specific verification command or check needed
2. **RUN** — Execute the verification (test, build, lint, manual check)
3. **READ** — Read the full output, don't skim or assume
4. **VERIFY** — Confirm the output proves the work is done
5. **CLAIM** — Only now mark the phase as complete

See `references/unified-workflow-guide.md` (in this plugin) for the full unified workflow.
