---
description: Review and strengthen tests. Use when the user wants the test suite reviewed for gaps or hardened ("review the tests", "are we testing this enough"). Escalates to a stronger model — in-context when possible.
argument-hint: "[scope or files, optional]"
allowed-tools: Bash(determinator:*), Bash(determinator-escalate:*), Task
---
Review tests: **$ARGUMENTS**

Choose the escalation path, then carry it out:
1. Run `determinator which` to see the active backend.
2. **If the backend is the Anthropic subscription**: launch the **dt-review** subagent via the Task tool, passing the scope plus relevant context from our conversation. Keeps context; returns here.
3. **If the backend is local/cloud** (Ollama at `localhost`): run the separate process and show its output:
   `determinator-escalate review-tests "${ARGUMENTS:-review the test suite for the current change}"`
