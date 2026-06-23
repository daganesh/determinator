---
description: Run this project's test suite and report pass/fail. Adapt to your project.
argument-hint: "[extra test args]"
allowed-tools: Bash
---
Run the project's tests and report a concise pass/fail summary. This template
auto-detects a common runner; edit `~/.claude/commands/test.md` for your project.

!`if [ -f package.json ]; then npm test --silent $ARGUMENTS; \
elif [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -d tests ]; then pytest -q $ARGUMENTS; \
elif [ -f Makefile ] && grep -qE '^test:' Makefile; then make test; \
else echo "No known test runner found — edit ~/.claude/commands/test.md."; fi`
