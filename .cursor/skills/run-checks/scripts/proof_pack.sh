#!/usr/bin/env bash
# Prints the "## Proof" section of the MR description from evidence, not from the agent's word: the last
# check_all.sh verdict, the red lines logged in PROGRESS.md (quick track: PLAN.md) and the changed files.
# Exit 1 unless check_all.sh printed ALL PASS on exactly the content of HEAD. After any edit, commit or
# rebase, run /run-checks again. The ticket key comes from the branch name.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
KEY="$(git branch --show-current | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n 1)"
[ -n "$KEY" ] || { echo "No ticket key in the branch name."; exit 1; }
REC=".agent/work/$KEY/last-check.txt"
[ -f "$REC" ] || { echo "No check record ($REC). Run /run-checks first."; exit 1; }
field() { sed -n "s/^$1: *//p" "$REC" | head -n 1; }

VERDICT="$(field verdict)"
if [ "$VERDICT" != "ALL PASS" ]; then
  echo "The last check did not pass ($VERDICT). Fix it, then run /run-checks again."; exit 1
fi
if [ "$(field tree)" != "$(git rev-parse 'HEAD^{tree}')" ]; then
  echo "The last check ran on different content than HEAD: something changed after it, or isn't committed yet."
  echo "Commit what belongs in the MR, then run /run-checks again."; exit 1
fi
BASE="${BASE_REF:-origin/main}"
MB="$(git merge-base "$BASE" HEAD 2>/dev/null)" || { echo "Base ref '$BASE' not found. Set BASE_REF."; exit 1; }
RED="$(cat ".agent/work/$KEY/PROGRESS.md" ".agent/work/$KEY/PLAN.md" 2>/dev/null | grep -F ': red: ' | sed -E 's/^[[:space:]]*[-*][[:space:]]+//')"

echo "## Proof"
echo "\`check_all.sh\` printed ALL PASS on exactly this commit, \`$(git rev-parse --short HEAD)\` (checked $(field time))."
echo "Checks that ran: $(field checks)"
echo
echo "Tests written first, each shown failing before its code (as logged in PROGRESS.md / PLAN.md):"
if [ -n "$RED" ]; then printf '```text\n%s\n```\n' "$RED"; else echo "None logged."; fi
echo
echo "Changed files vs \`$BASE\`:"
printf '```text\n%s\n```\n' "$(git diff --name-status "$MB" HEAD)"
