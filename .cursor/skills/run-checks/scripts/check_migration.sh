#!/usr/bin/env bash
# Alembic round trip on the LOCAL/TEST database: upgrade → downgrade (one step per changed
# migration file) → upgrade, exactly one head, and no drift between models and migrations.
# Ends with "MIGRATION PASS" or "MIGRATION FAIL".
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${PYTHON:-python}"
cd "$ROOT/backend"
source "$HERE/db_guard.sh"
db_guard required || { echo "MIGRATION FAIL"; exit 1; }

# Steps to round-trip = migration files changed on this branch (CHANGED comes from check_all.sh).
# 0 means only models changed, so just check drift. Run on its own: round-trip the last migration.
N=1
if [ -n "${CHANGED:-}" ]; then
  N=$(echo "$CHANGED" | grep -E '^backend/alembic/versions/[^/]+\.py$' | grep -v '/__init__\.py$' \
    | while read -r f; do [ -f "$ROOT/$f" ] && echo "$f"; done | grep -c . || true)
fi

fail=0
step() { echo "> $*"; "$@" 2>&1 | tail -n 20; [ "${PIPESTATUS[0]}" -eq 0 ] || fail=1; }

step $PY -m alembic upgrade head
if [ "$N" -gt 0 ]; then
  [ $fail -eq 0 ] && step $PY -m alembic downgrade "-$N"
  [ $fail -eq 0 ] && step $PY -m alembic upgrade head
fi

heads=$($PY -m alembic heads 2>/dev/null | grep -c . || true)
echo "> alembic heads: $heads"
[ "$heads" = "1" ] || { echo "Expected exactly 1 head."; fail=1; }
[ "$heads" -gt 1 ] && echo "Main has a newer migration: point your migration's down_revision at it (/db-migration step 7)."

echo "> alembic check (models match migrations)"
$PY -m alembic check 2>&1 | tail -n 10 || fail=1

if [ $fail -eq 0 ]; then echo "MIGRATION PASS"; else echo "MIGRATION FAIL"; fi
exit $fail
