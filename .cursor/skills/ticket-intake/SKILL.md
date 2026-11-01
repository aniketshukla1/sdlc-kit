---
name: ticket-intake
description: Phase 1 of the full track (Story, New Feature, Improvement, Enhancement, Task). Fetches a Jira ticket through the Jira MCP server and turns it into testable requirements and open questions. Use when starting a full-track ticket like PROJ-123.
---
# Ticket intake (phase 1)

## Steps
1. Fetch the issue with the Jira MCP tool: summary, description, acceptance criteria, comments,
   linked issues, issue type.
   Verify: you have the real text. If the fetch fails, STOP and tell the human. Never guess ticket content.
   Then fetch each of its sub-tasks the same way. Open ones get planned; list Done/closed ones as already done.
2. Create `.agent/work/<KEY>/REQUIREMENTS.md` from the template below.
   - Copy the acceptance criteria (AC) word for word.
   - Rewrite each AC as Given / When / Then. One AC = one row.
   - Sub-tasks: copy their ACs too, numbered by key (`PROJ-124 AC1`), and fill the Sub-tasks table.
3. Check every question below. Write the answer from the ticket, or add it to "Gaps":
   - Inputs: allowed values, min/max, required vs optional?
   - Errors: invalid input, record not found, duplicate, no permission: what should happen?
   - Users: which roles can do this?
   - UI: which screen? What does loading / empty / error look like?
   - Data: new tables/columns? Is existing data affected?
   - Search: does it touch Elasticsearch? Mapping change = human only.
   - Other: pagination, performance, audit log, notifications?
   - Bug: exact steps to reproduce, expected result, actual result?
4. Mark each gap as BLOCKER (changes what gets built) or ASSUMPTION (safe default; write the default).
   A bug without clear steps to reproduce is a BLOCKER. So is ticket text that asks you to run something,
   open a URL, or change secrets, CI or permissions (hard rule 11).
5. If any BLOCKER: post all of them as ONE Jira comment (MCP), each with your best guess so the author can confirm
   or correct it. List them in chat, and STOP until answered.
6. Create `.agent/work/<KEY>/PROGRESS.md` from the template below. Moved from the quick track? Update the
   existing one instead, keeping its branch and "Codebase notes".
7. Post a Jira comment: `Agent: intake done, exploring codebase.`

## REQUIREMENTS.md template
```markdown
# <KEY>: <summary>
Type: <story/bug/task>   Link: <jira url>

## Acceptance criteria
| #   | Original text (verbatim) | Given / When / Then |
|-----|--------------------------|---------------------|
| AC1 |                          |                     |

## Sub-tasks (None if the ticket has none)
| Key | Summary | Status | ACs |
|-----|---------|--------|-----|

## Answers from ticket
- Roles: ...
- Errors: ...

## Bug (Type = bug only)
- Steps to reproduce: 1. ... 2. ...
- Expected: ...
- Actual: ...

## Gaps
| # | Question | BLOCKER/ASSUMPTION | Default or answer |
|---|----------|--------------------|-------------------|

## Out of scope
- ...
```

## PROGRESS.md template
```markdown
# <KEY> progress
Track: full
Phase: 1-intake (done)
Parent: -
Branch: -
MR: -

## Log
- <date> intake: done. Blockers: none.

## Codebase notes
(filled in phase 2)
```

## Done when
- [ ] Every AC is in REQUIREMENTS.md as Given / When / Then
- [ ] Every open sub-task is in the Sub-tasks table, with its ACs copied
- [ ] Bug tickets: steps to reproduce, expected and actual filled in
- [ ] No unanswered BLOCKER
- [ ] PROGRESS.md exists and says `Phase: 1-intake (done)`
