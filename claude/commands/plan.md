---
description: Escalate to premium Claude (headless, read-only) to produce an implementation plan.
argument-hint: <what to plan>
allowed-tools: Bash(determinator-escalate:*)
disable-model-invocation: true
---
Premium implementation plan for: **$ARGUMENTS**

!`determinator-escalate plan "$ARGUMENTS"`
