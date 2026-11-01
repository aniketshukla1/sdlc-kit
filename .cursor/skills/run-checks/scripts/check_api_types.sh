#!/usr/bin/env bash
# Fails if the generated API types (default frontend/src/api/schema.d.ts) don't match the backend's OpenAPI
# schema. `--write` regenerates them. No types file yet: skipped (setup: README step 6).
# Settings: API_TYPES (the file), OPENAPI_APP (default app.main:app, imported from backend/), PYTHON.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
PY="${PYTHON:-python}"
OUT="${API_TYPES:-frontend/src/api/schema.d.ts}"
if [ ! -f "$ROOT/$OUT" ] && [ "${1:-}" != --write ]; then echo "No $OUT: generated API types not set up, skipped."; exit 0; fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# A fixed hash seed, so the same schema always gives the same file.
(cd "$ROOT/backend" && PYTHONHASHSEED=0 $PY -c 'import json, sys
from importlib import import_module
module, _, attr = sys.argv[1].partition(":")
with open(sys.argv[2], "w") as f:
    json.dump(getattr(import_module(module), attr).openapi(), f)' "${OPENAPI_APP:-app.main:app}" "$TMP/openapi.json") \
  || { echo "Could not export the OpenAPI schema. Set OPENAPI_APP if the app isn't app.main:app."; exit 1; }
(cd "$ROOT/frontend" && npx --no-install openapi-typescript "$TMP/openapi.json" -o "$TMP/schema.d.ts") > "$TMP/log" 2>&1 \
  || { echo "openapi-typescript failed:"; tail -n 20 "$TMP/log"; exit 1; }

if [ "${1:-}" = --write ]; then
  mkdir -p "$(dirname "$ROOT/$OUT")" && cp "$TMP/schema.d.ts" "$ROOT/$OUT" && echo "Wrote $OUT."; exit
fi
if cmp -s "$TMP/schema.d.ts" "$ROOT/$OUT"; then echo "$OUT matches the backend API."; exit 0; fi
diff -u "$ROOT/$OUT" "$TMP/schema.d.ts" | head -n 30
echo "API TYPES STALE: run bash .cursor/skills/run-checks/scripts/check_api_types.sh --write, then fix what tsc reports."
exit 1
