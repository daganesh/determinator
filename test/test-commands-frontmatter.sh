#!/usr/bin/env bash
# Lint YAML frontmatter of every slash command; escalation commands must be manual-only.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

python3 - "$REPO/claude/commands" <<'PY'
import re, pathlib, sys
root = pathlib.Path(sys.argv[1])
ok = True
for f in sorted(root.glob("*.md")):
    text = f.read_text()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        print(f"FAIL {f.name}: no frontmatter"); ok = False; continue
    keys = dict(re.findall(r"^([\w-]+):\s*(.*)$", m.group(1), re.M))
    if "description" not in keys:
        print(f"FAIL {f.name}: missing description"); ok = False; continue
    # Escalation commands must be model-invocable (so natural language triggers them)
    # and must route through determinator-escalate.
    if f.name in {"dt-plan.md", "dt-code-task.md", "dt-review-tests.md"}:
        if keys.get("disable-model-invocation", "").strip() == "true":
            print(f"FAIL {f.name}: escalation command must stay model-invocable (drop disable-model-invocation)"); ok = False; continue
        if "determinator-escalate" not in text:
            print(f"FAIL {f.name}: escalation command must call determinator-escalate"); ok = False; continue
    print(f"ok {f.name}")
sys.exit(0 if ok else 1)
PY
echo "PASS: command frontmatter"
