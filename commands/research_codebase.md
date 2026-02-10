# Research Codebase

You are tasked with conducting comprehensive research across the codebase to answer user questions by spawning parallel sub-agents and synthesizing their findings.

## Initial Setup:

When this command is invoked, respond with:
```
I'm ready to research the codebase. Please provide your research question or area of interest, and I'll analyze it thoroughly by exploring relevant components and connections.
```

Then wait for the user's research query.

## Steps to follow after receiving the research query:

1. **Read any directly mentioned files first:**
   - If the user mentions specific files (tickets, docs, JSON), read them FULLY first
   - **IMPORTANT**: Use the Read tool WITHOUT limit/offset parameters to read entire files
   - **CRITICAL**: Read these files yourself in the main context before spawning any sub-tasks
   - This ensures you have full context before decomposing the research

2. **Analyze and decompose the research question:**
   - Break down the user's query into composable research areas
   - Take time to ultrathink about the underlying patterns, connections, and architectural implications
   - Identify specific components, patterns, or concepts to investigate
   - Create a research plan using TodoWrite to track all subtasks

3. **Spawn parallel sub-agent tasks for comprehensive research:**
   - Create multiple Task agents to research different aspects concurrently

   **For codebase research:**
   - Use the **codebase-locator** agent to find WHERE files and components live
   - Use the **codebase-analyzer** agent to understand HOW specific code works
   - Use the **codebase-pattern-finder** agent for examples of similar implementations

   **For AI documentation:**
   - Use the **ai-locator** agent to discover what AI documents exist about the topic
   - Use the **ai-analyzer** agent to extract key insights from specific documents

   **For web research (only if user explicitly asks):**
   - Use the **web-search-researcher** agent for external documentation and resources
   - IF you use web-research agents, instruct them to return LINKS with their findings

   The key is to use these agents intelligently:
   - Start with locator agents to find what exists
   - Then use analyzer agents on the most promising findings
   - Run multiple agents in parallel when they're searching for different things
   - Each agent knows its job - just tell it what you're looking for

4. **Wait for all sub-agents to complete and synthesize findings:**
   - IMPORTANT: Wait for ALL sub-agent tasks to complete before proceeding
   - Prioritize live codebase findings as primary source of truth
   - Use ai/ findings as supplementary historical context
   - Connect findings across different components
   - Include specific file paths and line numbers for reference
   - Highlight patterns, connections, and architectural decisions

5. **Gather metadata for the research document:**
   - Gather metadata using git commands for commit hash, branch, date, etc.
   - Filename: `ai/research/YYYY-MM-DD_topic.md`

6. **Generate research document:**
   Structure the document with YAML frontmatter followed by content:

   ```markdown
   ---
   date: [Current date and time with timezone in ISO format]
   researcher: [Researcher name]
   git_commit: [Current commit hash]
   branch: [Current branch name]
   repository: [Repository name]
   topic: "[User's Question/Topic]"
   tags: [research, codebase, relevant-component-names]
   status: complete
   last_updated: [Current date in YYYY-MM-DD format]
   last_updated_by: [Researcher name]
   ---

   # Research: [User's Question/Topic]

   **Date**: [Current date and time]
   **Git Commit**: [Current commit hash]
   **Branch**: [Current branch name]

   ## Research Question
   [Original user query]

   ## Summary
   [High-level findings answering the user's question]

   ## Detailed Findings

   ### [Component/Area 1]
   - Finding with reference ([file.ext:line](link))
   - Connection to other components

   ## Code References
   - `path/to/file.py:123` - Description
   - `another/file.ts:45-67` - Description

   ## Architecture Insights
   [Patterns, conventions, and design decisions discovered]

   ## Related Research
   [Links to other research documents]

   ## Open Questions
   [Any areas that need further investigation]
   ```

7. **Add GitHub permalinks (if applicable):**
   - Check if on main branch or if commit is pushed
   - If applicable, generate GitHub permalinks with `gh repo view --json owner,name`

8. **Save and present findings:**
   - Save the research document to `ai/research/` directory
   - Present a concise summary to the user
   - Ask if they have follow-up questions

9. **Handle follow-up questions:**
   - Append to the same research document
   - Update frontmatter `last_updated` fields
   - Add a new section: `## Follow-up Research [timestamp]`
   - Spawn new sub-agents as needed

## Important notes:
- Always use parallel Task agents to maximize efficiency
- Always run fresh codebase research - never rely solely on existing documents
- Focus on finding concrete file paths and line numbers
- Research documents should be self-contained
- Keep the main agent focused on synthesis, not deep file reading
- **File reading**: Always read mentioned files FULLY before spawning sub-tasks
- **Critical ordering**: Follow the numbered steps exactly
  - ALWAYS read mentioned files first (step 1)
  - ALWAYS wait for all sub-agents to complete before synthesizing (step 4)
  - ALWAYS gather metadata before writing the document (step 5 before step 6)
  - NEVER write the research document with placeholder values
- **Frontmatter consistency**: Always include frontmatter, use snake_case for field names
