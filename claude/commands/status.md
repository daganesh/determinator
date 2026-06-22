---
description: Show the active determinator tier plus this repo's git status.
allowed-tools: Bash(determinator:*), Bash(git:*)
---
!`echo "== tier =="; determinator which 2>/dev/null || echo "n/a (not in a determinator session)"; echo; echo "== git =="; git status -sb 2>/dev/null | head -30 || echo "not a git repo"`
