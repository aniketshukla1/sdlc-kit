#!/usr/bin/env bash
# Scans ADDED lines in changed files for debug code, ignore comments, skipped tests, secrets and unfinished
# work (a stub left from test-first, a swallowed error).
# Fails if protected paths or migrations already on main changed, or tests were removed.
# Human-approved exceptions: .agent/guard-exceptions.txt
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
MB="${MB:-$(git merge-base "${BASE_REF:-origin/main}" HEAD 2>/dev/null)}" || { echo "Base ref not found. Set BASE_REF."; exit 1; }
CHANGED="${CHANGED:-$({ git diff --name-only "$MB"; git ls-files --others --exclude-standard; } | sort -u)}"
EXC=".agent/guard-exceptions.txt"

PY_BAD='print\(|breakpoint\(\)|import pdb|#[[:space:]]*type:[[:space:]]*ignore|#[[:space:]]*noqa|except[[:space:]]*:|pytest\.mark\.skip|text\(f["'"'"']|execute\(f["'"'"']'
TS_BAD='console\.log|debugger;|@ts-ignore|@ts-nocheck|eslint-disable|:[[:space:]]*any\b|as any\b|<any>|\.only\(|\.skip\(|waitForTimeout\(|cy\.wait\([0-9]'
# Ways to make a failing test pass or not run. Checked in test files only.
SKIP_BAD='pytest\.skip\(|pytest\.(mark\.)?xfail|\.skipTest\(|unittest\.skip|expectedFailure|\bx(it|describe|test)\(|\.(fixme|todo|fails)\('
TEST_DEF='^[[:space:]]*((async[[:space:]]+)?def[[:space:]]+test|(it|test)\()'
# Unfinished work in source files. An abstract method uses @abstractmethod with `...`, not NotImplementedError.
STUB='raise[[:space:]]+NotImplementedError|new[[:space:]]+Error\(["'"'"'`][Nn]ot implemented|except[^:]*:[[:space:]]*pass\b|catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}'
SECRET='AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY|glpat-[0-9A-Za-z_-]{20,}|(password|passwd|secret|api_key|apikey|token)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']'
PROTECTED='(^|/)\.env($|\.)|docker-compose\.(staging|stage|prod|production)|(^|/)\.gitlab-ci\.yml$|(^|/)\.github/workflows/|(^|/)\.(cursor|claude|agents)/|(^|/)AGENTS\.md$|(^|/)search/.*(mapping|index_settings|alias)|mappings?[^/]*\.json$|(^|/)\.p4'
# Lint/type/test config: weakening any of these can turn a failing check green.
CONFIG='(^|/)(pyproject\.toml|setup\.cfg|pytest\.ini|tox\.ini|\.?ruff\.toml|\.?mypy\.ini|\.eslintignore|alembic\.ini)$|(^|/)tsconfig[^/]*\.json$|eslint\.config|\.eslintrc|(^|/)(vite|vitest|playwright|cypress)\.config\.|(^|/)alembic/env\.py$'
DEPS='(^|/)(package\.json|requirements[^/]*\.txt)$'

fail=0; t_add=0; t_rm=0; t_files=""
is_test() { case "$1" in */tests/*|tests/*|*/__tests__/*|*.test.*|*.spec.*|*/e2e/*|*/cypress/*) return 0 ;; esac; return 1; }
numbered_added() {  # added lines of file $1 as "<line number><TAB><text>" (whole file if untracked)
  if git ls-files --error-unmatch "$1" >/dev/null 2>&1; then
    git diff -U0 "$MB" -- "$1" | awk '/^@@/ { split($3, a, ","); n = substr(a[1], 2) + 0; h = 1; next }
      h && /^\+/ { print n "\t" substr($0, 2); n++ }'
  else
    awk '{ print NR "\t" $0 }' "$1"
  fi
}
added_lines() { numbered_added "$1" | cut -f2-; }
removed_lines() { git diff -U0 "$MB" -- "$1" | awk '/^@@/ { h = 1; next } h && /^-/ { print substr($0, 2) }'; }
flag() {  # $1=file $2=label $3=hits, as "<line number><TAB><text>" lines
  [ -n "$3" ] || return 0
  echo "[$2] $1"; echo "$3" | awk -F '\t' '{ print "    line " $1 ": " substr($0, length($1) + 2) }'; fail=1
}
report() {  # $1=file $2=label $3=regex $4=grep flags
  flag "$1" "$2" "$(numbered_added "$1" | grep -E $4 -- "$3" | head -5)"
}
swallowed() {  # "except X:" then "pass", or "catch (e) {" then "}", on two consecutive added lines of file $1
  numbered_added "$1" | awk -F '\t' '
    open && $1 == n + 1 && $2 ~ /^[[:space:]]*(pass|\})[[:space:]]*$/ { print n "\t" text " / " $2 }
    { open = ($2 ~ /^[[:space:]]*(except[^:]*:|\}?[[:space:]]*catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{)[[:space:]]*$/); n = $1; text = $2 }'
}

while IFS= read -r f; do
  [ -z "$f" ] && continue
  if [ -f "$EXC" ] && grep -qxF "$f" "$EXC"; then echo "[human exception] $f"; continue; fi
  case "$f" in .env.example|*/.env.example) continue ;; esac
  case "$f" in .agent/coverage.txt)  # raising the bar is fine; lowering it is a human's call
    old="$(git show "$MB:$f" 2>/dev/null | sed -n '/^[^#]/{p;q;}')"; new="$(sed -n '/^[^#]/{p;q;}' "$f" 2>/dev/null)"
    if [ -n "$old" ] && [ "${new:-0}" -lt "$old" ] 2>/dev/null; then
      echo "[weakened bar, needs human approval] $f: coverage minimum lowered from $old to ${new:-nothing}"; fail=1
    else
      echo "[note] $f changed. Only humans edit it; reviewers check it in the MR diff."
    fi
    continue ;;
  esac
  case "$f" in .agent/guard-exceptions.txt|.agent/size-allowlist.txt)
    echo "[note] $f changed. Only humans edit it; reviewers check it in the MR diff."; continue ;;
  esac
  if echo "$f" | grep -qE "$PROTECTED|$CONFIG"; then
    echo "[protected path, needs human approval] $f → stop and ask a human to add it to $EXC"; fail=1; continue
  fi
  case "$f" in backend/alembic/versions/*)
    if git cat-file -e "$MB:$f" 2>/dev/null; then
      echo "[migration already on main] $f → never edit or delete it; create a new migration"; fail=1; continue
    fi ;;
  esac
  if echo "$f" | grep -qE "$DEPS"; then
    echo "[warning] dependency file changed: $f (allowed only if listed in approved PLAN.md)"
  fi
  if is_test "$f"; then  # count test definitions removed vs added; a deleted file counts as all removed
    r=$(removed_lines "$f" | grep -cE "$TEST_DEF")
    [ "$r" -gt 0 ] && { t_rm=$((t_rm + r)); t_files="$t_files    $f: $r removed"$'\n'; }
    [ -f "$f" ] && t_add=$((t_add + $(added_lines "$f" | grep -cE "$TEST_DEF")))
  fi
  [ -f "$f" ] || continue
  case "$f" in
    *.py) report "$f" "debug/ignore" "$PY_BAD" "" ;;
    *.ts|*.tsx|*.js|*.jsx) report "$f" "debug/ignore/any" "$TS_BAD" "" ;;
  esac
  if is_test "$f"; then
    report "$f" "skipped test" "$SKIP_BAD" ""
  elif [[ "$f" != *.md ]]; then
    report "$f" "possible secret" "$SECRET" "-i"
    case "$f" in *.py|*.ts|*.tsx|*.js|*.jsx)
      report "$f" "unfinished: finish the stub or handle the error" "$STUB" ""
      flag "$f" "unfinished: swallowed error" "$(swallowed "$f" | head -5)" ;;
    esac
  fi
done <<< "$CHANGED"

if [ "$t_rm" -gt "$t_add" ]; then
  echo "[tests removed] $t_rm test definitions removed, $t_add added. Deleting tests is not allowed:"
  printf '%s' "$t_files"; fail=1
fi
[ $fail -eq 0 ] && echo "No forbidden patterns, removed tests or protected paths."
exit $fail
