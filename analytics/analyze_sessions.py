#!/usr/bin/env python3
"""Analyze Claude Code session history and summarize tool/command usage.

Reads Claude Code session transcripts (``*.jsonl``) and aggregates how the
agent spent its tool calls — which tools, which bash binaries, which git/gh
subcommands, which files get re-read — so you can decide what to push down to
a cheaper tier (local model, MCP worker, or a deterministic script).

By default it scans ``~/.claude/projects`` for sessions modified in the last
N days. Point ``--path`` at a single ``.jsonl`` file or a directory to analyze
a specific transcript (e.g. the bundled sanitized sample).

This script is provider-neutral and reads only local files. It writes nothing
unless you pass ``--dump-prompts``.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import shlex
import sys
import time
from collections import Counter, defaultdict

DEFAULT_ROOT = os.path.expanduser("~/.claude/projects")


def iter_session_files(path: str | None, root: str, days: int) -> list[str]:
    """Resolve the set of .jsonl transcripts to analyze."""
    if path:
        if os.path.isdir(path):
            return sorted(glob.glob(os.path.join(path, "**", "*.jsonl"), recursive=True))
        return [path]
    cutoff = time.time() - days * 86400
    return sorted(
        f for f in glob.glob(os.path.join(root, "**", "*.jsonl"), recursive=True)
        if os.path.getmtime(f) >= cutoff
    )


def first_binary(cmd: str) -> str:
    """Best-effort first executable in a bash command, skipping VAR=val prefixes."""
    cmd = cmd.strip()
    try:
        parts = shlex.split(cmd)
    except ValueError:
        parts = cmd.split()
    i = 0
    while i < len(parts) and "=" in parts[i] and not parts[i].startswith("-"):
        i += 1
    if i < len(parts):
        return parts[i]
    return cmd.split()[0] if cmd else ""


def analyze(files: list[str]) -> dict:
    tool_counts: Counter = Counter()
    tool_output_tokens: defaultdict = defaultdict(int)
    bash_binary: Counter = Counter()
    git_sub: Counter = Counter()
    gh_sub: Counter = Counter()
    read_files: Counter = Counter()
    slash_cmds: Counter = Counter()
    prompts: list[str] = []
    sessions: set = set()
    totals = {"assistant_msgs": 0, "output_tokens": 0, "cache_read": 0, "cache_creation": 0}

    for f in files:
        try:
            fh = open(f, errors="replace")
        except OSError:
            continue
        with fh:
            for line in fh:
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                sid = r.get("sessionId")
                if sid:
                    sessions.add(sid)
                typ = r.get("type")
                if typ == "assistant":
                    m = r.get("message", {})
                    totals["assistant_msgs"] += 1
                    usage = m.get("usage") or {}
                    ot = usage.get("output_tokens", 0)
                    totals["output_tokens"] += ot
                    totals["cache_read"] += usage.get("cache_read_input_tokens", 0)
                    totals["cache_creation"] += usage.get("cache_creation_input_tokens", 0)
                    for b in (m.get("content") or []):
                        if not (isinstance(b, dict) and b.get("type") == "tool_use"):
                            continue
                        name = b.get("name", "?")
                        tool_counts[name] += 1
                        tool_output_tokens[name] += ot
                        inp = b.get("input") or {}
                        if name == "Bash":
                            cmd = inp.get("command", "")
                            bash_binary[first_binary(cmd)] += 1
                            for seg in re.split(r"&&|;", cmd):
                                seg = seg.strip()
                                if seg.startswith("git "):
                                    git_sub[seg.split()[1] if len(seg.split()) > 1 else "?"] += 1
                                if seg.startswith("gh "):
                                    parts = seg.split()
                                    gh_sub[" ".join(parts[1:3])] += 1
                        elif name == "Read":
                            read_files[inp.get("file_path", "")] += 1
                elif typ == "user":
                    m = r.get("message", {})
                    c = m.get("content")
                    text = c if isinstance(c, str) else "".join(
                        b.get("text", "") for b in c if isinstance(b, dict) and b.get("type") == "text"
                    ) if isinstance(c, list) else ""
                    for mm in re.finditer(r"<command-name>\s*(/?[\w:-]+)", text):
                        slash_cmds[mm.group(1).lstrip("/")] += 1
                    t = text.strip()
                    if t and "<command-name>" not in t and "<local-command-stdout>" not in t \
                            and "tool_result" not in t and not t.startswith("<") and len(t) < 2000:
                        prompts.append(t)

    return {
        "files": len(files), "sessions": len(sessions), "totals": totals,
        "tool_counts": tool_counts, "tool_output_tokens": tool_output_tokens,
        "bash_binary": bash_binary, "git_sub": git_sub, "gh_sub": gh_sub,
        "read_files": read_files, "slash_cmds": slash_cmds, "prompts": prompts,
    }


def show(title: str, counter: Counter, n: int) -> None:
    print(f"\n===== {title} (top {n}) =====")
    for k, v in counter.most_common(n):
        print(f"{v:6d}  {k}")


def report(a: dict, top: int) -> None:
    t = a["totals"]
    print(f"Files analyzed:           {a['files']}")
    print(f"Distinct sessions:        {a['sessions']}")
    print(f"Assistant messages:       {t['assistant_msgs']}")
    print(f"Total tool calls:         {sum(a['tool_counts'].values())}")
    print(f"Output tokens:            {t['output_tokens']:,}")
    print(f"Cache read tokens:        {t['cache_read']:,}")
    print(f"Human prompts captured:   {len(a['prompts'])}")
    show("TOOL USAGE", a["tool_counts"], top)
    print("\n===== TOOL OUTPUT-TOKEN COST =====")
    for k, v in sorted(a["tool_output_tokens"].items(), key=lambda x: -x[1])[:top]:
        print(f"{v:10,d}  {k}  (calls={a['tool_counts'][k]})")
    show("BASH — first binary", a["bash_binary"], top)
    show("GIT subcommands", a["git_sub"], top)
    show("GH subcommands", a["gh_sub"], top)
    show("SLASH COMMANDS", a["slash_cmds"], top)
    show("MOST RE-READ FILES", a["read_files"], top)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--path", help="A .jsonl transcript file or directory to analyze (default: scan ~/.claude/projects)")
    p.add_argument("--root", default=DEFAULT_ROOT, help="Root to scan when --path is not given")
    p.add_argument("--days", type=int, default=30, help="Only sessions modified within N days (default: 30)")
    p.add_argument("--top", type=int, default=25, help="Top-N rows per category (default: 25)")
    p.add_argument("--json", action="store_true", help="Emit raw aggregates as JSON instead of a report")
    p.add_argument("--dump-prompts", metavar="FILE", help="Write captured human prompts to FILE (one per line)")
    p.add_argument("--dry-run", action="store_true", help="List the files that would be analyzed, then exit")
    args = p.parse_args(argv)

    files = iter_session_files(args.path, args.root, args.days)
    if args.dry_run:
        print(f"Would analyze {len(files)} file(s):")
        for f in files:
            print(f"  {f}")
        return 0
    if not files:
        print("No session files found.", file=sys.stderr)
        return 1

    a = analyze(files)
    if args.dump_prompts:
        with open(args.dump_prompts, "w") as out:
            out.write("\n".join(pr.replace("\n", " ")[:300] for pr in a["prompts"]))
    if args.json:
        serializable = {k: (dict(v) if isinstance(v, (Counter, defaultdict)) else v)
                        for k, v in a.items() if k != "prompts"}
        print(json.dumps(serializable, indent=2))
    else:
        report(a, args.top)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
