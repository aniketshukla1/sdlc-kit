---
name: implementation-plan
description: Phase 3. Writes PLAN.md with vertical-slice tasks, edge and abuse cases, and a test plan that gives each test its task and exact expected result, gets human approval, then creates the git branch. Use after codebase exploration and before writing any code.
---
# Implementation plan (phase 3)

## Steps
1. Read REQUIREMENTS.md and "Codebase notes" in PROGRESS.md.
2. Copy `plan-template.md` (next to this file) to `.agent/work/<KEY>/PLAN.md` and fill every section.
   Write `None` if a section does not apply. Never delete a section.
3. Tasks:
   - Slice vertically: one task = one acceptance criterion (or a small group) end to end, e.g. schema →
     repository → service → route for one endpoint. Riskiest slice first; shared groundwork (migration, model)
     before the slices that need it. ≤ 5 source files per task (tests not counted), one sitting. "And" in a
     task title means two tasks.
   - Each task names what its tests call: the route (method + path), the function with its signature, or the
     component with its props. Its tests are written before its code (/write-tests), so fix these here.
   - Sub-tasks in REQUIREMENTS.md: fill the Roadmap first. Every open sub-task gets a row and its plan tasks;
     a sub-task others depend on goes first. Number the tasks in Roadmap order, slice order inside each.
     Each task belongs to exactly one sub-task; shared groundwork goes in the one the others depend on.
     Every sub-task gets its own branch and MR later ("Roadmap tickets" below).
   - Bug ticket: T1's first test is the regression test (/write-tests "Bug tickets"). Moved from the quick
     track: it is already written; tick it.
   - A dependency upgrade: one package per task, its changelog read for breaking changes, tests green before
     and after. A performance task: the plan states the command, today's number and the target; no gain
     beyond run-to-run noise → revert.
   - If a file would go over 200 lines, add a "split <file>" task BEFORE the task that grows it.
   - Files table: one full repo-relative path per row, no `{a,b}` shorthand. `check_scope.sh` fails on any
     changed file that PLAN.md doesn't name.
4. Edge and abuse cases: for each AC go through the template's checklist and keep the ones that apply. Write the
   exact result of each (status code, message, UI text).
5. Test plan: every AC, edge case and abuse case → one row: test name, type, the task that makes it pass, and
   the exact expected result. Abuse cases first.
6. Anything a human must do (ES mapping, env var, data backfill, infra) goes in "Human actions required".
   The Risks "Ask first" items (a new feature flag included) are approved by the human with the plan.
   A new library or pattern, in a project that keeps ADRs: add a task for a short one, in its format.
7. Show the plan summary in chat and post PLAN.md as a comment on the ticket (MCP). Then write exactly:
   `Reply "approve" or "changes: <feedback>".`
   STOP. Write no code until the human replies `approve`.
8. On `changes: ...` → update PLAN.md and repeat step 7.
9. On `approve` (roadmap ticket: skip steps 9–10 and go to "Roadmap tickets" below):
   `git fetch origin && git switch -c <type>/<KEY>-<short-slug> origin/main`
   (`<type>` = `feature` | `bugfix` | `chore`; slug = 3–5 lowercase words with dashes)
   PROGRESS.md already names a branch (moved from the quick track)? `git switch <branch>` instead.
   Verify: `git branch --show-current` prints the new branch.
10. Update PROGRESS.md: `Phase: 3-plan (approved)`, `Branch: <name>`, log the approval time.

## Roadmap tickets: one MR per sub-task
After `approve`, <KEY> itself gets no branch or MR. Each open sub-task gets its own, in Roadmap order.
Each sub-task's MR leaves main working: user-visible parts of an unfinished ticket go behind the project's
existing feature flag, if it has one (decide this at planning).
Also run these steps on every "Continue <KEY>" while the Roadmap has rows that aren't `merged`.
1. For each `MR !<iid>` row: `bash .cursor/skills/mr-feedback/scripts/mr.sh view <iid>` says it's merged → set
   the row to `merged`.
2. Pick the next `todo` row whose "Depends on" rows are all `merged`. None ready → tell the human which MR
   it is waiting for, and stop. Every row `merged` → the ticket is done; tell the human.
3. Create `.agent/work/<SUBKEY>/PLAN.md` from the template below: copy that row's plan tasks, their files and
   the Test plan rows for its ACs from <KEY>'s PLAN.md. Nothing else is planned again.
4. `git fetch origin && git switch -c <type>/<SUBKEY>-<short-slug> origin/main`. Set the row to `branch <name>`.
5. Create `.agent/work/<SUBKEY>/PROGRESS.md` (template in /ticket-intake) with `Parent: <KEY>`,
   `Phase: 3-plan (approved)` and the branch. In <KEY>'s PROGRESS.md: `Phase: roadmap (<n> of <m> merged)`.
6. ≤ 3 plan tasks: run phases 4–7 for <SUBKEY> in this chat, one after another (red → green per task,
   /run-checks, /self-review, /gitlab-mr), with no new chat between them. More tasks: phase 4 starts here and
   later phases go on with `Continue <SUBKEY>`. Chat getting long either way: update PROGRESS.md, then
   "Start a new chat and type: Continue <SUBKEY>".

Sub-task PLAN.md template:
```markdown
# <SUBKEY> plan (sub-task of <KEY>, Roadmap row <n>)
Parent plan: .agent/work/<KEY>/PLAN.md (data, API, UI, edge cases).
Requirements: .agent/work/<KEY>/REQUIREMENTS.md, the rows named `<SUBKEY> AC…`.
- Migration: <yes/no>

## Tasks
- [ ] T<n>: <copied from the parent plan>

## Files
| Path | New/Edit | Lines now → expected | Purpose |
|------|----------|----------------------|---------|

## Test plan
| Covers (AC#/Edge#) | Test name | Type (unit/integration/component/e2e) | Task | Expected (exact) | File |
|--------------------|-----------|----------------------------------------|------|------------------|------|
```

## Done when
- [ ] Every template section filled (or `None`)
- [ ] Every AC, edge case and abuse case is in the Test plan, with its task and exact expected result
- [ ] Every open sub-task is in the Roadmap with its plan tasks (or Roadmap: None)
- [ ] Human replied `approve`
- [ ] Branch created from `origin/main` and recorded in PROGRESS.md (roadmap ticket: the first sub-task's)
