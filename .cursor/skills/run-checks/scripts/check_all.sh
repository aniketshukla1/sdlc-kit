#!/usr/bin/env bash
# Runs all checks for files changed on this branch (committed + uncommitted + untracked + deleted).
# Last line is "ALL PASS" or "FAIL: <checks>". Exit code 0 / 1.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

BASE="${BASE_REF:-origin/main}"
git fetch -q origin "${BASE#origin/}" 2>/dev/null || true
if ! MB="$(git merge-base "$BASE" HEAD 2>/dev/null)"; then
  echo "Base ref '$BASE' not found, so the changed files are unknown. Set BASE_REF (e.g. BASE_REF=origin/master)."
  echo "FAIL: base-ref"; exit 1
fi
export MB

# Deleted files stay in the list: the guards need them to catch removed tests and protected files.
CHANGED="$({ git diff --name-only "$MB"; git ls-files --others --exclude-standard; } | sort -u)"
export CHANGED

if [ -z "$CHANGED" ]; then
  echo "No changed files vs $BASE."
  echo "ALL PASS"
  exit 0
fi
echo "Changed files vs $BASE:"
echo "$CHANGED" | sed 's/^/  /'

FAILED=""
run() {
  local name="$1"; shift
  echo; echo "=== $name ==="
  if "$@"; then echo "--- $name: PASS"; else echo "--- $name: FAIL"; FAILED="$FAILED $name"; fi
}

run "file-size" bash "$DIR/check_size.sh"
run "guards" bash "$DIR/check_guards.sh"
run "scope" bash "$DIR/check_scope.sh"
if echo "$CHANGED" | grep -q '^backend/'; then run "backend" bash "$DIR/check_backend.sh"; fi
if echo "$CHANGED" | grep -qE '^backend/(alembic/versions|app/models)/'; then run "migration" bash "$DIR/check_migration.sh"; fi
if echo "$CHANGED" | grep -q '^frontend/'; then run "frontend" bash "$DIR/check_frontend.sh"; fi
if echo "$CHANGED" | grep -qE '^(backend|frontend)/'; then run "api-types" bash "$DIR/check_api_types.sh"; fi

echo
if [ -z "$FAILED" ]; then
  echo "ALL PASS"; exit 0
else
  echo "FAIL:$FAILED"; exit 1
fi
