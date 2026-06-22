---
description: Commit staged changes (message drafted by the local model) and push.
allowed-tools: Bash(git:*), mcp__determinator-local-workers__gen_commit_msg
---
Do this without spending premium tokens on the message:

1. Run `git diff --staged`. If it's empty, stop and tell me to stage changes first.
2. Use the `gen_commit_msg` tool (local model) with the staged diff to draft a commit message.
3. Show me the message, then `git commit` with it and `git push`.
