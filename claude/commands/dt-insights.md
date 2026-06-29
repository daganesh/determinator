---
description: Analyze your Claude Code usage (tools, bash, git, re-reads, cache hit rate) to tune your tiers.
argument-hint: "[--days N] [--path FILE] [--top N] [--price USD_PER_MTOK]"
allowed-tools: Bash(python3:*)
---
!`python3 "${DETERMINATOR_HOME:-$HOME/.local/share/determinator}/analytics/analyze_sessions.py" $ARGUMENTS`
