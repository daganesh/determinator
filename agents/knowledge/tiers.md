# Tiers

A **tier** is a name you launch with `determinator <tier>`. Each tier = a `{model, backend}`,
defined in `~/.config/determinator/determinator.conf`. The three **backends** are fixed plumbing;
tiers are user labels on top, so names/models are fully configurable.

| Default tier | Launch | Backend | Cost | Good for |
|------|--------|---------|------|----------|
| local | `determinator local` | local Ollama (`localhost:11434`) | free | exploration, summaries, status, running tests/git, grep |
| balanced | `determinator balanced` | Ollama `:cloud` model | cheap | everyday workhorse; coding when local RAM is the limit (needs `ollama signin`) |
| reasoning | `determinator reasoning` | Anthropic via Claude subscription | subscription | planning, real coding decisions, test review |

## One session = one tier (no in-session switching)

Environment variables are read once, when `claude` starts, so a session's tier is fixed for
its whole life. To use a different tier, start another session (another process/terminal) —
multiple concurrent sessions across tiers are fine. Escalation (below) does not switch a
session; it spawns a separate short-lived process.

## Hard limits — read before trusting the local tier

- Claude Code wants **≥64k context**. A 7–14B local model on ~32 GB RAM can hold that, but
  it's tight and slow. Set `num_ctx` deliberately; don't assume the Ollama default is enough.
- The local tier is for **exploration and summarization**, not long agentic coding. When a task
  needs real reasoning or multi-file edits, **escalate** (see [escalation.md](escalation.md)).
- `:cloud` models are **not local** — they run on Ollama's cloud (not free, not offline), but
  have no local RAM ceiling.

## Cost model

With a Claude subscription, the reasoning tier runs on your subscription login (no metered API
billing). local is free; balanced is cheap. The point is to keep cheap work cheap and pay for
the reasoning tier only on the hard steps.
