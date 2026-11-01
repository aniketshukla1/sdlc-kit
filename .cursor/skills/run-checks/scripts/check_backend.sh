#!/usr/bin/env bash
# Backend: ruff + format + mypy on changed Python files, then the full pytest suite
# (skipped, and FAIL, when the DB URL points at a host that isn't local: see db_guard.sh).
# Adapt PYTHON if your venv/runner differs (e.g. PYTHON="poetry run python").
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${PYTHON:-python}"
MB="${MB:-$(cd "$ROOT" && git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
CHANGED="${CHANGED:-$(cd "$ROOT" && { git diff --name-only "$MB"; git ls-files --others --exclude-standard; })}"
FILES=$(echo "$CHANGED" | grep -E '^backend/.*\.py$' | sed 's#^backend/##' | while read -r f; do [ -f "$ROOT/backend/$f" ] && echo "$f"; done)
TYPED=$(echo "$FILES" | grep -v '^alembic/' || true)

cd "$ROOT/backend"
fail=0
if [ -n "$FILES" ]; then
  echo "> ruff check";          $PY -m ruff check $FILES || fail=1
  echo "> ruff format --check"; $PY -m ruff format --check $FILES || fail=1
fi
if [ -n "$TYPED" ]; then
  echo "> mypy"; $PY -m mypy --follow-imports=silent $TYPED || fail=1
fi
source "$HERE/db_guard.sh"
if db_guard optional; then
  echo "> pytest (last 40 lines)"
  $PY -m pytest -q -rf --tb=short -p no:cacheprovider 2>&1 | tail -n 40
  [ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
else
  fail=1
fi
exit $fail
