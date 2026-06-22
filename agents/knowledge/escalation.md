# Escalation

From inside a cheap (local/cloud) session you can run one premium job without making the
whole session premium. Three manual commands:

| Command | Premium does | Tools it gets |
|---|---|---|
| `/plan <task>` | a read-only implementation plan | Read, Grep, Glob, Bash |
| `/code-task <task>` | implements a scoped change | Read, Edit, Write, Grep, Glob, Bash |
| `/review-tests [scope]` | reviews/strengthens tests | Read, Edit, Grep, Glob, Bash |

## How it works

Each command runs `determinator-escalate <mode> "<task>"`, which:

1. Forces the **premium** backend in an isolated subprocess — it unsets `ANTHROPIC_BASE_URL`,
   `ANTHROPIC_AUTH_TOKEN`, and `ANTHROPIC_API_KEY` so the call can't leak the cheap session's
   localhost backend or silently switch to metered API billing.
2. Runs `claude -p` headless with a mode-specific system prompt and a scoped `--allowedTools`.
3. Uses your Claude subscription login by default (API key only if you opted in).

Routing is **manual by design** — you decide when a step is worth premium. There is no
automatic difficulty classifier.

## Large inputs

`claude -p` has a ~10 MB stdin limit. For a huge diff/log, write it to a temp file and
reference the path in the task text rather than pasting it inline.
