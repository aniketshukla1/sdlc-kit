---
name: chat
description: Starts the ticket workflow from a request typed in chat, without a Jira or Linear ticket. Turns "fix this bug" or "add this feature" into a local ticket with testable acceptance criteria and a CHAT-<n> key, then runs the normal track. Use when someone asks in chat to fix, build, add or change something and gives no ticket key.
---
# Start from chat (no ticket)

A request typed in chat becomes a local ticket, so the same tracks, tests first and checks apply. A chat ticket
has no tracker: what the workflow would post to a ticket, you say in chat and log in PROGRESS.md.

## Steps
1. Type: Bug (something is broken), Feature (new or changed behaviour) or Task (no behaviour change: a refactor,
   an upgrade). Unclear → ask.
2. Draft the ticket with the template for its type, from `.cursor/skills/jira-create/`: Bug → `bug-template.md`,
   Feature → `enhancement-template.md`, Task → `task-template.md`. Keep every heading.
   - At the top: `Type: <Bug|Feature|Task>`, then the request word for word on a `Request:` line.
   - The request says nothing about a section: write `None`, or add a line under Open Questions. Never invent
     steps, error text, numbers, names or root causes.
   - Acceptance criteria: numbered, each one a check a test can make (Given / When / Then fits most).
   - Leave out Sub-tasks. More than one mergeable part → ask the human to split it into separate requests.
3. Missing parts (Bug: steps to reproduce, actual and expected result; Feature and Task: acceptance criteria):
   ask for them in ONE message (max 5 questions), each with your best guess so the human can answer "yes".
4. Show the draft. Then write exactly: `Reply "start" or "changes: <feedback>".` STOP.
5. On `start`, pick the key: `n` = 1 + the highest number after `CHAT-` in `.agent/work/` and in
   `git branch -a --list '*CHAT-*'` (after `git fetch -q origin`), or 1 if there's none. The key is `CHAT-<n>`.
6. Save the draft as `.agent/work/CHAT-<n>/TICKET.md`. Tell the human the key: `Continue CHAT-<n>` picks it up
   in a new chat, like any ticket.
7. Start the track for `CHAT-<n>`: Bug → /quick-fix. Feature or Task → /ticket-intake (the full track).

## Done when
- [ ] The human typed `start`; TICKET.md has the request word for word and testable acceptance criteria
- [ ] The track's first skill runs for `CHAT-<n>`
