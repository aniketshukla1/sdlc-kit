---
name: mr-feedback
description: Phase 8. Fixes failed pipeline jobs and addresses MR review comments (GitLab or GitHub), then pushes and posts a summary note. Use when an MR exists and the human says "Continue <KEY>" after review or a pipeline run.
---
# MR feedback (phase 8)

You never merge. After a human merges, the pipeline deploys to the Testing environment.
`mr.sh` below is `bash .cursor/skills/mr-feedback/scripts/mr.sh`: it talks to GitLab or GitHub, whichever hosts the repo.
Staging and Production are never your concern.

## Steps
1. Read PROGRESS.md (branch, MR IID). Then: `git switch <branch> && git pull --ff-only`.
2. Pipeline and conflicts: `bash .cursor/skills/mr-feedback/scripts/pipeline_failures.sh <IID>`
   It exits 1 when it can't read GitLab or GitHub: show that error to the human; never treat it as green.
   `MERGE CONFLICTS` → first `git fetch origin && git merge origin/main`. Conflict in a file you did not
   change, or you're unsure → `git merge --abort` and ask the human. Else resolve, `git add <files>`,
   `git commit --no-edit`. Never rebase here: the branch is pushed, so a rebase needs a force push.
   2 Alembic heads after the merge → /db-migration step 7.
   For each failed job, classify it and act:
   | Class                 | Signs                                            | Action |
   |-----------------------|--------------------------------------------------|--------|
   | test / lint / type    | assertion, ruff, mypy, eslint, tsc errors        | Reproduce with /run-checks, fix the code |
   | build                 | install/compile/docker build errors              | Fix only if caused by your change, else ask |
   | flaky / infra         | timeout, runner error, network, image pull       | `mr.sh retry <job-id>` ONCE. Fails again → tell the human |
3. Review comments: `bash .cursor/skills/mr-feedback/scripts/mr_comments.sh <IID>`
   It shows unresolved threads and comments posted since your last `Agent update` note (step 6).
   Make a table in PROGRESS.md: `comment | action (fix / answer / needs new ticket)`.
   - Fix requested changes that are inside the plan scope.
   - Out-of-scope requests: don't do them; answer that it needs a new ticket.
   - Disagree? Don't argue in code. Write your reason in the reply and let the reviewer decide.
4. After fixes: /run-checks → `ALL PASS`.
5. Commit: `git commit -m "<KEY>: fix(<scope>): address review feedback"` (explicit `git add <files>`).
   Push: `git push` (never force).
   Refresh the proof for the new head: run `proof_pack.sh` again (/gitlab-mr step 7), replace the Proof section
   of `.agent/work/<KEY>/MR.md` with it, then `mr.sh set-body <IID> .agent/work/<KEY>/MR.md`.
6. Post ONE summary note on the MR. Start it with `Agent update`: next round, step 3 skips what it answers.
   Write `Agent update: <one line per comment: what you changed or your answer>` to `.agent/work/<KEY>/note.md`,
   then `mr.sh note <IID> .agent/work/<KEY>/note.md`.
   Do not resolve threads. The reviewer resolves them.
7. Update PROGRESS.md: `Phase: 8-feedback (round <n> done)` + log.
8. Tell the human what changed and that the MR is ready for another review.

## Done when
- [ ] Merge conflicts merged (never rebased) or reported; every failed job fixed, retried once (flaky), or reported
- [ ] Every review comment has an action in PROGRESS.md and a line in the MR note
- [ ] `ALL PASS` shown, changes pushed without force
- [ ] The MR description's Proof section is refreshed for the pushed head
