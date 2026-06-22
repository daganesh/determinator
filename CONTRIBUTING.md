# Contributing

Thanks for your interest in determinator.

## Ground rules

- **No secrets, ever.** `secrets.env` and `*.det.bak` are git-ignored. Don't commit API keys.
- **Stay vendor-neutral.** No employer-internal paths, repo names, URLs, or real session data.
- **Portable bash.** Target macOS (bash 3.2) and Linux. Avoid `mapfile`, associative arrays,
  GNU-only `sed -i`, and `readlink -f`. OS specifics live in `scripts/detect-os.sh`.
- **Idempotent + reversible.** Every install step must be safe to re-run and fully undone by
  `scripts/uninstall.sh` (sentinel-delimited blocks, one-time `.det.bak`, jq-merge not clobber).

## Before you open a PR

Run the test suite (no network needed):

```bash
bash test/test-mcp-protocol.sh
bash test/test-commands-frontmatter.sh
bash test/test-idempotency.sh
```

On a machine with `ollama` + `claude` installed, also run the full end-to-end check:

```bash
make doctor
```

## Scope

determinator is a **manual** router by design — keep it that way. Automatic difficulty-based
routing is explicitly out of scope (see the README's "Prior art" note).
