#!/usr/bin/env bash
# Changed-line coverage: of the production lines this branch adds or changes (committed or not), at least the
# minimum in .agent/coverage.txt (default 90%) must run in the tests. Reads the Cobertura reports that
# check_backend.sh (pytest-cov) and check_frontend.sh (@vitest/coverage-*) leave in .agent/work/coverage/.
# No report: skipped. Lines a report doesn't list (comments, blank lines, tests) don't count.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
MB="${MB:-$(git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
REPORTS="$(ls .agent/work/coverage/backend.xml .agent/work/coverage/frontend/cobertura-coverage.xml 2>/dev/null)"
if [ -z "$REPORTS" ]; then
  echo "No coverage report: changed-line coverage not checked (install pytest-cov or @vitest/coverage-v8)."; exit 0
fi
MIN="$(sed -n '/^[^#]/{p;q;}' .agent/coverage.txt 2>/dev/null)"

python3 - "$ROOT" "$MB" "${MIN:-90}" $REPORTS <<'PY'
import os, re, subprocess, sys
import xml.etree.ElementTree as ET
root, mb, minimum, reports = os.path.realpath(sys.argv[1]), sys.argv[2], float(sys.argv[3]), sys.argv[4:]

hits = {}  # repo path -> {line: hits}, for every line a report says can run
for report in reports:
    tree = ET.parse(report)
    sources = [s.text or "" for s in tree.iter("source")] or [root]
    for cls in tree.iter("class"):
        name = cls.get("filename")
        path = next((os.path.join(s, name) for s in sources if os.path.exists(os.path.join(s, name))),
                    os.path.join(sources[0], name))
        lines = hits.setdefault(os.path.relpath(os.path.realpath(path), root), {})
        for line in cls.iter("line"):
            n = int(line.get("number"))
            lines[n] = max(lines.get(n, 0), int(line.get("hits")))

def git(*args):
    return subprocess.run(("git",) + args, cwd=root, capture_output=True, text=True).stdout

changed, path = {}, None  # repo path -> line numbers this branch adds or changes
for l in git("diff", "-U0", "--no-color", mb).splitlines():
    if l.startswith("+++ "):
        path = l[6:] if l.startswith("+++ b/") else None
    elif l.startswith("@@") and path:
        start, count = re.search(r"\+(\d+)(?:,(\d+))?", l).groups()
        changed.setdefault(path, set()).update(range(int(start), int(start) + int(count or 1)))
for path in git("ls-files", "--others", "--exclude-standard").splitlines():  # a new file: every line is new
    if path in hits:
        with open(os.path.join(root, path), errors="replace") as f:
            changed[path] = set(range(1, sum(1 for _ in f) + 1))

measured = [(p, n, hits[p][n]) for p in sorted(changed) if p in hits for n in sorted(changed[p] & set(hits[p]))]
if not measured:
    sys.exit(print("No changed lines that the coverage report measures."))
covered = sum(1 for _, _, h in measured if h)
percent = 100.0 * covered / len(measured)
print("Changed-line coverage: %.0f%% (%d of %d lines, minimum %.0f%%)." % (percent, covered, len(measured), minimum))
if percent < minimum:
    missed = ["%s:%d" % (p, n) for p, n, h in measured if not h]
    print("Not run by any test:")
    for m in missed[:30]:
        print("  " + m)
    if len(missed) > 30:
        print("  … and %d more" % (len(missed) - 30))
    print("Add tests that run these lines, or delete the dead code. Never lower the minimum.")
    sys.exit(1)
PY
