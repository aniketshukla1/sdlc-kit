---
name: run-checks
description: Runs every automated check (file size, forbidden patterns, plan scope, lint, types, unit tests, migrations) on the changed files and prints ALL PASS or FAIL. Use after writing tests, after self-review, and before any commit or push.
---
# Run checks

## Steps
1. From the repo root run:
   `bash .cursor/skills/run-checks/scripts/check_all.sh`
2. The last line is either `ALL PASS` or `FAIL: <check names>`.
3. On FAIL: scroll up to the first `--- <check>: FAIL` block. Fix ONLY that cause, then run again.
4. Same error 3 times → stop and ask the human (show the error and what you tried).
5. Not allowed, ever:
   - editing these scripts, lint/type/test config, or `.agent/*.txt` allowlists
   - `# noqa`, `# type: ignore`, `eslint-disable`, `@ts-ignore`, `pytest.mark.skip`, `xfail`, `xit(`, `.skip(`/`.only(`/`.todo(`/`.fixme(`
   - deleting or weakening a test
6. A failing test you did not write: check whether your diff touches the code it tests
   (`git diff $(git merge-base origin/main HEAD) --stat`). If it doesn't, STOP and report it to the
   human as possibly pre-existing. Don't "fix" unrelated tests.
7. When `ALL PASS`: paste the final summary lines into the PROGRESS.md log.

## Scripts (for reference; do not edit)
- `check_all.sh`: runs the checks below for files changed vs `$BASE_REF` (default `origin/main`); fails if that ref is missing. On a ticket branch it records the verdict and the exact content checked in `.agent/work/<KEY>/last-check.txt`
- `check_size.sh`: files ≤ 200 lines, React components ≤ 150
- `check_guards.sh`: debug code, ignore comments, skipped or removed tests, secrets, leftover stubs, swallowed errors, protected paths, edits to migrations already on main
- `check_scope.sh`: every changed file must be named in PLAN.md
- `check_backend.sh`: ruff, ruff format, mypy on changed files + full pytest (local DB only), with coverage when pytest-cov is installed
- `check_frontend.sh`: tsc, eslint on changed files + full vitest, with coverage when `@vitest/coverage-v8` or `-istanbul` is installed
- `check_coverage.sh`: at least the minimum in `.agent/coverage.txt` (default 90%) of the changed production lines ran in those tests; skipped without a coverage report
- `check_migration.sh`: alembic round trip of the changed migrations, single head, model drift (local DB only; also runs when models change)
- `db_guard.sh`: refuses a DB whose host isn't in `LOCAL_DB_HOSTS` (used by the two above)
- `check_api_types.sh`: the generated API types match the backend's OpenAPI schema (`--write` regenerates them); skipped until set up
- `proof_pack.sh`: the MR's Proof section (verdict, red lines, changed files); refuses unless the last `ALL PASS` ran on exactly HEAD's content. Used by /gitlab-mr and /mr-feedback
- `selftest.sh`: tests these scripts, the mr-feedback scripts and the command hook. For humans changing them; not part of run-checks
- `doctor.sh`: the setup checklist (tools, `glab`/`gh` login, the command hook, the self-tests). For humans; not part of run-checks
