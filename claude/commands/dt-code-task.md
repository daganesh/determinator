---
description: Implement a scoped coding task. Use when the user asks to implement, build, or write code for a specific change ("code this", "implement the plan"). Runs on the configured coding tier (balanced by default).
argument-hint: <task to implement>
allowed-tools: Bash(determinator-escalate:*)
---
Implementing: **$ARGUMENTS**

!`determinator-escalate code-task "$ARGUMENTS"`
