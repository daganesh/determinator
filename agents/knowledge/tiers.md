# Tiers

All three tiers are the **same `claude` binary**; only the backend env vars differ.

| Tier | Launch | Backend | Cost | Good for |
|------|--------|---------|------|----------|
| local | `determinator local` | local Ollama (`localhost:11434`) | free | exploration, summaries, status, running tests/git, grep |
| cloud | `determinator cloud` | Ollama `:cloud` model | cheap | same as local when RAM is the limit (needs `ollama signin`) |
| premium | `determinator premium` | Anthropic via Claude subscription (OAuth) | subscription | planning, real coding, test review |

## Hard limits — read before trusting the local tier

- Claude Code wants **≥64k context**. A 7–14B local model on ~32 GB RAM can hold that, but
  it's tight and slow. Set `num_ctx` deliberately; don't assume the Ollama default is enough.
- The local tier is for **exploration and summarization**, not long agentic coding. When a task
  needs real reasoning or multi-file edits, **escalate** (see [escalation.md](escalation.md)).
- `:cloud` models are **not local** — they run on Ollama's cloud (not free, not offline), but
  have no local RAM ceiling.

## Cost model

With a Claude subscription, premium runs on your subscription login (no metered API billing).
Local is free; cloud is cheap. The point of determinator is to keep cheap work cheap and pay
for premium only on the hard steps.
