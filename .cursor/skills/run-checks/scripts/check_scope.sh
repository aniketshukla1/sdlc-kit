#!/usr/bin/env bash
# Fails if a changed file is not named in the ticket's PLAN.md (hard rule 3).
# The ticket key comes from the branch name. No PLAN.md (human branch, CI): skipped.
# Exempt: lock files, generated shadcn components and API types, the .agent allowlists, and migration
# files when the plan says "Migration: yes".
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
MB="${MB:-$(git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
CHANGED="${CHANGED:-$({ git diff --name-only "$MB"; git ls-files --others --exclude-standard; } | sort -u)}"
KEY="$(git branch --show-current | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n 1)"
PLAN=".agent/work/$KEY/PLAN.md"
if [ -z "$KEY" ] || [ ! -f "$PLAN" ]; then echo "No PLAN.md for this branch: scope not checked."; exit 0; fi
MIGRATION=no; grep -qiE 'Migration:[[:space:]]*yes' "$PLAN" && MIGRATION=yes

fail=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in
    *.lock|*-lock.json|*-lock.yaml|frontend/src/components/ui/*|.agent/guard-exceptions.txt|.agent/size-allowlist.txt) continue ;;
    "${API_TYPES:-frontend/src/api/schema.d.ts}") continue ;;  # generated; check_api_types.sh verifies it
    backend/alembic/versions/*) [ "$MIGRATION" = yes ] && continue ;;
  esac
  { grep -qF -- "$f" "$PLAN" || grep -qF -- "${f#*/}" "$PLAN"; } && continue  # plans may drop backend/ or frontend/
  echo "NOT IN PLAN: $f"; fail=1
done <<< "$CHANGED"

if [ $fail -eq 0 ]; then echo "Every changed file is in $PLAN."
else echo "Revert these, or stop and ask the human to add them to PLAN.md (hard rule 3)."; fi
exit $fail
