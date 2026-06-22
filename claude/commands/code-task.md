---
description: Escalate to premium Claude (headless) to implement a scoped coding task.
argument-hint: <task to implement>
allowed-tools: Bash(determinator-escalate:*)
disable-model-invocation: true
---
Premium implementation of: **$ARGUMENTS**

!`determinator-escalate code-task "$ARGUMENTS"`
