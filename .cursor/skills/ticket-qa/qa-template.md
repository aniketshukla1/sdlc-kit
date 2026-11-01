# <KEY> QA
MR: !<IID> (<branch>)   Date: <date>

## Checks
| # | Must-pass | Given / When / Then | How (test name, or steps) | Where (local / Testing) | Result | Evidence |
|---|-----------|---------------------|---------------------------|-------------------------|--------|----------|
| 1 | yes | Given ..., when ..., then ... | `test_...` | local | | |

## Coverage (one that doesn't apply: N/A: <why>)
- Golden path, end to end:
- Empty and minimum (0 items, 1 item, optional fields left out):
- Boundaries (max length, max number, unicode):
- Errors (invalid input 422, not found 404, no permission 403, duplicate 409, network failure):
- Two users at once, or a refresh during a save:
- Largest realistic input (no hang or timeout):
- Keyboard and screen reader (Tab order, Esc closes dialogs, focus returns, labels read):
- Existing data, URLs and saved preferences still work:
- Logs, audit entries or events the change should write:

## Result
- Pass: <row: one-line evidence>
- Fail: <row: exact steps, expected vs actual>
- Blocked: <row: why>

Verdict: <QA passed / QA failed / Blocked>
