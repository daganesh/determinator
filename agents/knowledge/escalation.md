# Escalation — two paradigms

From a cheap session you can run one job on a stronger model. determinator has **two** ways
to do this; `/dt-plan`, `/dt-code-task`, `/dt-review-tests` auto-pick based on your backend.

## Paradigm 1 — Subagent (in-context, same backend)

When your session is already on the **Anthropic** backend (`determinator reasoning`), escalation
is an **in-session subagent** with a `model:` override — defined in `claude/agents/dt-*.md`
(`dt-plan`→opus, `dt-code`→sonnet, `dt-review`→opus). The parent passes the task **plus
relevant context** from the live conversation; the subagent runs on a stronger model and
returns its result into the same session. No separate process, context preserved.

- Trade-off: a subagent **cannot cross backends**. `ANTHROPIC_BASE_URL` is process-global, so
  this only switches *tiers within Anthropic* (haiku/sonnet/opus). It can't reach Anthropic
  from a local Ollama session.
- Full context: a subagent starts fresh by default; the parent decides what context to pass.
  (`CLAUDE_CODE_FORK_SUBAGENT=1` makes subagents inherit the full conversation — advanced.)

## Paradigm 2 — Process (separate `claude -p`, crosses backends)

When your session is on **local/cloud** (Ollama), a subagent can't reach the reasoning tier,
so escalation runs `determinator-escalate <mode> "<task>"` — a separate headless `claude -p`
process wired to the target tier's backend (default the reasoning tier; `--tier` to override).

- Crosses backends: this is the only way to jump local Ollama → Anthropic.
- Trade-off: the process is **context-blind** — it sees the task text + the repo on disk, not
  your live conversation. Ground tasks in files; pass state via a file (write `PLAN.md`, then
  `/dt-code-task implement PLAN.md`). `claude -p` has a ~10 MB stdin limit — reference big
  inputs by path.

## Which fires when

| Session backend | Paradigm used | Why |
|---|---|---|
| Anthropic (`reasoning`) | Subagent (in-context) | same backend → context-aware, no new process |
| local / cloud (Ollama) | Process (`determinator-escalate`) | only way to cross into Anthropic |

The commands run `determinator which` first and branch automatically.
