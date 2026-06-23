# Routing heuristics

Decide where work runs. Default to the cheapest tier that can do the job; escalate the hard step.

## Keep on the local/balanced tier
- Status questions: "what changed?", "are tests passing?", "summarize this diff"
- Running things: tests, builds, git, grep/find, file reads
- Drafting commit messages and triaging logs → use the local MCP tools
  (`gen_commit_msg`, `summarize_diff`, `triage_log`) even from a premium session

## Escalate to premium (`/plan`, `/code-task`, `/review-tests`)
- Designing a change across multiple files or systems
- Non-trivial implementation that needs real reasoning or care
- Reviewing tests for correctness/coverage gaps
- Anything where a wrong cheap answer costs more than the premium call

## Smell test
If a wrong answer is cheap to catch and fix → stay cheap. If a wrong answer is expensive
(ships a bug, wrong architecture, missed edge case) → escalate.
