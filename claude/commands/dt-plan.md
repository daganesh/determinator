---
description: Plan a feature or change. Use whenever the user wants to plan, design, or think through an approach ("plan this feature", "how should we build X", "/dt-plan ..."). Escalates to a stronger model — in-context when possible.
argument-hint: <what to plan>
allowed-tools: Bash(determinator:*), Bash(determinator-escalate:*), Task
---
Plan this: **$ARGUMENTS**

Choose the escalation path, then carry it out:
1. Run `determinator which` to see the active backend.
2. **If the backend is the Anthropic subscription** (shows `anthropic*`, or no `localhost` base URL): launch the **dt-plan** subagent via the Task tool. Pass it the task **plus the relevant context from our current conversation** (files, decisions, constraints). This keeps context and returns the plan here — no separate process.
3. **If the backend is local/cloud** (Ollama at `localhost`): a subagent can't reach the reasoning tier from here, so run the separate process and show its output:
   `determinator-escalate plan "$ARGUMENTS"`
