#!/usr/bin/env bash
# One-command setup: copies sdlc-kit into your repo, then checks the result.
# Usage: bash install.sh <your-repo> [--agent claude|codex]... [--tracker jira|linear] [--key PROJ]
#                        [--host gitlab|github] [--force] [--check | --no-check]
# Never overwrites a file that's already there; --force replaces the kit's own files (never your .agent/*.txt).
# Existing hooks.json, .claude/settings.json and AGENTS.md get the kit's part merged in. Agents: Cursor always,
# plus any your repo already uses (.claude/ or CLAUDE.md: Claude Code; .codex/ or AGENTS.md: Codex).
# --check only runs the checks; --no-check skips them.
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
usage() { sed -n '3,4p' "$0" | sed 's/^# //'; exit 2; }
TARGET="" AGENTS="" TRACKER="" KEY="" HOST="" FORCE=0 MODE=install
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) case "${2:-}" in cursor) ;; claude|codex) AGENTS="$AGENTS $2" ;; *) usage ;; esac; shift 2 ;;
    --tracker) case "${2:-}" in jira|linear) TRACKER="$2" ;; *) usage ;; esac; shift 2 ;;
    --host) case "${2:-}" in gitlab|github) HOST="$2" ;; *) usage ;; esac; shift 2 ;;
    --key) KEY="${2:?--key needs a value}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --check) MODE=check; shift ;;
    --no-check) MODE=nocheck; shift ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) TARGET="$1"; shift ;;
  esac
done
[ -n "$TARGET" ] || usage
ROOT="$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null)" || { echo "$TARGET is not a git repository."; exit 1; }
[ "$ROOT" != "$KIT" ] || { echo "That's the kit itself. Point it at your own repo."; exit 1; }

if [ "$MODE" != check ]; then
  if [ -z "$AGENTS" ]; then
    { [ -d "$ROOT/.claude" ] || [ -f "$ROOT/CLAUDE.md" ]; } && AGENTS="$AGENTS claude"
    { [ -d "$ROOT/.codex" ] || [ -f "$ROOT/AGENTS.md" ]; } && AGENTS="$AGENTS codex"
  fi
  echo "Installing sdlc-kit into $ROOT for Cursor${AGENTS:+ +$AGENTS}."
  python3 - "$KIT" "$ROOT" "$AGENTS" "$FORCE" "$TRACKER" "$KEY" "$HOST" <<'PY' || exit 1
import json, os, shutil, sys
kit, root, agents, force, tracker, key, host = sys.argv[1], sys.argv[2], sys.argv[3].split(), sys.argv[4] == "1", *sys.argv[5:]
counts, problems = {"copied": 0, "kept": 0, "replaced": 0}, []

def walk(top):  # files and symlinks under the kit's <top>, without following links or taking local junk
    for dirpath, dirnames, filenames in os.walk(os.path.join(kit, top)):
        for d in list(dirnames):
            path = os.path.join(dirpath, d)
            if d == "__pycache__" or os.path.relpath(path, kit) == os.path.join(".agent", "work"):
                dirnames.remove(d)
            elif os.path.islink(path):  # a skill or rule link: copy the link itself
                dirnames.remove(d)
                yield os.path.relpath(path, kit)
        for f in filenames:
            if f != ".DS_Store" and not f.endswith(".pyc"):
                yield os.path.relpath(os.path.join(dirpath, f), kit)

def place(rel, kit_owned=True):
    src, dst = os.path.join(kit, rel), os.path.join(root, rel)
    exists = os.path.lexists(dst)
    if exists and not (force and kit_owned and not (os.path.isdir(dst) and not os.path.islink(dst))):
        counts["kept"] += 1
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if exists:
        os.remove(dst)
    if os.path.islink(src):
        os.symlink(os.readlink(src), dst)
    else:
        shutil.copy2(src, dst)
    counts["replaced" if exists else "copied"] += 1

def merge_hook(rel, event):  # add the kit's command hook to a hooks file that's already there
    src, dst = os.path.join(kit, rel), os.path.join(root, rel)
    if not os.path.exists(dst):
        return place(rel)
    try:
        with open(dst) as f:
            current = json.load(f)
        entries = current.setdefault("hooks", {}).setdefault(event, [])
        if "block_commands.py" in json.dumps(entries):
            counts["kept"] += 1
            return
        with open(src) as f:
            entries.extend(json.load(f)["hooks"][event])
        with open(dst, "w") as f:
            json.dump(current, f, indent=2)
            f.write("\n")
        print("  merged the command hook into " + rel)
    except (ValueError, AttributeError, TypeError, KeyError) as e:
        problems.append("%s: could not merge the hook (%s). Add it by hand from the kit's %s." % (rel, e, rel))

def merge_agents_md():
    src, dst = os.path.join(kit, "AGENTS.md"), os.path.join(root, "AGENTS.md")
    if not os.path.exists(dst):
        return place("AGENTS.md")
    with open(dst) as f:
        if "# sdlc-kit" in f.read():
            counts["kept"] += 1
            return
    with open(src) as s, open(dst, "a") as d:
        d.write("\n\n" + s.read())
    print("  appended the kit's section to AGENTS.md")

def setting(name, value, comment):  # keep the file's comment lines, replace its value
    path = os.path.join(root, ".agent", name)
    lines = [comment]
    if os.path.exists(path):
        with open(path) as f:
            lines = [l for l in f.read().splitlines() if l.startswith("#")] or [comment]
    with open(path, "w") as f:
        f.write("\n".join(lines + [value]) + "\n")
    print("  .agent/%s: %s" % (name, value))

for rel in walk(".cursor"):
    merge_hook(rel, "beforeShellExecution") if rel == os.path.join(".cursor", "hooks.json") else place(rel)
for rel in walk(".agent"):
    place(rel, kit_owned=False)
if "claude" in agents:
    for top in (os.path.join(".claude", "rules"), os.path.join(".claude", "skills")):
        for rel in walk(top):
            place(rel)
    merge_hook(os.path.join(".claude", "settings.json"), "PreToolUse")
if "codex" in agents:
    for rel in walk(os.path.join(".agents", "skills")):
        place(rel)
    merge_agents_md()
if tracker:
    setting("tracker.txt", tracker, "# The ticket tracker, on the next line: jira or linear. Humans edit this file, not the agent.")
if key:
    setting("jira-project.txt", key, "# Jira project key (Linear: team key) for /jira-create, on the next line. Humans edit this file, not the agent.")
if host:
    setting("git-host.txt", host, "# The MR host, on the next line: gitlab or github. Humans edit this file, not the agent.")
print("  copied %(copied)d files, replaced %(replaced)d, kept %(kept)d that were already there" % counts
      + ("" if force or not counts["kept"] else " (--force replaces the kit's own files)"))
for p in problems:
    print("  PROBLEM: " + p)
sys.exit(1 if problems else 0)
PY
  chmod +x "$ROOT"/.cursor/skills/*/scripts/*.sh
fi
[ "$MODE" = nocheck ] && exit 0
DOCTOR="$ROOT/.cursor/skills/run-checks/scripts/doctor.sh"
[ -f "$DOCTOR" ] || { echo "The kit isn't installed in $ROOT yet: run this without --check."; exit 1; }
echo; cd "$ROOT" && exec bash "$DOCTOR"
