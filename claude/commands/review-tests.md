---
description: Escalate to premium Claude (headless) to review and strengthen the tests.
argument-hint: "[scope or files, optional]"
allowed-tools: Bash(determinator-escalate:*)
disable-model-invocation: true
---
Premium test review: **$ARGUMENTS**

!`determinator-escalate review-tests "${ARGUMENTS:-review the test suite for the current change}"`
