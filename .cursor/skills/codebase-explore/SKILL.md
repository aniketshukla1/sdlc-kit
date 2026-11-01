---
name: codebase-explore
description: Phase 2. Finds the files, patterns and test setup relevant to a ticket without editing anything. Use after ticket intake and before planning.
---
# Codebase explore (phase 2)

Read only. Do NOT edit code in this phase.

## Steps
1. Read `.agent/work/<KEY>/REQUIREMENTS.md` and `PROGRESS.md`.
2. Map the layout (names only, no file contents yet):
   `ls backend/app backend/app/* frontend/src frontend/src/features 2>/dev/null`
3. For each key noun/verb in the requirements (e.g. "invoice", "cancel"):
   `rg -n -i "<term>" backend/app frontend/src --max-count 3` (no `rg`? use `git grep -n -i "<term>"`)
4. Pick the PATTERN SOURCE: the existing feature most similar to this ticket (e.g. another
   list + detail + form). Read its route, schema, service, repository, model, api hook,
   main component and one test of each kind. These are the files you will copy patterns from.
5. Check the test setup:
   `ls backend/tests frontend/playwright.config.* frontend/cypress.config.* 2>/dev/null`
   For the screen this ticket touches, find its existing e2e spec: `rg -l -i "<screen name>" frontend/e2e frontend/cypress`
6. Check if Elasticsearch is used: `ls backend/app/search 2>/dev/null`.
7. Find existing error classes and auth dependencies:
   `rg -n "class \w+Error" backend/app/core` and `rg -n "def get_current_user" backend/app`
8. Line count every file you expect to edit: `wc -l <files>`.
9. Write "Codebase notes" in PROGRESS.md (template below) and set `Phase: 2-explore (done)`.

## Limits
- Read at most ~15 files. Use line ranges for long files.
- Write down facts you saw. If something is unclear, write "UNKNOWN: ..." and ask in the plan.

## Codebase notes template
```markdown
## Codebase notes
Pattern source: <feature name>
| File | Purpose | Lines |
|------|---------|-------|
| backend/app/api/v1/routes/orders.py | orders endpoints (pattern) | 142 |

- Error classes: NotFoundError, ConflictError (app/core/errors.py)
- Auth dependency: get_current_user (app/api/deps.py)
- Tests: pytest unit+integration; Vitest; E2E for this screen: Playwright (frontend/e2e/orders.spec.ts)
- Elasticsearch: yes/no
- Files near 200 lines (need split): ...
- UNKNOWN: ...
```

## Done when
- [ ] Pattern source chosen and its files listed
- [ ] Test frameworks and the E2E location for this screen recorded
- [ ] Files near the 200-line limit listed
