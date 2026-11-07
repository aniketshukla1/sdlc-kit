<div align="center">

# sdlc-kit

### Ticket in. Reviewed MR out. Scripts decide when it's done.

A drop-in kit for Cursor, Claude Code and Codex that turns an AI coding agent into a teammate you can hand real tickets to.<br>
It plans before it codes, writes failing tests first, and can't say "done" until real check scripts agree.

[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e)](LICENSE)
![Agents](https://img.shields.io/badge/agents-Cursor%20%C2%B7%20Claude%20Code%20%C2%B7%20Codex-111827)
![Ticket in](https://img.shields.io/badge/ticket%20in-Jira%20%C2%B7%20Linear-0052CC)
![MR out](https://img.shields.io/badge/MR%20out-GitLab%20%C2%B7%20GitHub-FC6D26)
![Self-tests](https://img.shields.io/badge/self--tests-98%2F98%20passing-22c55e)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-60a5fa)](CONTRIBUTING.md)

**[Website](https://aniketshukla1.github.io/sdlc-kit/)** · [Quick start](#quick-start) · [How it works](#how-it-works) · [What's inside](#whats-inside) · [Guardrails](#guardrails) · [FAQ](#faq) · [Roadmap](#roadmap)

<img src="docs/demo.gif" width="880" alt="21-second tour: an AI agent claims a ticket is done; sdlc-kit's tests start red and turn green, its check script catches a debug print on line 42, and its hook blocks a force push. It never merges. You do.">

<sub>▶ <a href="docs/demo.mp4">Watch the 21-second tour with sound</a></sub>

</div>

---

## Why

AI coding agents are fast and confident, and they are often wrong about being done. They skip the plan, write tests
that agree with whatever they just built, silence a failing check, and report "All tests pass ✅". Cheaper models do
it more.

sdlc-kit doesn't ask the model to be careful. It makes being careful the only way through.

| | What the agent does | What makes it stick |
|---|---|---|
| **Plans before code** | Writes a plan: vertical-slice tasks, edge and abuse cases, the exact expected result of every test | You type `approve`. No code before that |
| **Tests first** | Every task starts with tests that fail (red), then writes the code that makes them pass (green) | A test that passes before its code exists is rejected |
| **Checked, not trusted** | One command runs lint, types, tests, migrations and 11 kinds of guards on the diff | `check_all.sh` prints `ALL PASS` or `FAIL`. The model doesn't get a vote |
| **Keeps its hands off** | Never force-pushes, merges, wipes your uncommitted work, or touches a remote server | A command hook denies those commands before they run (Cursor and Claude Code) |
| **Never merges** | Opens the MR, answers review threads, fixes the failed jobs | You review. You merge. Always |

## See it catch a cheat

Real output, captured from a throwaway repo. The agent left a debug `print()` in `orders.py`, then tried to force-push:

```console
$ bash .cursor/skills/run-checks/scripts/check_all.sh
…
=== guards ===
[debug/ignore] backend/app/orders.py
    line 42: print("debug")
--- guards: FAIL
…
FAIL: guards

$ git push --force
Blocked by the agent kit: force push.
```

The same guards catch deleted or skipped tests, weakened lint and test config, secrets, edits to migrations that are
already on `main`, stubs left over from test-first, and swallowed errors.

## How it works

The ticket's type picks the track, so small tickets stay small. Linear has no issue types, so there a `Bug` label or
a sub-issue takes the quick track:

```mermaid
flowchart TD
    T([Ticket]) --> K{Issue type}
    K -->|"Bug, Sub-task"| Q["Quick track · 1 chat<br/>failing test → root cause"]
    K -->|"Story, Feature, Enhancement, Task"| F["Full track<br/>intake → explore → plan"]
    Q --> A1{{You approve the fix}}
    F --> A2{{You approve the plan}}
    A1 --> R["Code until the test is green"]
    A2 --> B["Per task: tests red → code green"]
    R --> C["check_all.sh"]
    B --> C
    C -->|ALL PASS| M["Self-review → MR"]
    M --> Y{{You review and merge}}
```

| Track | Ticket types | Chats to the MR | What happens |
|---|---|---|---|
| **Quick** | Bug, Sub-task | 1 | A failing test reproduces the bug, the agent finds the root cause (and checks every caller), you approve a ten-line plan, it fixes, checks and opens the MR |
| **Full** | Story, New Feature, Improvement, Enhancement, Task | 7 | Intake → explore → plan → **you approve** → red → green per task → checks → self-review → MR |
| **Roadmap** | Any ticket with sub-tasks | 3, then 1 per small sub-task | One roadmap for every sub-task, approved once; then each sub-task gets its own branch and MR, in dependency order |

A quick ticket that turns out big (a migration, an API change, a new screen, more than 5 files) moves itself to the
full track. Every chat starts by reading `PROGRESS.md`, so `Continue PROJ-123` picks up exactly where the last one
stopped.

<details>
<summary><b>The 8 phases of the full track</b></summary>

| # | Phase | Skill | Done when |
|---|---|---|---|
| 1 | Intake | `/ticket-intake` | Requirements written as Given / When / Then, no open BLOCKER |
| 2 | Explore | `/codebase-explore` | Pattern source, test setup and files near the size limit noted |
| 3 | Plan | `/implementation-plan` | You typed `approve` |
| 4 | Build | `/write-tests` (red), then `/db-migration`, `/backend-implement` or `/frontend-implement` (green) | Every task ticked, its tests green |
| 5 | Check | `/run-checks` | `ALL PASS` |
| 6 | Self-review | `/self-review` | Findings fixed, `ALL PASS` again |
| 7 | MR | `/gitlab-mr` | MR open, linked on the ticket |
| 8 | Feedback | `/mr-feedback` | Pipeline green, every review thread handled |

</details>

## Quick start

You need Cursor, Claude Code or Codex, GitLab with [`glab`](https://gitlab.com/gitlab-org/cli) or GitHub with
[`gh`](https://cli.github.com), a Jira or Linear MCP server, `git`, `python3` and
`ripgrep`. The standards target FastAPI + SQLAlchemy + MySQL + React/TypeScript; other stacks mostly mean editing
paths ([see below](#adapt-it-to-your-stack)).

1. **Install it** into your repo. It never overwrites a file that's already there, and it ends with a checklist:
   ```bash
   git clone https://github.com/aniketshukla1/sdlc-kit.git
   bash sdlc-kit/install.sh path/to/your-repo --key PROJ
   ```
   It sets up Cursor's files, and Claude Code's or Codex's too when your repo already uses them (or pass
   `--agent claude`, `--agent codex`). On Linear, add `--tracker linear` and use your team key. The MR host comes from
   your `origin` remote (`--host github` overrides it). An existing `hooks.json`, `.claude/settings.json` or
   `AGENTS.md` gets the kit's part merged in. The checklist covers your tools, your `glab` or `gh` login, the command
   hook and the self-tests. Run it again any time: `bash .cursor/skills/run-checks/scripts/doctor.sh`.
   On Windows, turn on symlinks (`git config core.symlinks true`) before you clone.
2. **Connect your tools:** run `glab auth login` (GitHub: `gh auth login`) and add your tracker's MCP server to your
   agent (Linear's is `https://mcp.linear.app/mcp`).
3. **Trust the workspace** when your agent asks (project hooks only run in trusted workspaces). Then prove the hook
   works: ask the agent to run `git push --force --dry-run`. It must be blocked. Codex has no hook in this kit yet, so
   your protected branches are its gate.
4. **Commit the kit** through a normal MR.
5. **Start a ticket** in your agent's chat:
   ```text
   Start ticket PROJ-123. Follow the ticket workflow rule.
   ```

<details>
<summary><b>Install by hand instead</b></summary>

```bash
cp -r sdlc-kit/.cursor sdlc-kit/.agent path/to/your-repo/        # every agent: rules, skills, scripts, state
cp -r sdlc-kit/.claude path/to/your-repo/                        # only if you use Claude Code
cp -r sdlc-kit/.agents sdlc-kit/AGENTS.md path/to/your-repo/     # only if you use Codex
chmod +x path/to/your-repo/.cursor/skills/*/scripts/*.sh
```

The `.claude/` and `.agents/` folders link to `.cursor/`, so there is one copy of every rule and skill. Copy only the
folders for the agents your team uses: Cursor also reads `.claude/skills` and `.agents/skills`. Already have an
`AGENTS.md`? Append ours to it. Then put your Jira project key (or Linear team key) in `.agent/jira-project.txt`;
on Linear, write `linear` in `.agent/tracker.txt`. If your `origin` remote doesn't say GitLab or GitHub, write
`gitlab` or `github` in `.agent/git-host.txt`.

</details>

## Daily use

| When | Type in the agent chat |
|---|---|
| Start a ticket | `Start ticket PROJ-123. Follow the ticket workflow rule.` (add `(quick)` or `(full)` to pick the track yourself) |
| No ticket? Ask in chat | `/chat fix: the export button crashes on an empty list` (or a feature). It drafts a local ticket; you type `start` |
| The plan is shown | `approve`, or `changes: <what to change>` |
| Every next chat | `Continue PROJ-123` |
| The MR got reviewed, or the pipeline finished | New chat: `Continue PROJ-123` |
| Next sub-task of a roadmap | `Continue PROJ-123` (the parent): it starts the next sub-task that's ready, or says which MR it's waiting for |
| Write a new ticket | `Create a bug: <what happened>` (or enhancement, task, sub-task). You type `create` |
| Review someone's MR | `Review MR !45` or `Review PROJ-123`. You type `post` |
| QA a ticket | `QA PROJ-123`. You type `post` |
| The MR got merged | Nothing. Your CI takes it from there |

Any skill also runs on its own: `/run-checks`, `/self-review`, `/mr-review`, and so on.

## What's inside

```text
.cursor/
├── rules/        6 rule files: the workflow (always on) + standards that load only for matching files
├── skills/       16 skills, one short checklist each, with their templates and check scripts
├── hooks.json    runs the command guard before risky shell commands
└── hooks/        block_commands.py: 14 rules, with its own self-test
.claude/          Claude Code: settings.json runs the same hook; rules/ and skills/ link to .cursor/
.agents/skills/   Codex: links to .cursor/skills/
AGENTS.md         Codex: points at the rules, the skills and the checks
.agent/           size allowlist, guard exceptions, tracker and project key; work/ holds per-ticket state (gitignored)
install.sh        one-command setup; ends with the doctor checklist (this repo only)
docs/             the audit and the skills review behind the design (this repo only)
```

| Skill | When | What it does |
|---|---|---|
| `/ticket-intake` | Full track, phase 1 | Turns the ticket and its sub-tasks into Given / When / Then requirements; batches questions as BLOCKERs |
| `/codebase-explore` | Phase 2 | Finds the pattern source to copy, the test setup and the files near the size limit. Read-only |
| `/implementation-plan` | Phase 3 | Vertical slices, edge and abuse cases, each test's exact expected result; stops for `approve` |
| `/write-tests` | Phase 4, red | Writes each task's tests before its code and shows them failing |
| `/db-migration` | Phase 4, data | SQLAlchemy model + Alembic migration with an up → down → up round trip |
| `/backend-implement` | Phase 4, green | FastAPI route → service → repository, with an edge-case checklist |
| `/frontend-implement` | Phase 4, green | React + TypeScript + shadcn/ui, with loading, empty, error and success states |
| `/run-checks` | Phase 5 | Runs `check_all.sh`: one `ALL PASS` or `FAIL` |
| `/self-review` | Phase 6 | Reviews the diff in a fresh chat: correctness, readability, architecture, security, performance |
| `/gitlab-mr` | Phase 7 | Explicit `git add`, typed commits, the MR from a template with a Proof section from `proof_pack.sh`, a comment on the ticket |
| `/mr-feedback` | Phase 8 | Fixes failed jobs, handles unresolved threads, merges `main` on conflicts (never rebases) |
| `/quick-fix` | Bug, Sub-task | The whole quick track in one chat |
| `/chat` | No ticket | Turns a request typed in chat into a local ticket (`CHAT-<n>`) with testable acceptance criteria, then runs the normal track |
| `/jira-create` | Anytime | Writes a detailed Jira or Linear ticket from one sentence, using your team's templates per issue type |
| `/mr-review` | Code review | Reviews any MR against its ticket; posts severity-labelled threads after you type `post` |
| `/ticket-qa` | QA | A pass/fail plan from the acceptance criteria, local runs with evidence, the result posted to the ticket |

## Guardrails

Everything below is a script or a hook, except the two gates that stay human: approving the plan, and merging.

| Guardrail | Enforced by |
|---|---|
| Files ≤ 200 lines, React components ≤ 150 | `check_size.sh` |
| No debug code, ignore comments, `any`, skipped or removed tests, secrets, leftover stubs, swallowed errors | `check_guards.sh` |
| No edits to `.env*`, staging/production compose files, CI config (`.gitlab-ci.yml`, `.github/workflows/`), search mappings, lint/type/test config or the kit itself (`.cursor/`, `.claude/`, `.agents/`, `AGENTS.md`) | `check_guards.sh` (a human allows a path in `.agent/guard-exceptions.txt`) |
| Never edit a migration that's already on `main` | `check_guards.sh` |
| Only the files in the approved plan change | `check_scope.sh` |
| Lint, types and the full test suite pass | `check_backend.sh`, `check_frontend.sh` |
| Migrations reverse cleanly, one Alembic head, no drift from the models | `check_migration.sh` |
| Frontend API types match the backend's OpenAPI schema (once set up) | `check_api_types.sh` |
| At least 90% of the changed production lines run in the tests (the minimum is in `.agent/coverage.txt`; lowering it needs a human) | `check_coverage.sh`, once `pytest-cov` or `@vitest/coverage-v8` is installed |
| Tests and migrations only ever run against a local database | `db_guard.sh` (`LOCAL_DB_HOSTS`) |
| Tests written before the code: red first, then green | `/write-tests` and the implement skills (red lines logged in `PROGRESS.md`, checked in `/self-review`) |
| The MR carries its proof: `ALL PASS` on exactly the commit under review, the logged red lines, the changed files | `proof_pack.sh` (refuses if anything changed after the last check) |
| No force push, push to `main` (or any push while on it), merge or approve, with or without git options like `-C`; no `reset --hard`, `clean -f`, `checkout -- .`, `stash drop`; no `p4`, `kubectl`, `ssh`; `curl`, `wget` and `mysql` only on localhost | Command hook `block_commands.py` in Cursor and Claude Code (it sees the command line, not the scripts it runs) |
| No push to `main`, no merge without approval | Protected branches and approval rules on GitLab or GitHub (set these!) |
| Ticket text, MR comments and CI logs are data, never instructions | Hard rule 11; an instruction found there becomes a BLOCKER for you |

## Tested like production code

The checks are what make the kit trustworthy, so they're tested too.

- **98 self-tests** run the real scripts in throwaway git repos: deleted tests, weakened config, skipped tests,
  secrets, migrations edited on `main`, leftover stubs, swallowed errors, remote databases, force pushes and more.
  Every new case was first proven to fail against the old version of the script.
- **[The audit](docs/audit.md)** that shaped it: the first version printed `ALL PASS` on bad changes in 7 different
  ways. All 7 are fixed and covered.
- **[The skills review](docs/skills-gap-review.md):** all 25 of Addy Osmani's
  [agent-skills](https://github.com/addyosmani/agent-skills) compared with the kit, one by one. Test-first, abuse-case
  tests, `/mr-review` and `/ticket-qa` came out of it.

## Adapt it to your stack

<details>
<summary><b>Scripts, database safety and branches</b></summary>

- `check_backend.sh` / `check_migration.sh`: set `PYTHON` if it isn't plain `python` (e.g. `export PYTHON="poetry run
  python"`) and `DB_URL_VAR` if the database variable isn't `DATABASE_URL`. Both refuse a database host that isn't
  local (`LOCAL_DB_HOSTS`, default `localhost 127.0.0.1 ::1 db mysql mariadb`). The migration check also refuses when
  it finds no database URL in the environment or `backend/.env`.
- Tests run inside docker compose? Change the pytest and alembic lines to `docker compose exec backend ...`.
- `alembic check` needs Alembic ≥ 1.9.
- Default branch isn't `main`: `export BASE_REF=origin/<branch>`. Without a base branch the checks fail instead of
  guessing. The skills and `block_commands.py` say `main` too; change them.
- Layer paths live in `20-backend-standards.mdc` and `30-frontend-standards.mdc`; edit them if your layout differs.

</details>

<details>
<summary><b>Let the linters enforce function size, parameters and nesting</b></summary>

```toml
# pyproject.toml
[tool.ruff.lint]
extend-select = ["PLR0913", "PLR0915", "PLR1702"]
preview = true                 # PLR1702 is a preview rule
explicit-preview-rules = true  # turn on only the preview rules listed here
[tool.ruff.lint.pylint]
max-args = 4
max-statements = 30            # ruff has no line-count rule; this is the closest to "≤ 40 lines"
max-nested-blocks = 3
```

ESLint: `"max-lines-per-function": ["error", 40], "max-params": ["error", 4], "max-depth": ["error", 3]`.
Files that already break these rules fail the next time they're touched.

</details>

<details>
<summary><b>Generated API types, so the frontend can't drift from the backend</b></summary>

Run `cd frontend && npm i -D openapi-typescript`, then `bash .cursor/skills/run-checks/scripts/check_api_types.sh
--write`, and add `src/api/schema.d.ts` to ESLint's ignores. Run it once more without `--write`: it must print
`matches`, which proves the output is the same every run. From then on, the checks fail when the file is stale.
Set `OPENAPI_APP` if the app isn't `app.main:app`, and `API_TYPES` for another path.

</details>

<details>
<summary><b>Optional: let the agent see the page</b></summary>

Add the Chrome DevTools MCP server to your agent (`npx -y chrome-devtools-mcp@latest --isolated`). The frontend and QA
skills then check pages on localhost: console errors, API status codes, the accessibility tree, screenshots at 375 and
1280 px. Keep `--isolated` (a throwaway browser profile); never use `--autoConnect` (your real browser).

</details>

## Run the guards in CI

<details>
<summary><b>A ready-to-paste GitLab CI job</b></summary>

The job runs the *target branch's* copy of the guards, so an MR that edits `check_guards.sh` can't pass its own check.
Add it once the kit is on `main`. A human MR that changes a protected file lists it in `.agent/guard-exceptions.txt`,
like the agent does.

```yaml
include:  # GitLab's scanners. Dependency Scanning needs GitLab Ultimate.
  - template: Jobs/Secret-Detection.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

agent-guards:  # image needs bash, git and python3
  stage: test
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  variables:
    GIT_DEPTH: "0"
    BASE_REF: origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME
  script:
    - git fetch origin "+refs/heads/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME:refs/remotes/$BASE_REF"
    - mkdir /tmp/main && git archive "$BASE_REF" .cursor/skills/run-checks/scripts | tar -x -C /tmp/main
    - bash /tmp/main/.cursor/skills/run-checks/scripts/check_size.sh
    - bash /tmp/main/.cursor/skills/run-checks/scripts/check_guards.sh
    - bash .cursor/skills/run-checks/scripts/selftest.sh  # this MR's copy: tests changes to the scripts
```

If your GitLab has review apps, `/ticket-qa`'s Testing rows can run there before merge.

</details>

<details>
<summary><b>A ready-to-paste GitHub Actions workflow</b></summary>

Same idea as the GitLab job: the guards come from the base branch's copy, so a pull request that edits
`check_guards.sh` can't pass its own check. Save it as `.github/workflows/agent-guards.yml` once the kit is on `main`.

```yaml
name: agent-guards
on: pull_request
permissions:
  contents: read
jobs:
  agent-guards:
    runs-on: ubuntu-latest  # has bash, git and python3
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0  # the base branch too, for the merge base
      - name: Guards from the base branch's copy
        env:
          BASE_REF: origin/${{ github.base_ref }}
        run: |
          mkdir /tmp/main && git archive "$BASE_REF" .cursor/skills/run-checks/scripts | tar -x -C /tmp/main
          bash /tmp/main/.cursor/skills/run-checks/scripts/check_size.sh
          bash /tmp/main/.cursor/skills/run-checks/scripts/check_guards.sh
      - name: Self-tests (this pull request's copy, so changes to the scripts get tested)
        run: bash .cursor/skills/run-checks/scripts/selftest.sh
```

GitHub's own scanners (secret scanning, code scanning, Dependabot) are switched on in the repo's security settings,
not in this file.

</details>

## FAQ

<details>
<summary><b>Will the agent ever merge, deploy or touch production?</b></summary>

No. The hook denies merge, approve and force push, and blocks `kubectl`, `ssh`, `p4`, and `curl`, `wget` or `mysql`
aimed at anything but localhost. Database checks refuse any host that isn't local. Protected branches on GitLab or
GitHub remain the final gate. Set them.

</details>

<details>
<summary><b>Why so many small files?</b></summary>

Long instructions make cheaper models skip steps. Each skill is one short checklist that loads only in its phase, and
each standards file loads only when a matching file is edited. Only the workflow and general rules are always on.

</details>

<details>
<summary><b>Does it burn a lot of tokens?</b></summary>

Less than one big prompt would. A bug is one chat. Every new chat re-reads the rules, the state files and the code, so
the kit keeps chats few where the work is small, and new rules go into files that load only when they're needed.

</details>

<details>
<summary><b>Does it work with Claude Code, Codex or Copilot?</b></summary>

Cursor, Claude Code and Codex are supported. Claude Code gets everything Cursor gets: the same rules (the standards
still load only for matching files), the 16 skills as slash commands, and the same command hook through
`.claude/settings.json`. Codex reads `AGENTS.md` and finds the skills in `.agents/skills/`. It has no command hook in
this kit yet, so your protected branches are its gate. Other agents can follow `AGENTS.md`: the rules and skills
are plain Markdown and the checks are plain shell.

</details>

<details>
<summary><b>Do I need Jira or Linear?</b></summary>

No. Type the request with `/chat` (`/chat add CSV export to the orders page`). It drafts a local ticket with testable
acceptance criteria and a `CHAT-<n>` key, you type `start`, and the same tracks, tests and checks run. The MR quotes
the request and lists the acceptance criteria, so reviewers still see what was asked.

</details>

<details>
<summary><b>GitHub instead of GitLab? Linear instead of Jira?</b></summary>

GitHub works: the kit reads the host from your `origin` remote (or `.agent/git-host.txt`), and
`.cursor/skills/mr-feedback/scripts/mr.sh` does every MR step through `glab` or `gh`: pull requests, checks and
review threads. The skill names stay the same, so `/gitlab-mr` opens a pull request on GitHub. Linear works too:
write `linear` in `.agent/tracker.txt` and add Linear's MCP server. Linear has no issue types, so a `Bug` label or a
sub-issue takes the quick track, sub-issues work like sub-tasks, and `/jira-create` uses labels instead of types.

</details>

<details>
<summary><b>My stack isn't FastAPI + React.</b></summary>

The workflow, the tracks, the hook and the guards are stack-agnostic. The standards files and `check_backend.sh` /
`check_frontend.sh` are where the stack lives: point them at your linters and test runners.

</details>

## Roadmap

Ideas on the table, not promises. Open an issue to vote or to pick one up.

- [ ] An example repo with a recorded ticket → MR run
- [x] GitHub support (`gh`, pull requests)
- [x] Packaging for Claude Code and Codex (`.claude/`, `.agents/`, `AGENTS.md`)
- [ ] A command guard for Codex (its experimental `.codex/rules`)
- [ ] More stacks: Django, Next.js, Spring
- [x] Linear as a ticket source
- [x] Changed-line coverage
- [ ] Mutation testing on changed lines (does each new test fail when the code it covers breaks?)
- [ ] Ready-made recipes for the Chrome DevTools checks

## Contributing

The kit lives by its own rule: scripts decide. So a change to a check script or the hook comes with a self-test case
that fails against the old version, and `selftest.sh` must end with `ALL OK`. Found a way to get `ALL PASS` on a bad
change, or to slip a command past the hook? That's the most valuable issue you can open. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgements

- Addy Osmani's [agent-skills](https://github.com/addyosmani/agent-skills) (MIT): the review behind test-first,
  abuse-case tests, the review checklist and the QA coverage list.
- The `qa-acceptance` skill from the Paperclip skill bundle: the shape of `/ticket-qa`'s pass/fail plan.

## License

[MIT](LICENSE). Use it, fork it, ship tickets with it.
