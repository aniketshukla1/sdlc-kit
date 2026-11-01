---
name: gitlab-mr
description: Phase 7. Commits, rebases, pushes the branch and opens a GitLab merge request with glab, then links it in Jira. Use after self-review is done and run-checks prints ALL PASS.
---
# GitLab MR (phase 7)

## Steps
1. Run /run-checks now. Continue only on `ALL PASS`.
2. Check what will be committed: `git status --short`.
   Must NOT appear: `.agent/work/`, `.env` files, build output, files not in PLAN.md.
3. Stage files explicitly: `git add <file> <file> ...` (never `git add -A` or `git add .`).
4. Commit, one commit per logical part (e.g. migration, backend, frontend, tests):
   `git commit -m "<KEY>: <type>(<scope>): <imperative summary, ≤ 72 chars>"`
   `<type>` = feat | fix | refactor | test | chore. Example: `PROJ-123: feat(orders): add cancel endpoint`
5. Update with main: `git fetch origin && git rebase origin/main`.
   Conflict in a file you did not change, or you're unsure → `git rebase --abort` and ask the human.
   After a rebase, run /run-checks again (2 Alembic heads → /db-migration step 7).
6. Push: `git push -u origin HEAD`. Never `--force`. If a push is rejected, ask the human.
7. Fill `mr-template.md` (next to this file) into `.agent/work/<KEY>/MR.md`. Every section, or `None`.
8. Create the MR:
   ```
   glab mr create --source-branch "$(git branch --show-current)" --target-branch main \
     --title "<KEY>: <summary>" --description "$(cat .agent/work/<KEY>/MR.md)" \
     --remove-source-branch --yes
   ```
   Add `--draft` if "Human actions required" is not `None`.
   Verify: the command prints an MR URL ending in `/merge_requests/<IID>`. The IID is that number.
9. Save MR URL and IID in PROGRESS.md. Set `Phase: 7-mr (open)`.
   PROGRESS.md has `Parent: <KEY>`? Also set this sub-task's row in that parent's Roadmap (its PLAN.md) to `MR !<IID>`.
10. Post a Jira comment (MCP) on the ticket, and on its parent if it has one: `Agent: MR ready for review: <url>`.
11. Tell the human: `MR created: <url>. After review or a pipeline result, start a new chat and type: Continue <KEY>`.

## Done when
- [ ] Only planned files committed, commit messages follow the format
- [ ] Branch pushed without force, MR created against `main`
- [ ] MR URL in PROGRESS.md and Jira
