# determinator

**A 3-tier model router for Claude Code.** Run the same Claude Code on a free local
model, a cheap cloud model, or your premium Claude subscription — and escalate the hard
parts on demand. You pick the tier; nothing decides for you.

Most agent work is cheap and repetitive (tests, git, status, grep, summaries) and doesn't
need a premium model. A minority (planning, real coding, test review) does. determinator lets
you keep the cheap work on a local/cloud [Ollama](https://ollama.com) model and *escalate*
specific high-value jobs to premium Claude — surgically, one call at a time.

> Built on the [Ollama → Claude Code integration](https://docs.ollama.com/integrations/claude-code):
> all three tiers are the **same `claude` binary**; only the backend changes via environment variables.

## The three tiers

| Tier | Backend | Cost | Use for |
|---|---|---|---|
| **local** | Claude Code → local Ollama (`localhost:11434`) | free, on-machine | exploration, summaries, status, running tests/git |
| **cloud** | Claude Code → Ollama `:cloud` model | cheap | same, when local RAM is the limit |
| **premium** | Claude Code → Anthropic via your **Claude subscription** (OAuth); API key optional | subscription (no metered API) | planning, coding, test review |

```bash
determinator local            # start a session on the free local model (alias: dt local)
determinator premium          # start a session on your Claude subscription
determinator which            # show the active tier/model
```

From inside a cheap session, escalate just the hard step to premium — without paying premium
for the whole session:

```
/plan add a retry with backoff to the http client     # headless premium planner (read-only)
/code-task implement the plan in client.py            # headless premium implementer
/review-tests                                          # headless premium test review
```

Local-LLM **MCP workers** (`summarize_diff`, `gen_commit_msg`, `triage_log`) run on the free
model even inside a premium session, so cheap language tasks never cost premium tokens.
`/insights` analyzes your own usage so you can tune which work goes where.

## Install

macOS or Linux:

```bash
git clone https://github.com/daganesh/determinator.git
cd determinator
make install
```

The installer (`install.sh`) detects your OS, ensures `ollama`/`claude`/`python3`/`jq`, pulls
the default local model, wires the tier shell functions, registers the MCP workers, and
installs the slash commands. It is **idempotent and reversible** — `make uninstall` cleanly
reverts everything. Verify any time with `make doctor`.

Premium defaults to your existing `claude` subscription login — **no API key is asked for**.
A metered `ANTHROPIC_API_KEY` is opt-in only.

## Reality check

A 7–14B local model on a 32 GB machine is good for *exploration and summarization only*.
Claude Code wants ≥64k context; local tiers are **not** for long agentic coding. determinator's
value is making **escalation** cheap and explicit, not replacing premium for hard work.

## What's in the box

- `bin/determinator`, `bin/determinator-escalate` — the tier launcher and the premium escalation isolator
- `install.sh` + `Makefile` + `scripts/` — idempotent installer/uninstaller/doctor
- `mcp/local_workers/` — stdio MCP server exposing 3 Ollama-backed tools
- `claude/commands/` — `/plan`, `/code-task`, `/review-tests`, `/insights`, `/test`, `/status`, `/commit-push`
- `analytics/` — `analyze_sessions.py` usage analyzer (+ a sanitized sample)
- `agents/` — starter `.agents/` knowledge base on when to use which tier
- `plugin/` — optional Claude Code plugin wrapper (convenience only; cannot switch tiers)

## Prior art

Routing here is **manual by design** — you pick the tier; `/plan` etc. escalate. If automatic
difficulty-based routing is ever wanted, [maslul](https://github.com/iliatankelevich/maslul)
is the reference (`verify_cascade`, `bypass_predicate`) — but it is a Python library for routing
*cloud API calls*, not Claude Code, so it is cited as prior art only, **not a dependency**.

## License

[MIT](LICENSE).
