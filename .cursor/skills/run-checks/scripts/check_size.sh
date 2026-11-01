#!/usr/bin/env bash
# Fails if any changed source/test file is longer than MAX_LINES (default 200), or a React component
# (frontend/src/*.tsx, not tests) is longer than 150.
# Exempt: shadcn generated components, the generated API types, lock files, paths listed in .agent/size-allowlist.txt
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
MAX="${MAX_LINES:-200}"
COMPONENT_MAX=150
ALLOW=".agent/size-allowlist.txt"
MB="${MB:-$(git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
CHANGED="${CHANGED:-$({ git diff --name-only "$MB"; git ls-files --others --exclude-standard; } | sort -u)}"

fail=0
while IFS= read -r f; do
  [ -z "$f" ] || [ ! -f "$f" ] && continue
  case "$f" in
    *.py|*.ts|*.tsx|*.js|*.jsx|*.css|*.sql|*.sh) ;;
    *) continue ;;
  esac
  case "$f" in
    frontend/src/components/ui/*|*.lock|*-lock.*|*.min.js|"${API_TYPES:-frontend/src/api/schema.d.ts}") continue ;;
  esac
  if [ -f "$ALLOW" ] && grep -qxF "$f" "$ALLOW"; then continue; fi
  max="$MAX"
  case "$f" in *.test.tsx|*.spec.tsx) ;; frontend/src/*.tsx) max="$COMPONENT_MAX" ;; esac
  n=$(wc -l < "$f" | tr -d ' ')
  if [ "$n" -gt "$max" ]; then
    echo "TOO LONG ($n > $max lines): $f  → split it by responsibility"
    fail=1
  fi
done <<< "$CHANGED"

[ $fail -eq 0 ] && echo "All changed files are within the size limits ($MAX lines, components $COMPONENT_MAX)."
exit $fail
