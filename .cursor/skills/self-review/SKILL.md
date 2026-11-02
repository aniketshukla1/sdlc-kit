---
name: self-review
description: Phase 6. Reviews the full branch diff against requirements, security, data and UI checklists, and fixes findings before the MR. Use after run-checks prints ALL PASS.
---
# Self-review (phase 6)

## Steps
1. `MB=$(git merge-base origin/main HEAD)`, then `git diff $MB --stat`.
   Review ONE file at a time: `git diff $MB -- <file>`.
2. For each file, go through the checklist below. Write each finding in PROGRESS.md under
   "Self-review" as `file:line: problem → fix`.
3. Fix all findings. Then run /run-checks again until `ALL PASS`.

## Checklist
Requirements and scope
- [ ] Every AC in REQUIREMENTS.md has code AND a test, and each test's red line is in PROGRESS.md
- [ ] Only files listed in PLAN.md changed; no unrelated formatting or refactors
Security
- [ ] Every new endpoint requires auth and checks ownership/role in the service
- [ ] `Create`/`Update` schemas accept no server-owned fields (`id`, owner id, `role`, `is_admin`, timestamps)
- [ ] All input validated by schema constraints; no SQL built from strings
- [ ] No secrets, tokens or personal data in code, logs or responses
- [ ] No user data rendered as HTML (`dangerouslySetInnerHTML`); external data validated before use
Data and performance
- [ ] No query inside a loop (N+1); new filter/sort columns have indexes
- [ ] No unbounded query or loop: lists are paginated
- [ ] A new cache states its key (including the user or tenant) and how it goes stale
- [ ] Multi-write operations are in one transaction
- [ ] Migration downgrade reverses upgrade; no ES mapping/index changes
Errors
- [ ] No swallowed exceptions; errors map to the correct status code
- [ ] The UI shows a helpful message for every error the API can return
Frontend
- [ ] Loading / empty / error / success states exist
- [ ] Labels and `aria-label`s present; no `any`; list keys are ids
Quality
- [ ] Files ≤ 200 lines, functions ≤ 40 lines, nesting ≤ 3
- [ ] Clear names; no duplicated logic (search for similar helpers)
- [ ] No branch bolted onto an unrelated flow; feature logic stays out of shared modules
- [ ] No code left unused by this change (list it and ask before deleting); no abstraction with one user
- [ ] No generic names (`data`, `result`, `temp`), boolean flag parameters or nested ternaries
- [ ] Code you deleted but didn't write: you found out why it existed first (`git log -L` or blame)
- [ ] No debug code, commented-out code, or TODO without a ticket key

## Done when
- [ ] Every checklist item checked for every file
- [ ] All findings fixed and listed in PROGRESS.md
- [ ] `ALL PASS` shown in this chat after the fixes
