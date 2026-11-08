---
name: write-tests
description: Phase 4, the first step of every plan task. Writes that task's tests from the PLAN.md test plan (pytest, Vitest, Playwright or Cypress) before its code, and shows them failing (red). Use at the start of each task, including a bug's regression test.
---
# Write tests first (phase 4, red step)

Write exactly the Test plan rows for the current task, before its code. Nothing unrelated.
A migration-only task skips this skill: `check_migration.sh` is its test.

## Steps
1. Read PLAN.md: the current task (what its tests call) and its Test plan rows. Read "Codebase notes"
   (test frameworks, E2E location).
2. Look at one existing test of each type from the pattern source and copy its setup.
   Find fixtures first: `rg -n "^def |^async def " backend/tests/conftest.py`
3. Backend:
   - Service tests → `backend/tests/unit/<feature>/`
   - Route tests → `backend/tests/integration/<feature>/`
   - Per endpoint at minimum: happy path, 422, 404, 401/403, 409 (if unique rule), pagination (if list).
4. Frontend component tests: put them where the pattern source keeps them.
   Cover: data rendered, loading, empty, error, validation message, successful submit.
5. E2E: use ONLY the framework recorded for this screen in "Codebase notes". One spec per user-facing AC
   (happy path + the most important failure), written with the task that adds the page.
6. Assert the row's exact expected result: status code, fields, message or visible text. Derive numbers from
   the inputs in the test (`price * qty`), not mental math. Never assert only "not None" or "truthy".
7. Run only these tests:
   - `cd backend && pytest <test paths> -q`
   - `cd frontend && npx vitest run <test paths>`
   - E2E needs the LOCAL stack (`docker compose up -d` with the dev compose file only), then
     `npx playwright test <spec>` or `npx cypress run --spec <spec>`
8. Each must FAIL (red) on its assertion, or because the route or screen doesn't exist yet (404, element not
   found). Not on a typo, an import or a fixture error. A missing module or function → add a stub with the
   planned signature (`raise NotImplementedError` / `throw new Error("not implemented")`) and run again.
   `check_guards.sh` fails if a stub is still there at the end.
9. A test that PASSES now tests nothing new: fix the test, or ask to fix the plan. Never keep it as it is.
10. Log each `<test>: red: <the failing line>` in PROGRESS.md and fill the Test plan "File" column.
    Then write the task's code (/db-migration, /backend-implement or /frontend-implement) until they pass.
11. Tests written red are locked. Change one later only if it contradicts REQUIREMENTS.md, and write why in
    PROGRESS.md and the MR.

## Bug tickets: the regression test (plan task T1)
1. Write one test per symptom (usually just one) from REQUIREMENTS.md "Bug": follow the steps to reproduce, assert
   the Expected result. Put it where the pattern source keeps tests of that kind.
2. Run only those tests. Each must FAIL, showing the Actual result. Paste the failing output in PROGRESS.md.
3. One passes? Then it doesn't reproduce the bug. STOP and tell the human what you tried.

## Done when
- [ ] Every Test plan row of this task has a file and a logged red line
- [ ] The failing output is shown in this chat
- [ ] Test files ≤ 200 lines
