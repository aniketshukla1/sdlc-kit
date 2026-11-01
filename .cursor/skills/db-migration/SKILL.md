---
name: db-migration
description: Phase 4 (data tasks). Changes SQLAlchemy models and creates a verified Alembic migration for MySQL. Use only when PLAN.md "Data changes" says a migration is needed.
---
# DB migration (phase 4, data tasks)

Skip this skill if PLAN.md "Data changes → Migration" is `no`.

## Steps
1. Read PLAN.md "Data changes" and the next unticked data task. Do only that task.
2. Edit or create the model in `backend/app/models/` following the database standards
   (names, explicit lengths, `DECIMAL` for money, indexes on foreign keys).
3. Generate the migration from inside `backend/`:
   `alembic revision --autogenerate -m "<KEY> <short description>"`
4. Open the new file in `backend/alembic/versions/`. Autogenerate is often wrong. Check each item:
   - [ ] Only the intended changes. Delete unrelated detected diffs.
   - [ ] Types, lengths, `nullable` and defaults are exactly what the plan says.
   - [ ] NOT NULL column on an existing table has `server_default` (or the plan's 3-step approach).
   - [ ] Index / unique / FK names follow `ix_`, `uq_`, `fk_` naming.
   - [ ] `downgrade()` reverses `upgrade()` in reverse order.
   - [ ] A rename or drop follows expand/contract (database standards), never in place.
   - [ ] No ORM model imports inside the migration (use `op` and `sa` only).
5. Run the checker (it does upgrade → downgrade → upgrade on your LOCAL/test DB):
   `bash .cursor/skills/run-checks/scripts/check_migration.sh`
   Verify: output ends with `MIGRATION PASS`.
6. Never edit a migration that already exists on main (`check_guards.sh` fails if you do). Create a new one.
7. `alembic heads` shows 2 heads after you updated from main (main got a new migration): set
   `down_revision` in YOUR oldest new migration to the other head. Don't use `alembic merge`. Then step 5 again.
8. Data backfill on staging/production is NOT your job. If needed, it must be under
   "Human actions required" in PLAN.md. If it isn't, stop and tell the human.
9. Never touch Elasticsearch mappings or indices.
10. Tick the task in PLAN.md. Add to PROGRESS.md log: task, migration file name, `MIGRATION PASS`.

## Done when
- [ ] Every item in step 4 checked
- [ ] `MIGRATION PASS` shown in this chat
- [ ] `alembic heads` shows exactly one head
