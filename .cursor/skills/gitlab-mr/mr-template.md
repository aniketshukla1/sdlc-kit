## Jira
<KEY>: <jira url>
Parent: <the Parent key in PROGRESS.md, or None>

## Summary
<2–3 sentences: what changes and why; any shortcut or known limit>

## Changes
- Database: <migration file / None>
- Backend: <endpoints, services>
- Frontend: <screens, components>

## Acceptance criteria
| AC | Covered by test(s) |
|----|--------------------|
| AC1 | `test_...` |

## Edge cases handled
- ...

## How to test manually
1. ...

## Database
- Migration: <yes/no>. Downgrade tested locally: <yes/no>
- Backfill or ops needed: <None / see Human actions>

## Elasticsearch
None (agent does not change mappings or indices)

## Human actions required
None

## Rollback
<revert this MR; the migration downgrade (tested); or the feature flag to turn off>

<proof.md from step 7, pasted unedited: proof_pack.sh's output, starting with "## Proof">

_Created by the coding agent. Screenshots for UI changes: reviewer to add if needed._
