---
description: Analyze your Claude Code usage (tools, bash, git, re-reads) to tune your tiers.
argument-hint: "[--days N] [--path FILE] [--top N]"
allowed-tools: Bash(python3:*)
---
!`python3 "${DETERMINATOR_HOME:-$HOME/.local/share/determinator}/analytics/analyze_sessions.py" $ARGUMENTS`
