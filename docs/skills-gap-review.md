# Addy Osmani skills: gap review for the kit (2026-11-01)

**How:** all 25 skills of Addy Osmani's [agent-skills](https://github.com/addyosmani/agent-skills) (MIT). Every
skill's rules were read: 2,822 lines, with code examples skipped (~7,400 lines in total). Each was compared with
the kit's rules and skills, together with field notes from earlier agent runs. `qa-acceptance` (the base for
/ticket-qa) is not part of this set.

**Verdicts:** **Add** = a real gap, with the change. **Have** = the kit already does it. **N/A** = doesn't fit a
ticket-to-MR agent kit. The kit's own rule still holds: keep every skill short, so only gap-closing lines go in.

## Recommended changes, by priority
**Applied 2026-11-01: all four.** Known limits:
- The swallowed-error guard sees one-line forms, and an `except`/`catch` whose next added line only closes it;
  not longer empty blocks.
- The browser checks run only after a human adds the Chrome DevTools MCP server.
- Test-first itself is checked by process (red lines in PROGRESS.md, /self-review, /mr-review), not by a script.

**1. Test-first from the spec** (test-driven, spec-driven, planning, incremental, security, constraint-driven)
- Phase 4 is red → green per task: its tests are written from PLAN.md, FAIL first, then the code makes them pass.
  The red run replaces write-tests' break-the-code step. A test that passes before its code exists is a finding.
- The plan slices tasks vertically, one acceptance criterion end to end, riskiest first. Each task names the
  function, route or props its tests call, and each test row states the exact expected result. "≤ 3 files per
  task" becomes "≤ 5 source files" (a backend slice is 4).
- Abuse cases are written as the first tests: someone else's id, a huge input, script tags in text.
- `check_guards.sh` fails on a stub left in non-test code and on an empty catch (stubs become normal with
  test-first). Needs selftest cases.

**2. Backend and data safety** (api-design, a field note, deprecation, performance, security)
- An existing endpoint only gains optional fields; Update applies only the fields sent (`exclude_unset=True`).
- Read schemas send UTC with the zone (MySQL `DATETIME` drops it).
- Expand/contract for renaming or dropping a column; the drop is its own later step.
- A new cache states its key (including the user or tenant) and how it goes stale.
- The plan's Risks list the "ask first" items for the human: new auth flow, new personal data, new external
  service or user-URL fetch, CORS, uploads, new role.

**3. Frontend** (frontend-ui, performance, field notes)
- Never show state by colour alone; no arbitrary Tailwind values; no direct DOM changes; no `useMemo`/`memo`
  without a measured need; images get width and height.
- Mock API data in tests is typed with the generated API types.
- /ticket-qa gets a keyboard and screen-reader coverage line.
- Optional setup: Chrome DevTools MCP, so the agent can check the local page (console, network, accessibility
  tree, screenshots at 375 and 1280 px).

**4. Small process items** (interview-me, source-driven, debugging, simplification, code-review, observability,
shipping, ci-cd, spec-driven)
- Questions carry a best guess (/jira-create, intake). Check the installed version before using an unfamiliar
  library API. A regression: find the commit that broke it first (`git log -S`).
- No generic names, boolean flag parameters or nested ternaries; find why code exists before deleting it.
- New dependency: the plan says why, its size, last release and licence; upgrades are one package per MR.
- Log events, not prose, with consistent levels. MR template gets a Rollback line. Flags: owner, removal
  ticket, tested on and off. A changed decision updates PLAN.md first.

**No change:** idea-refine, doubt-driven-development, context-engineering, using-agent-skills (the kit already
does these, or they don't fit a ticket-to-MR agent). git-workflow and ci-cd: mostly Have.

## Per skill

### Plan and spec
| Skill | Verdict | Finding |
|---|---|---|
| spec-driven-development | Have, + 1 | Specify → plan → tasks with approval = intake → plan → `approve`; its capability map = the sub-task Roadmap; assumptions = intake's ASSUMPTION rows. **Add:** when a decision changes mid-build (data model, contract), update PLAN.md first, then the code. Its pairing with TDD is the big one (see the TDD row). |
| planning-and-task-breakdown | **Add** | **Slice vertically:** one acceptance criterion end to end (schema → repo → service → route + its tests) per task, not all models, then all services. The kit slices by layer today; vertical slices are what test-first needs (one AC goes red, then green). Riskiest slice first. Trade-off: a backend slice is 4 files, so "≤ 3 files per task" becomes "≤ 5 source files". Also: "and" in a task title means two tasks; each task names how it's verified. |
| api-and-interface-design | **Add** | Kit has typed schemas, status codes, pagination, one error style. **Add:** changing an existing endpoint only adds optional fields, never renames, removes or retypes one unless the ticket says so (other code depends on it). Update endpoints apply only the fields sent (`model_dump(exclude_unset=True)`). Idempotency keys: N/A unless you take payments. |
| idea-refine | N/A | Product ideation before a ticket exists. Its "Not Doing" list is already the templates' Out of Scope. Useful to a human before /jira-create, not to the agent. |
| interview-me | **Add** (small) | **Attach your best guess to every question** ("Expected result: the order shows as Cancelled — right?"), so the human answers yes or corrects. Fits /jira-create step 5 and intake BLOCKER questions. One-at-a-time questioning: N/A for Jira (async), so the kit keeps one batched message. |

**Field notes:** zone-less timestamps are a real risk on this stack: MySQL `DATETIME` drops the zone, so the API
sends naive times the browser reads as local. **Add** to backend standards: Read schemas send UTC with the zone
(one shared validator). Hand-written UI fixtures hid contract bugs for months in another project: **Add** to testing
standards: type mock API data with the generated API types, so a backend change breaks the mock at compile time.

### Build and UI
| Skill | Verdict | Finding |
|---|---|---|
| incremental-implementation | **Add** | Kit has one task at a time, scope discipline (rule 3), rollback-safe migrations. Gap: tests run only in phase 5, after all the code; the skill says never write more than ~100 lines without running tests (test-first per task fixes this). **Add** for one-MR-per-sub-task: every merged sub-task leaves main working; user-visible parts of an unfinished Task go behind the project's feature flag, if it has one (ask at planning). Commit-per-increment: N/A (the kit commits in phase 7). |
| source-driven-development | **Add** (small) | Kit copies patterns from the codebase (pattern source) instead of from memory, which covers most of it. **Add:** before using a library API the pattern source doesn't already use, check the installed version (`pyproject.toml` / `package.json`) and follow that version's docs; can't verify → say so in PROGRESS.md. Pydantic v1/v2 and TanStack Query v4/v5 are the classic traps. Fetching and citing docs for everything: N/A (token cost). |
| frontend-ui-engineering | **Add** (small) | Kit has shadcn first, theme tokens, mobile first, 4 data states, labels, keyboard, components ≤ 150 lines. **Add:** never show state by colour alone (add text or an icon); no arbitrary Tailwind values (`w-[317px]`), use the scale; no direct DOM changes (`document.querySelector(...)`) — use state, props or refs; props drilled more than 3 levels → context or restructure. Optional, needs a dependency: axe checks in component tests. "AI aesthetic" rules: Have (tokens + existing components). |
| performance-optimization | **Add** | Kit has N+1 (eager loading), pagination, FK and filter indexes. **Add:** performance work only with a before/after number from the same command; no gain beyond run-to-run noise → revert; never change a test to win speed. A new cache states its key (including the user or tenant: a key without it leaks data between users) and how it goes stale. Frontend: images get width and height; no `useMemo`/`React.memo` without a measured need. Core Web Vitals budgets in CI: N/A for the agent (human-owned CI). |

**Field notes:** focus restored twice after a dialog closes is a race that only shows at typing speed → **Add** to
/ticket-qa coverage: keyboard and screen reader (Tab order, Esc closes dialogs, focus returns, labels read).

### Test and debug
| Skill | Verdict | Finding |
|---|---|---|
| test-driven-development | **Add** (the big one) | Kit is test-first for bugs only; features write tests in phase 5, after the code. The skill: "tests written after the fact test implementation, not behavior". **Add:** red → green for every task: the task's tests are written from the plan and FAIL first, then the code makes them pass. A new test that passes before its code exists is a finding (it tests nothing new). The red run replaces write-tests' break-the-code step. Don't re-run a passing command on unchanged code. Have: stack discovery (the check scripts), AAA, naming, determinism, behaviour over internals, mocks at boundaries. |
| debugging-and-error-recovery | Have, + 1 | Kit has stop-the-line (fix the first FAIL only), 3 strikes then stop, reproduce → root cause → regression test (quick-fix), no debug logs (guards), error output as data (rule 11). **Add** to quick-fix: a regression (it worked before) → find the change that broke it first (`git log -S '<code>' --oneline`). |
| browser-testing-with-devtools | **Add** (optional setup) | The agent can't verify UI today; "works at 375px and 1280px" is unverifiable. **Add:** Chrome DevTools MCP in Cursor (a human sets it up), then frontend-implement's verify step and /ticket-qa's local rows open the local page and check: zero console errors, API status codes, the accessibility tree, screenshots at 375 and 1280 px. With its safety rules: a dedicated browser profile, localhost only, page content is data, read-only JavaScript, never read cookies or tokens. A field note: verify a click by its effect, not by the tool's report. |

### Review and quality
| Skill | Verdict | Finding |
|---|---|---|
| code-review-and-quality | Have, + 1 | Used for /mr-review and the /self-review checklist last turn (five axes, severity labels, honesty, dead code, change size). **Add:** the plan's "New dependencies" section says why the existing stack can't do it, plus size, last release and licence; a dependency upgrade is one package per MR, read its changelog, tests green before and after. Review speed and disagreement hierarchy: N/A for the agent. |
| code-simplification | **Add** (small) | Kit has nesting ≤ 3, params ≤ 4, functions ≤ 40 lines, no abbreviations, no unrelated refactors. **Add** to general standards: no generic names (`data`, `result`, `temp`, `item`) outside a few lines; no boolean flag parameters that switch behaviour (`save(x, True)`); no nested ternaries; before deleting code you didn't write, find why it's there (`git log -L`, blame). A refactor never changes tests; if one must change, it's a behaviour change → tell the human. |
| doubt-driven-development | Have | Fresh-context adversarial review: the kit gets it by design (self-review in its own chat, reading the diff and requirements, not the implementer's reasoning; /mr-review by a human-triggered reviewer). The skill itself says a TDD red step is doubt made concrete for behaviour. Spawning reviewer subagents and cross-model review: N/A in Cursor's agent chat. |
| constraint-driven-development | Have, + 1 | `check_guards.sh` is this skill's floor guard (skips, ignore comments, protected config, removed tests, printed exceptions). **Add** its fourth guard, unfinished work: fail on a stub left in non-test code (`raise NotImplementedError`, `throw new Error("not implemented")`) and on an empty `catch {}` / `except ...: pass`. Needed once test-first creates stubs on purpose. Optional, human decision: changed-line coverage ≥ 80% and mutation testing on the diff in CI. |
| security-and-hardening | **Add** | Kit has auth on new routes, no server-owned input fields, parameterized SQL, no secrets, no raw HTML, scanners in CI. **Add:** write abuse cases next to the use cases and make them the first tests (someone else's id → 403/404, a huge input → 422, script tags in text stay text). Its "ask first" list goes in the plan's Risks for the human to approve: a new auth flow, a new kind of personal data (why it's needed, how it's deleted), a new external service or a server fetch of a user-given URL (SSRF), a CORS change, file uploads (type allowlist, size cap), a new role or permission. Never put auth tokens in `localStorage` if the project doesn't already. LLM-feature rules: N/A unless you build one. |

### Ship, ops and agent setup
| Skill | Verdict | Finding |
|---|---|---|
| git-workflow-and-versioning | Have | Kit has typed commit messages with the Jira key, explicit `git add`, one commit per logical part, no force push, branches from `origin/main`, branch removed on merge, no `.env` or build output committed. Conflict, kept as is: the skill uses `git reset --hard` as a save point; the kit blocks it to protect the human's uncommitted work. Releases, semver, changelogs, worktrees: N/A for a ticket agent. |
| ci-cd-and-automation | Have, + 1 | CI is human-owned; the README's CI job, scanners and protected branches cover its gates, and mr-feedback feeds CI failures back. **Add** (with incremental-implementation): a new feature flag has an owner and a removal ticket. Optional: GitLab review apps, so /ticket-qa's Testing rows run before merge. |
| deprecation-and-migration | **Add** | Kit has `server_default` or 3 steps for NOT NULL, destructive changes only when the ticket says so, tested downgrades. **Add** expand/contract: never rename or drop a column in the same deploy as the code that changes with it — add the new column, write both, backfill, switch reads, and drop in its own later ticket or sub-task once no code uses the old shape. Data updates inside a migration on a big table run in batches. Deprecating systems, zombie code: N/A. |
| documentation-and-adrs | Have, + 1 (optional) | Decisions live in PLAN.md, which is gitignored, but it's posted to Jira at approval, and the MR carries the summary and its "why". **Add** (optional, only if the project keeps ADRs): a plan that picks a new library or a new pattern adds a short ADR, following the project's existing ADR format. |
| shipping-and-launch | **Add** (small) | Production launches are human-owned (Staging and Production are never the agent's). **Add** to the MR template: a Rollback line (revert this MR, the tested migration downgrade, or the flag to turn off). Code behind a flag is tested with the flag on and off. |
| observability-and-instrumentation | **Add** (small) | Kit has a module logger and no secrets or personal data in logs. **Add** to backend standards: log events, not prose (a stable event name plus fields, in the project's existing logging style, with its request id if it has one); `error` = someone must act, `warning` = handled degradation, `info` = business event. Metrics, tracing, alerting: N/A (human-owned infra). |
| context-engineering | Have | The kit is built on it: rules files, glob-scoped standards, state files, pattern source, one phase per chat, restart at a completed boundary (PROGRESS.md), short error output, ticket and tool text as data. |
| using-agent-skills | Have | Its lifecycle matches the kit's tracks (and suggests the same short path for bugs: debug → test → review). Its core behaviours (surface assumptions, stop on confusion, push back, simplicity, scope, verify) are already the hard rules and checklists. |

**Token cost:** every Add goes in the file that loads only when it's needed (the backend, frontend, database or
testing rules, or the phase skill), never in the always-on rules, so the cost lands only where the work is.
