#!/usr/bin/env bash
# Frontend: tsc (whole project), eslint on changed TS files, then the full vitest suite.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
MB="${MB:-$(cd "$ROOT" && git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
CHANGED="${CHANGED:-$(cd "$ROOT" && { git diff --name-only "$MB"; git ls-files --others --exclude-standard; })}"
FILES=$(echo "$CHANGED" | grep -E '^frontend/.*\.(ts|tsx)$' | grep -v '^frontend/src/components/ui/' \
  | sed 's#^frontend/##' | while read -r f; do [ -f "$ROOT/frontend/$f" ] && echo "$f"; done)

cd "$ROOT/frontend"
TSCONFIG="tsconfig.json"; [ -f tsconfig.app.json ] && TSCONFIG="tsconfig.app.json"
fail=0

echo "> tsc --noEmit -p $TSCONFIG (last 40 lines)"
npx --no-install tsc --noEmit -p "$TSCONFIG" 2>&1 | tail -n 40
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1

if [ -n "$FILES" ]; then
  echo "> eslint (changed files)"
  npx --no-install eslint --max-warnings=0 $FILES 2>&1 | tail -n 60
  [ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
fi

COV=()
rm -rf "$ROOT/.agent/work/coverage/frontend"
if grep -qE '"@vitest/coverage-(v8|istanbul)"' package.json 2>/dev/null; then  # for check_coverage.sh
  COV=(--coverage.enabled --coverage.reporter=cobertura "--coverage.include=src/**"
       "--coverage.reportsDirectory=$ROOT/.agent/work/coverage/frontend")
fi
echo "> vitest (last 40 lines)"
npx --no-install vitest run --reporter=dot ${COV[@]+"${COV[@]}"} 2>&1 | tail -n 40
[ "${PIPESTATUS[0]}" -eq 0 ] || fail=1
exit $fail
