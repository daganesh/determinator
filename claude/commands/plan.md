---
description: Plan a feature or change. Use whenever the user wants to plan, design, or think through an approach ("plan this feature", "how should we build X", "/plan ..."). Runs a planning agent on the configured planning tier (reasoning by default).
argument-hint: <what to plan>
allowed-tools: Bash(determinator-escalate:*)
---
Implementation plan for: **$ARGUMENTS**

!`determinator-escalate plan "$ARGUMENTS"`
