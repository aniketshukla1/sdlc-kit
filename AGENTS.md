# sdlc-kit

This repo uses the sdlc-kit ticket workflow: a Jira or Linear ticket in, a reviewed merge request out (GitLab or GitHub). The kit's
rules, skills and scripts live in `.cursor/`, whichever agent you are.

Before any ticket work, read and follow:
- `.cursor/rules/00-ticket-workflow.mdc`: the phases, state files and hard rules
- `.cursor/rules/10-general-standards.mdc`: size limits, naming and structure

Before editing a file, read the standards for its kind:
- backend Python: `.cursor/rules/20-backend-standards.mdc`
- frontend TypeScript: `.cursor/rules/30-frontend-standards.mdc`
- models, migrations, repositories and search code: `.cursor/rules/40-database-standards.mdc`
- tests: `.cursor/rules/50-testing-standards.mdc`

Use the skill the workflow names for each phase (`.agents/skills/<name>/SKILL.md`, linked to `.cursor/skills/`).
Work is done only when `bash .cursor/skills/run-checks/scripts/check_all.sh` prints `ALL PASS`.
Never merge, approve or force-push, and never touch Perforce, staging, production or Elasticsearch mappings.
