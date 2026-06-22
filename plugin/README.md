# determinator plugin (optional)

A thin Claude Code plugin wrapper. **It is not required** — the shell installer
(`make install`) is the authoritative way to use determinator.

## What a plugin can and cannot do here

- ✅ Bundle the local-LLM MCP workers (`.mcp.json`).
- ✅ Add a `SessionStart` hook that prints the active tier.
- ❌ **Switch tiers.** Tier switching means setting `ANTHROPIC_BASE_URL` / `ANTHROPIC_AUTH_TOKEN`
  in your shell before launching `claude`. A plugin runs *inside* an already-started Claude Code
  session and cannot change which backend that session connects to. So `determinator local|cloud|premium`
  and the escalation commands remain shell-level — provided by the installer, not this plugin.

## Use it only if

You already ran `make install` (so `$DETERMINATOR_HOME` exists and the MCP server is on disk),
and you prefer registering the MCP workers via a plugin instead of the installer's `claude mcp add`.
The `.mcp.json` here points at `${DETERMINATOR_HOME}/mcp/local_workers/server.py`.

For everyone else: skip this directory and just use `make install`.
