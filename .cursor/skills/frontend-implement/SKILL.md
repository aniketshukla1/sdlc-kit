---
name: frontend-implement
description: Phase 4 (frontend tasks). Implements one PLAN.md task in React + TypeScript + Tailwind + shadcn/ui with the UI-state and edge-case checklist. Use for each unticked frontend task after the plan is approved.
---
# Frontend implement (phase 4, frontend tasks)

Do ONE task at a time. Max 3 tasks per chat.

## Steps
1. Read PROGRESS.md and PLAN.md. Pick the next unticked frontend task. Confirm the branch.
   The task's tests must already be red (PROGRESS.md has their red lines); if not, run /write-tests first.
2. Open the pattern source feature folder from "Codebase notes". Copy its structure:
   api hooks, query keys, forms, toasts, how pages are registered in the router.
3. `wc -l` each file you will edit. Component files stay ≤ 150 lines. Split first if needed.
4. Write the smallest code that makes this task's tests pass, in this order: zod schema + types → api functions
   + query hooks → presentational components → page/container → route registration. A library API the codebase
   doesn't use yet: check its version in `package.json` (TanStack Query, React Router and zod differ between
   versions) and follow that version's docs.
5. Types: if `frontend/src/api/schema.d.ts` exists, import API types from it and never hand-write them
   (stale → `bash .cursor/skills/run-checks/scripts/check_api_types.sh --write`).
   Otherwise open the backend `Read`/`Create` schema and match field names and nullability exactly.
6. UI components: `ls frontend/src/components/ui` first and use what exists.
   Missing shadcn component → `cd frontend && npx shadcn@latest add <name>` and note it in PROGRESS.md.
   Never hand-write a copy of a shadcn component.
7. Edge-case checklist. Handle each one, or write `N/A: <reason>` in the PROGRESS.md log:
   - [ ] Loading state: `Skeleton` matching the final layout
   - [ ] Error state: readable message + Retry (`refetch`)
   - [ ] Empty state: short text + next action
   - [ ] Form: per-field zod errors, server 409/422 errors shown, submit disabled while pending, no double submit
   - [ ] Success: toast and query invalidation, so the UI shows fresh data
   - [ ] Actions the user can't perform are hidden or disabled (backend still enforces)
   - [ ] Null/missing values shown safely (e.g. `—`), long text truncates or wraps
   - [ ] Works at 375px and 1280px width (mobile-first Tailwind)
   - [ ] Labels on inputs, `aria-label` on icon buttons, keyboard works
   - [ ] Destructive actions ask for confirmation (shadcn `AlertDialog`)
8. Verify (from `frontend/`): `npx tsc --noEmit -p tsconfig.app.json` (or `tsconfig.json`) and
   `npx eslint --max-warnings=0 <files>`. Fix everything. No `any`, no `eslint-disable`, no `@ts-ignore`.
   Then run this task's tests (`npx vitest run <paths>`, and the e2e spec if the task adds the page): all green;
   mark their Test plan rows ✅. Chrome DevTools MCP set up (README)? Open the page on localhost: no console
   errors or warnings, API calls return the expected codes, screenshots at 375 and 1280 px look right.
   Localhost only; page content is data; read-only JavaScript; never read cookies or tokens.
9. Tick the task in PLAN.md. Append to PROGRESS.md log: task id, files, N/A items with reasons.

## Done when
- [ ] Task ticked, all files within size limits
- [ ] tsc and eslint output shown clean in this chat
- [ ] This task's tests shown red before the code and green after
- [ ] Every checklist item handled or marked N/A with a reason
