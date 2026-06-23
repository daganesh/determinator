---
description: Review and strengthen tests. Use when the user wants the test suite reviewed for gaps or hardened ("review the tests", "are we testing this enough"). Runs on the configured review tier (reasoning by default).
argument-hint: "[scope or files, optional]"
allowed-tools: Bash(determinator-escalate:*)
---
Test review: **$ARGUMENTS**

!`determinator-escalate review-tests "${ARGUMENTS:-review the test suite for the current change}"`
