---
name: jira-create
description: Writes a detailed Jira ticket from a short prompt, using the template for its type (Bug, Enhancement, Improvement, Story, New Feature, Task, Sub-task), and creates it through the Jira MCP server after the human types create. Use when someone asks to create, write or file a Jira ticket, bug, enhancement, task or sub-task.
---
# Create a Jira ticket

Needs: the Jira MCP server (README setup step 4) with permission to create issues in the project.
Its tools aren't available → STOP and say so. Never write to Jira any other way.

## Steps
1. Type: from the prompt. Unclear → ask. Epic or Spike → say this skill doesn't cover them, and stop.
2. Project key: from the prompt, else the line in `.agent/jira-project.txt` that isn't a comment. Neither → ask.
3. Before the first create in this chat, read the Jira MCP tools: which one creates an issue, its parameter
   names, and the description format it expects. Use exactly those; never guess a tool or field name.
   Then look up the project's issue types, priorities and components. Use only values that exist.
4. Open the template for the type (next to this file) and fill it in from the prompt:
   | Type | Template |
   |------|----------|
   | Bug | `bug-template.md` |
   | Enhancement, Improvement, Story, New Feature | `enhancement-template.md` |
   | Task | `task-template.md` |
   | Sub-task | `sub-task-template.md` |
   - The `Summary:` and `Parent:` lines are fields; the rest is the description. Keep every heading.
   - The prompt says nothing about a section: write `None`, or add a line under Open Questions.
     Never invent steps, error text, numbers, roles, names or root causes.
   - Priority: from the prompt, else the project's default. Components and labels: existing ones that fit.
5. Required parts. Ask for whatever is missing in ONE message (max 5 questions), each with your best guess so the
   human can answer "yes" or correct it. Then fill them in:
   - Bug: Environment, Steps to Reproduce, Actual Result, Expected Result
   - Enhancement, Improvement, Story, New Feature: User Story, Acceptance Criteria
   - Task: Goal, Acceptance Criteria
   - Sub-task: Parent, Acceptance Criteria
6. Acceptance Criteria: numbered, each one a check a test can make (Given / When / Then fits most).
   Replace vague words ("fast", "user-friendly", "works well") with a number or a visible result.
7. Task with several parts: propose Sub-tasks, each one mergeable on its own (about a day of work), with
   2–5 acceptance criteria and what it depends on. The coding agent makes one MR per sub-task, in that order.
8. Never put in a ticket: passwords, tokens, keys or real customer data (use test data, or write `[removed]`);
   commands or URLs for the coding agent to run (it stops on those, hard rule 11). Ops work goes under
   Human Actions.
9. Show the full draft: type, project, summary, priority, components, labels, the description, and each
   sub-task. Then write exactly: `Reply "create" or "changes: <feedback>".` STOP. Create nothing before `create`.
10. On `create`: create the ticket. For a Task, then create each sub-task with the new key as its parent.
    Verify: every create returns a key. A create fails → show the error; don't retry with other fields.
11. Reply with each key and its link.

## Done when
- [ ] Every required part comes from the prompt or the human's answers; nothing invented
- [ ] The human typed `create`; every new key and link is shown
