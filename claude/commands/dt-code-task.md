---
description: Implement a scoped coding task. Use when the user asks to implement, build, or write code for a specific change ("code this", "implement the plan"). Escalates to a coding model — in-context when possible.
argument-hint: <task to implement>
allowed-tools: Bash(determinator:*), Bash(determinator-escalate:*), Task
---
Implement this: **$ARGUMENTS**

Choose the escalation path, then carry it out:
1. Run `determinator which` to see the active backend.
2. **If the backend is the Anthropic subscription**: launch the **dt-code** subagent via the Task tool, passing the task plus relevant context from our conversation. Keeps context; returns here.
3. **If the backend is local/cloud** (Ollama at `localhost`): run the separate process and show its output:
   `determinator-escalate code-task "$ARGUMENTS"`
