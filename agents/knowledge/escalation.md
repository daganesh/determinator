# Escalation

From inside a cheap (local/balanced) session you can run one job on a stronger tier without
making the whole session expensive. Trigger by slash command **or** plain language — the
commands are model-invocable, so "plan this feature" maps to `/plan`.

| Command / intent | Runs on (configurable) | Premium does | Tools it gets |
|---|---|---|---|
| `/plan`, "plan this…" | `DET_PLAN_TIER` (reasoning) | a read-only implementation plan | Read, Grep, Glob, Bash |
| `/code-task`, "implement…" | `DET_CODE_TIER` (balanced) | implements a scoped change | Read, Edit, Write, Grep, Glob, Bash |
| `/review-tests`, "review the tests" | `DET_REVIEW_TIER` (reasoning) | reviews/strengthens tests | Read, Edit, Grep, Glob, Bash |

## How it works

Each command runs `determinator-escalate <mode> "<task>"` (optionally `--tier <name>` to
override). That helper:

1. Resolves the mode's tier from config → `{model, backend}`.
2. Wires that backend in an **isolated subprocess** — for the `anthropic` backend it unsets
   `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and `ANTHROPIC_API_KEY` so the call can't
   inherit the parent's localhost backend or silently switch to metered billing.
3. Runs `claude -p` headless with a mode-specific system prompt and a scoped `--allowedTools`.

The escalated process is **separate** from your session: it sees the task text you pass plus
the repo on disk (Read/Grep/Glob), not your session's live conversation. Ground tasks in the
files; for chained steps, pass state via a file (e.g. write `PLAN.md`, then
`/code-task implement PLAN.md`).

## Large inputs

`claude -p` has a ~10 MB stdin limit. For a huge diff/log, write it to a temp file and
reference the path in the task text rather than pasting it inline.
