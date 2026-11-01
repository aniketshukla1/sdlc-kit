#!/usr/bin/env bash
# Tests the run-checks scripts (in a throwaway git repo), the mr-feedback scripts and the Cursor command hook.
# Run it after changing any of them.
# Backend, frontend and migration checks are replaced by stubs, so no Python/Node is needed;
# the real migration and backend checks run with PYTHON=echo or a fake python; glab, npx and the OpenAPI export are faked.
# Last line is "ALL OK" or "FAILED: <n> case(s)". Exit code 0 / 1.
set -uo pipefail
unset CHANGED MB

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"; F="$(mktemp -d)"  # F: fake tools, outside the repo so git clean keeps them
trap 'rm -rf "$T" "$F"' EXIT
cd "$T" || exit 1
git init -q -b main . || exit 1
git config user.email selftest@example.com; git config user.name selftest
git config commit.gpgsign false; git config core.hooksPath /dev/null
[ "$(git rev-parse --show-toplevel)" = "$(pwd -P)" ] || { echo "Not in the temp repo; stopping."; exit 1; }

S=.cursor/skills/run-checks/scripts
mkdir -p "$S" .agent backend/app/models backend/tests backend/alembic/versions frontend/src
cp "$SRC/check_all.sh" "$SRC/check_size.sh" "$SRC/check_guards.sh" "$SRC/check_scope.sh" "$SRC/check_api_types.sh" "$S/"
cp "$SRC/check_migration.sh" real_check_migration.sh; cp "$SRC/check_backend.sh" real_check_backend.sh
cp "$SRC/db_guard.sh" .
for s in check_backend check_frontend check_migration; do printf 'echo "RAN %s"\n' "$s" > "$S/$s.sh"; done
printf '# none\n' > .agent/guard-exceptions.txt
printf '# none\n' > .agent/size-allowlist.txt
printf 'work/\n' > .agent/.gitignore
printf 'x = 1\n' > backend/app/models/order.py
printf 'def test_a():\n    assert 1 == 1\n\n\ndef test_b():\n    assert 2 == 2\n' > backend/tests/test_order.py
printf 'stages: [test]\n' > .gitlab-ci.yml
printf '[tool.ruff]\nselect = ["E", "F"]\n' > pyproject.toml
printf 'export const a = 1;\n' > frontend/src/a.ts
printf 'revision = "001"\n' > backend/alembic/versions/001_init.py
seq 1 10 | sed 's/^/y = /' > backend/app/ten.py
git add -A && git commit -qm base || exit 1
export BASE_REF=main
failures=0

start() { git reset -q --hard && git clean -qfd && git switch -q main && git switch -qC case; }
verdict() {  # $1 = case, $2 = 1 if as expected, $3 = output
  if [ "$2" -eq 1 ]; then echo "ok    $1"; return; fi
  echo "WRONG $1"; printf '%s\n' "$3" | sed 's/^/      /'; failures=$((failures + 1))
}
expect() {  # $1 = case, $2 = PASS|FAIL, then text the check_all output must contain
  local name="$1" want="$2" out last s ok=1; shift 2
  out="$(bash "$S/check_all.sh" 2>&1)"; last="$(printf '%s\n' "$out" | tail -n 1)"
  if [ "$want" = PASS ]; then [ "$last" = "ALL PASS" ] || ok=0; else [ "${last#FAIL}" != "$last" ] || ok=0; fi
  for s in "$@"; do printf '%s\n' "$out" | grep -qF -- "$s" || ok=0; done
  verdict "$name" "$ok" "$out"
}
mig() {  # $1 = case, $2 = CHANGED ("" = run on its own), $3 = text that must appear, $4 = text that must not
  local out ok=1
  if [ -n "$2" ]; then out="$(CHANGED="$2" DB_URL_VAR=SELFTEST_DB SELFTEST_DB=mysql://u:p@localhost:3306/app PYTHON=echo bash real_check_migration.sh 2>&1)"
  else out="$(DB_URL_VAR=SELFTEST_DB SELFTEST_DB=mysql://u:p@localhost:3306/app PYTHON=echo bash real_check_migration.sh 2>&1)"; fi
  printf '%s\n' "$out" | grep -qF -- "$3" || ok=0
  if [ -n "$4" ] && printf '%s\n' "$out" | grep -qF -- "$4"; then ok=0; fi
  [ "$(printf '%s\n' "$out" | tail -n 1)" = "MIGRATION PASS" ] || ok=0
  verdict "$1" "$ok" "$out"
}

start; printf 'def helper():\n    return 1\n' > backend/app/util.py
expect "normal change passes" PASS
start; printf 'print("debug")\n' >> backend/app/models/order.py
expect "print() fails" FAIL "[debug/ignore]"
start; printf 'print("debug")\n' >> backend/app/models/order.py; git commit -qam wip
expect "committed change is still checked" FAIL "[debug/ignore]"
start; export BASE_REF=origin/main
expect "missing base ref fails" FAIL "FAIL: base-ref"
ok=0; out="$(bash "$S/check_guards.sh" 2>&1)" || { printf '%s\n' "$out" | grep -qF "Base ref not found" && ok=1; }
verdict "missing base ref fails (guards run alone)" "$ok" "$out"
export BASE_REF=main

start; git rm -q backend/tests/test_order.py
expect "deleted test file fails" FAIL "[tests removed]"
start; printf 'def test_a():\n    assert 1 == 1\n' > backend/tests/test_order.py
expect "removed test function fails" FAIL "[tests removed]"
start; git mv backend/tests/test_order.py backend/tests/test_orders.py
expect "renamed test file passes" PASS
start; printf '\nimport pytest\n\n\n@pytest.mark.xfail\ndef test_c():\n    pytest.skip("later")\n' >> backend/tests/test_order.py
expect "xfail and pytest.skip fail" FAIL "[skipped test]"
start; mkdir -p frontend/e2e; printf 'xit("a", () => {});\ntest.fixme("b", async () => {});\nit.todo("c");\n' > frontend/e2e/flow.spec.ts
expect "xit, test.fixme and it.todo fail" FAIL "[skipped test]"

start; git rm -q .gitlab-ci.yml
expect "deleted .gitlab-ci.yml fails" FAIL "approval] .gitlab-ci.yml"
start; printf '[tool.ruff]\nselect = []\n' > pyproject.toml
expect "weakened pyproject.toml fails" FAIL "approval] pyproject.toml"
start; printf 'export default {};\n' > frontend/vitest.config.ts; printf 'src/\n' > frontend/.eslintignore
printf '[pytest]\naddopts = -k "not orders"\n' > backend/pytest.ini
expect "test config files fail" FAIL "approval] frontend/vitest.config.ts" "approval] frontend/.eslintignore" "approval] backend/pytest.ini"
start; printf 'pyproject.toml\n' >> .agent/guard-exceptions.txt; printf '[tool.ruff]\nselect = ["E"]\n' > pyproject.toml
expect "human exception passes" PASS "[human exception] pyproject.toml"

start; printf 'x = 2\n' > backend/app/models/order.py
expect "model change runs the migration check" PASS "RAN check_migration"
start; mkdir -p backend/alembic/versions  # git clean removes empty folders
printf 'x\n' > backend/alembic/versions/001_a.py; printf 'x\n' > backend/alembic/versions/002_b.py
mig "migration check alone round-trips 1 step" "" "downgrade -1" ""
mig "models-only change skips the round trip" "backend/app/models/order.py" "alembic upgrade head" "downgrade"
mig "2 new migrations round-trip 2 steps" "$(printf 'backend/alembic/versions/001_a.py\nbackend/alembic/versions/002_b.py')" "downgrade -2" ""
cat > fake_py <<'EOF'
#!/usr/bin/env bash
case "$*" in *" heads") printf 'a1 (head)\nb2 (head)\n' ;; *) echo "$@" ;; esac
EOF
chmod +x fake_py
out="$(DB_URL_VAR=SELFTEST_DB SELFTEST_DB=mysql://u:p@localhost:3306/app PYTHON="$T/fake_py" bash real_check_migration.sh 2>&1)"
ok=0; printf '%s\n' "$out" | grep -qF "/db-migration step 7" && [ "$(printf '%s\n' "$out" | tail -n 1)" = "MIGRATION FAIL" ] && ok=1
verdict "2 heads fail and say how to fix them" "$ok" "$out"

plan() { mkdir -p .agent/work/PROJ-1; printf '%s\n' "$@" > .agent/work/PROJ-1/PLAN.md; git switch -qC feature/PROJ-1-scope; }
start; plan '| `app/util.py` | New |'; printf 'def helper():\n    return 1\n' > backend/app/util.py
expect "planned file passes the scope check" PASS "Every changed file is in"
start; plan '| `backend/app/util.py` | New |'; printf 'y = 1\n' > backend/app/other.py
expect "unplanned file fails the scope check" FAIL "NOT IN PLAN: backend/app/other.py"
start; plan '- Migration: yes'; mkdir -p backend/alembic/versions; printf 'x\n' > backend/alembic/versions/003_c.py
expect "migration file passes when the plan has one" PASS "Every changed file is in"

HOOK="$SRC/../../../hooks/block_commands.py"
if [ -f "$HOOK" ]; then
  out="$(python3 "$HOOK" --selftest 2>&1)"; verdict "Cursor hook rules" "$(( $? == 0 ))" "$out"
  out="$(printf '{"command": "git push --force"}' | python3 "$HOOK" 2>&1)"
  ok=0; printf '%s' "$out" | grep -qF '"permission": "deny"' && ok=1; verdict "Cursor hook denies over stdin" "$ok" "$out"
  out="$(printf '{"command": "git status"}' | python3 "$HOOK" 2>&1)"
  ok=0; printf '%s' "$out" | grep -qF '"permission": "allow"' && ok=1; verdict "Cursor hook allows over stdin" "$ok" "$out"
fi

start; printf 'CONFIG = {"password": "hunter2hunter2"}\n' > backend/app/conf_a.py
printf 'URL = "https://x/?k=glpat-%s"\n' abcdefghijklmnopqrst > backend/app/conf_b.py  # split: no token in this file
expect "dict-style secret and GitLab token fail" FAIL "[possible secret] backend/app/conf_a.py" "[possible secret] backend/app/conf_b.py"
start; sed -i.bak '8s/.*/print("debug")/' backend/app/ten.py && rm backend/app/ten.py.bak
expect "guard output names the real line" FAIL 'line 8: print("debug")'
start; printf 'API_URL=\n' > frontend/.env.example
expect ".env.example in a subfolder passes" PASS
start; printf 'revision = "001b"\n' > backend/alembic/versions/001_init.py
expect "editing a migration from main fails" FAIL "[migration already on main] backend/alembic/versions/001_init.py"
start; seq 1 160 | sed 's#^#// line #' > frontend/src/Big.tsx
expect "160-line component fails" FAIL "TOO LONG (160 > 150 lines): frontend/src/Big.tsx"
start; printf 'def cancel(order_id):\n    raise NotImplementedError\n' > backend/app/cancel.py
expect "a stub left from test-first fails" FAIL "[unfinished: finish the stub or handle the error] backend/app/cancel.py"
start; printf 'def load():\n    try:\n        return 1\n    except ValueError:\n        pass\n' > backend/app/load.py
expect "an error swallowed over two lines fails" FAIL "[unfinished: swallowed error] backend/app/load.py" "line 4:"
start; printf 'export function f() {\n  try { g(); } catch (e) {}\n}\n' > frontend/src/f.ts
expect "an empty catch fails" FAIL "[unfinished: finish the stub or handle the error] frontend/src/f.ts"
start; printf 'import pytest\n\n\ndef test_stub_raises():\n    with pytest.raises(NotImplementedError):\n        raise NotImplementedError\n' > backend/tests/test_stub.py
expect "a stub inside a test file passes" PASS

cat > "$F/npx" <<'EOF'
#!/usr/bin/env bash
cp "$3" "$5"  # called as: npx --no-install openapi-typescript <schema> -o <types file>
EOF
cat > "$F/python" <<'EOF'
#!/usr/bin/env bash
{ echo "$SELFTEST_API"; seq 1 250; } > "${@: -1}"  # stands in for the OpenAPI export, which writes its last argument
EOF
chmod +x "$F/npx" "$F/python"
api() {  # $1 = case, $2 = expected exit code, $3 = text the output must contain, then check_api_types.sh arguments
  local name="$1" want="$2" text="$3" out rc ok=0; shift 3
  out="$(PYTHON="$F/python" PATH="$F:$PATH" bash "$S/check_api_types.sh" "$@" 2>&1)"; rc=$?
  [ "$rc" -eq "$want" ] && printf '%s\n' "$out" | grep -qF -- "$text" && ok=1
  verdict "$name" "$ok" "$out"
}
start; export SELFTEST_API=v1
api "API types check skips until set up" 0 "not set up, skipped"
api "API types --write creates the file" 0 "Wrote frontend/src/api/schema.d.ts" --write
api "current API types pass" 0 "matches the backend API"
export SELFTEST_API=v2
api "stale API types fail" 1 "API TYPES STALE"
start; plan '- Migration: no'; export SELFTEST_API=v1 PYTHON="$F/python" OLDPATH="$PATH" PATH="$F:$PATH"
bash "$S/check_api_types.sh" --write >/dev/null
expect "a 251-line generated types file passes size and scope" PASS "matches the backend API" "Every changed file is in"
export PATH="$OLDPATH"; unset SELFTEST_API PYTHON OLDPATH

db() {  # $1 = case, $2 = script, then VAR=value settings; as expected when the script refuses the database
  local name="$1" script="$2" out ok=0; shift 2
  out="$(env "$@" PYTHON=echo bash "$script" 2>&1)" || { printf '%s\n' "$out" | grep -qF "Refusing:" && ok=1; }
  verdict "$name" "$ok" "$out"
}
start
db "migration check refuses a remote database" real_check_migration.sh DB_URL_VAR=SELFTEST_DB SELFTEST_DB=mysql://u:p@10.0.3.17:3306/app
db "migration check refuses an unknown database" real_check_migration.sh DB_URL_VAR=SELFTEST_DB_UNSET
printf 'SELFTEST_DB_URL="mysql://u:p@db-staging.internal/app"\n' > backend/.env
db "migration check reads the URL from backend/.env" real_check_migration.sh DB_URL_VAR=SELFTEST_DB_URL
db "backend check refuses a remote database" real_check_backend.sh DB_URL_VAR=SELFTEST_DB_URL

PF="$SRC/../../mr-feedback/scripts/pipeline_failures.sh"; MC="$SRC/../../mr-feedback/scripts/mr_comments.sh"
mkdir -p "$T/bin"
cat > "$T/bin/glab" <<'EOF'
#!/usr/bin/env bash
[ "${GLAB_FAIL:-}" = 1 ] && { echo "401 Unauthorized" >&2; exit 1; }
case "$2" in
  *merge_requests/12) printf '{"has_conflicts": %s, "target_branch": "main"}\n' "${GLAB_CONFLICTS:-false}" ;;
  *merge_requests/*/pipelines*) printf '[{"id": 5, "status": "success"}, {"id": 7, "status": "%s"}]\n' "$GLAB_STATUS" ;;
  *merge_requests/*/discussions*) printf '%s\n' "$GLAB_DISCUSSIONS" ;;
  *jobs\?scope=failed*) printf '%s\n' "${GLAB_JOBS:-[]}" ;;
  */trace) echo "E   AssertionError: boom" ;;
esac
EOF
chmod +x "$T/bin/glab"
pf() {  # $1 = case, $2 = script, $3 = expected exit code, then text the output must contain (NOT:text = must not)
  local name="$1" script="$2" want="$3" out rc s ok=1; shift 3
  out="$(PATH="$T/bin:$PATH" bash "$script" 12 2>&1)"; rc=$?
  [ "$rc" -eq "$want" ] || ok=0
  for s in "$@"; do
    case "$s" in
      NOT:*) printf '%s\n' "$out" | grep -qF -- "${s#NOT:}" && ok=0 ;;
      *) printf '%s\n' "$out" | grep -qF -- "$s" || ok=0 ;;
    esac
  done
  verdict "$name" "$ok" "$out"
}
export GLAB_STATUS=failed GLAB_JOBS='[{"id": 70, "stage": "test", "name": "pytest"}]'
pf "pipeline script shows the newest pipeline's failed jobs" "$PF" 0 "pipeline 7: failed" "AssertionError: boom" "NOT:MERGE CONFLICTS"
export GLAB_STATUS=success GLAB_JOBS='[]'
pf "pipeline script reports a green pipeline" "$PF" 0 "No failed jobs."
export GLAB_CONFLICTS=true
pf "pipeline script reports merge conflicts" "$PF" 0 "MERGE CONFLICTS with main"
unset GLAB_CONFLICTS

D1='[{"notes": [{"system": true, "body": "added 1 commit", "created_at": "2026-10-01T09:00:00Z", "author": {"username": "dev"}}]},
 {"notes": [{"system": false, "body": "Rename this.", "created_at": "2026-10-01T10:00:00Z", "resolvable": true, "resolved": false, "author": {"username": "alice"}, "position": {"new_path": "backend/app/x.py", "new_line": 42}}]},
 {"notes": [{"system": false, "body": "Old nit.", "created_at": "2026-10-01T10:05:00Z", "resolvable": true, "resolved": true, "author": {"username": "alice"}}]},
 {"notes": [{"system": false, "body": "Also update the README.", "created_at": "2026-10-01T11:00:00Z", "resolvable": false, "author": {"username": "bob"}}]}]'
D2='[{"notes": [{"system": false, "body": "Agent update: renamed it, README updated.", "created_at": "2026-10-01T12:00:00Z", "resolvable": false, "author": {"username": "dev"}}]},
 {"notes": [{"system": false, "body": "Please add a test too.", "created_at": "2026-10-01T13:00:00Z", "resolvable": true, "resolved": false, "author": {"username": "alice"}}]}]'
export GLAB_DISCUSSIONS="$D1"
pf "comments script shows open threads and comments" "$MC" 0 "comment 1 backend/app/x.py:42" "@alice: Rename this." \
  "@bob: Also update the README." "To handle: 2." "NOT:Old nit." "NOT:added 1 commit"
export GLAB_DISCUSSIONS="$D1$D2"  # two pages, as glab --paginate prints them
pf "comments script skips what the last Agent update answered" "$MC" 0 "@alice: Please add a test too." "To handle: 1." \
  "resolve: 1." "NOT:Rename this." "NOT:Also update the README."
export GLAB_FAIL=1
pf "pipeline script fails loudly when glab fails" "$PF" 1 "glab api failed" "401 Unauthorized"
pf "comments script fails loudly when glab fails" "$MC" 1 "glab api failed" "401 Unauthorized"
unset GLAB_FAIL GLAB_STATUS GLAB_JOBS GLAB_DISCUSSIONS

echo
if [ "$failures" -eq 0 ]; then echo "ALL OK"; exit 0; fi
echo "FAILED: $failures case(s)"; exit 1
