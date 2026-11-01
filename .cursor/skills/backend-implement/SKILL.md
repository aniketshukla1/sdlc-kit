---
name: backend-implement
description: Phase 4 (backend tasks). Implements one PLAN.md task in Python/FastAPI following the layer pattern and edge-case checklist. Use for each unticked backend task after the plan is approved.
---
# Backend implement (phase 4, backend tasks)

Do ONE task at a time. Max 3 tasks per chat.

## Steps
1. Read PROGRESS.md and PLAN.md. Pick the next unticked backend task. Confirm the branch:
   `git branch --show-current` must match PROGRESS.md. The task's tests must already be red (PROGRESS.md has
   their red lines); if not, run /write-tests for it first.
2. Open the pattern source files from "Codebase notes". Copy their structure, imports,
   naming, dependency injection and error handling. Do not invent a new style.
3. `wc -l` each file you will edit. If the change would pass 200 lines, do the split first.
4. Write the smallest code that makes this task's tests pass, in layer order: schema → repository → service →
   route. Before using any function, class or setting, confirm it exists: `rg -n "def <name>|class <name>" backend/app`.
   A library API the codebase doesn't use yet: check the installed version (`pyproject.toml` or the lock file)
   and follow that version's docs; can't verify → say so in PROGRESS.md.
5. Edge-case checklist. Handle each one, or write `N/A: <reason>` in the PROGRESS.md log:
   - [ ] New route requires the auth dependency (public only if PLAN.md's API table says so)
   - [ ] `Create`/`Update` schemas have no server-owned fields (`id`, owner id, `role`, `is_admin`, timestamps)
   - [ ] Not found → project's not-found error (404)
   - [ ] Belongs to another user / wrong role → forbidden error (403), checked in the service
   - [ ] Duplicate → catch `IntegrityError` → conflict error (409)
   - [ ] Invalid input → `Field` constraints in the schema (422); max lengths = DB column lengths
   - [ ] Optional/nullable fields handled in service and response
   - [ ] Empty list returns `[]` (+ pagination info), never 404
   - [ ] Pagination: default 20, max 100, stable `order_by`
   - [ ] Multi-write operations in one transaction
   - [ ] No N+1: relations in the response are eager-loaded
   - [ ] UTC datetimes, `Decimal` money
   - [ ] No secrets or personal data in logs or responses
6. Register new routers the same way the pattern source does (find with `rg -n "include_router" backend/app`).
7. Verify on touched files (from `backend/`):
   `ruff check <files> && ruff format <files> && mypy --follow-imports=silent <files>`
   Fix all errors. No `# noqa` / `# type: ignore`.
   Then run this task's tests: all green (mark their Test plan rows ✅). Still red while the code looks right →
   re-check the expected value against REQUIREMENTS.md before changing more code.
8. Tick the task in PLAN.md. Append to PROGRESS.md log: task id, files changed, edge cases N/A with reasons.

## Done when
- [ ] Task ticked, every file ≤ 200 lines
- [ ] ruff and mypy output shown clean in this chat
- [ ] This task's tests shown red before the code and green after
- [ ] Every checklist item handled or marked N/A with a reason
