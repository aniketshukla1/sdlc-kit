#!/usr/bin/env bash
# Checks that this repo is ready for the kit: tools, the MR host login, the command hook and the self-tests,
# then says what's left to do. Usage, from the repo: bash .cursor/skills/run-checks/scripts/doctor.sh
# Exit code 0 when every check passes.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$ROOT" || exit 1
S=.cursor/skills
bad=0
check() {  # $1 = what is checked, then the command that must succeed
  if "${@:2}" >/dev/null 2>&1; then echo "  ✓ $1"; else echo "  ✗ $1"; bad=1; fi
}
denies() {  # $1 = hook input, $2 = text the hook's answer must contain
  printf '%s' "$1" | python3 .cursor/hooks/block_commands.py | grep -qF -- "$2"
}

HOST="$(bash "$S/mr-feedback/scripts/mr.sh" host)"
TRACKER="$(sed -n '/^[^#]/{p;q;}' .agent/tracker.txt 2>/dev/null)"; TRACKER="${TRACKER:-jira}"
KEY="$(sed -n '/^[^#]/{p;q;}' .agent/jira-project.txt 2>/dev/null)"
echo "Checking $ROOT (MR host: $HOST, tracker: $TRACKER)"
check "git" command -v git
check "python3" command -v python3
check "ripgrep (rg)" command -v rg
if [ "$HOST" = github ]; then
  check "gh is logged in" gh auth status --active  # only the account gh uses; a stale second login doesn't count
else
  check "glab is logged in" glab auth status
fi
check "the command hook blocks a force push (Cursor)" denies '{"command": "git push --force"}' '"permission": "deny"'
if [ -d .claude ]; then
  check "the command hook blocks a force push (Claude Code)" \
    denies '{"tool_name": "Bash", "tool_input": {"command": "git push --force"}}' '"permissionDecision": "deny"'
fi
echo "  … self-tests (about 20 seconds)"
OUT="$(bash "$S/run-checks/scripts/selftest.sh" 2>&1)"
if [ "$(printf '%s\n' "$OUT" | tail -n 1)" = "ALL OK" ]; then
  echo "  ✓ self-tests: ALL OK"
else
  echo "  ✗ self-tests:"; printf '%s\n' "$OUT" | grep -E '^(WRONG|FAILED)' | sed 's/^/      /'; bad=1
fi
[ -n "$KEY" ] || echo "  ! no project key in .agent/jira-project.txt yet: /jira-create will ask for it"
if [ -d backend ] && ! (cd backend && ${PYTHON:-python} -c "import pytest_cov") >/dev/null 2>&1; then
  echo "  ! install pytest-cov in the backend so the checks measure changed-line coverage"
fi
if [ -f frontend/package.json ] && ! grep -qE '"@vitest/coverage-(v8|istanbul)"' frontend/package.json; then
  echo "  ! add @vitest/coverage-v8 to the frontend so the checks measure changed-line coverage"
fi

echo
echo "Next:"
echo "  1. Commit the kit through a normal MR."
if [ "$TRACKER" = linear ]; then echo "  2. Add Linear's MCP server to your agent: https://mcp.linear.app/mcp"
else echo "  2. Add your Jira MCP server to your agent."; fi
echo "  3. Open the repo in your agent, trust the workspace, and ask it to run: git push --force --dry-run"
echo "     It must be blocked."
echo "  4. Start a ticket: Start ticket PROJ-123. Follow the ticket workflow rule."
echo "     No tracker, or no ticket yet? Skip step 2 and type /chat with what you want done."
exit $bad
