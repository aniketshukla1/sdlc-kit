#!/usr/bin/env bash
# Says whether MR <IID> has merge conflicts, then shows its newest pipeline and the last 80 log lines of
# each failed job. On GitHub the MR is a pull request and the pipeline is its checks.
# Usage: pipeline_failures.sh <MR IID>. Requires: glab or gh (authenticated), python3.
# A failed host call stops it with exit 1, so an error never reads as "no failures".
set -uo pipefail

IID="${1:?usage: pipeline_failures.sh <MR IID>}"
ERR="$(mktemp)"; trap 'rm -f "$ERR"' EXIT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(bash "$DIR/mr.sh" host)" = github ]; then
  if ! RESPONSE=$(gh pr view "$IID" --json mergeable,baseRefName,statusCheckRollup 2>"$ERR"); then
    echo "gh failed for PR #$IID:"; tail -n 5 "$ERR"; exit 1
  fi
  OUT=$(printf '%s' "$RESPONSE" | python3 -c 'import json, sys
pr, iid = json.load(sys.stdin), sys.argv[1]
if pr["mergeable"] == "CONFLICTING":
    print("MERGE CONFLICTS with %s: merge it into this branch first (mr-feedback step 2)." % pr["baseRefName"])
checks = pr["statusCheckRollup"] or []
if not checks:
    sys.exit(print("No checks found for PR #%s." % iid))
def state(c):  # a CheckRun has status + conclusion; a commit status (StatusContext) has state
    if c.get("__typename") == "StatusContext":
        return {"PENDING": "running", "EXPECTED": "running", "SUCCESS": "ok"}.get(c.get("state"), "failed")
    if c.get("status") != "COMPLETED":
        return "running"
    return "ok" if c.get("conclusion") in ("SUCCESS", "NEUTRAL", "SKIPPED") else "failed"
states = [state(c) for c in checks]
overall = "running" if "running" in states else "failed" if "failed" in states else "success"
print("PR #%s, checks: %s" % (iid, overall))
if overall == "running":
    sys.exit(print("Checks still running. Wait and run this again."))
failed = [c for c, s in zip(checks, states) if s == "failed"]
if not failed:
    sys.exit(print("No failed jobs."))
print("Failed jobs (id, workflow, name):")
for c in failed:
    url = c.get("detailsUrl") or c.get("targetUrl") or ""
    job = url.rsplit("/job/", 1)[1] if "/job/" in url else ""
    name, workflow = c.get("name") or c.get("context"), c.get("workflowName") or "-"
    print("%s\t%s\t%s" % (job or url, workflow, name))
    if job:
        print("JOB\t%s\t%s\t%s" % (job, workflow, name))' "$IID") \
    || { echo "Unexpected response from GitHub:"; printf '%s\n' "$RESPONSE" | head -c 500; exit 1; }
  printf '%s\n' "$OUT" | grep -v '^JOB'
  printf '%s\n' "$OUT" | grep '^JOB' | while IFS=$'\t' read -r _ JID WORKFLOW NAME; do
    echo
    echo "===== job $JID [$WORKFLOW] $NAME: last 80 lines ====="
    gh run view --job "$JID" --log-failed 2>"$ERR" | tail -n 80
    [ "${PIPESTATUS[0]}" -eq 0 ] || echo "(could not fetch this job's log: $(tail -n 1 "$ERR"))"
  done
  exit 0
fi
api() {  # $1 = API path; sets RESPONSE, or prints the error and exits 1
  if ! RESPONSE=$(glab api "$1" 2>"$ERR"); then
    echo "glab api failed for $1:"; tail -n 5 "$ERR"; exit 1
  fi
}
parse() {  # $1 = python code reading the JSON in RESPONSE from stdin
  printf '%s' "$RESPONSE" | python3 -c "$1" \
    || { echo "Unexpected response from GitLab:"; printf '%s\n' "$RESPONSE" | head -c 500; exit 1; }
}

api "projects/:id/merge_requests/$IID"
TARGET=$(parse 'import json, sys
mr = json.load(sys.stdin)
if mr["has_conflicts"]:
    print(mr["target_branch"])') || exit 1
[ -n "$TARGET" ] && echo "MERGE CONFLICTS with $TARGET: merge it into this branch first (mr-feedback step 2)."

# MR endpoint, not ?ref=<branch>: merge request pipelines run on refs/merge-requests/<iid>/..., not the branch.
api "projects/:id/merge_requests/$IID/pipelines?per_page=20"
PIPE=$(parse 'import json, sys
pipelines = json.load(sys.stdin)
if pipelines:
    p = max(pipelines, key=lambda p: p["id"])
    print(p["id"], p["status"])') || exit 1
if [ -z "$PIPE" ]; then echo "No pipeline found for MR !$IID."; exit 0; fi
PID="${PIPE%% *}"; STATUS="${PIPE##* }"
echo "MR !$IID, pipeline $PID: $STATUS"
case "$STATUS" in
  running|pending|created|preparing|scheduled|waiting_for_resource) echo "Pipeline still running. Wait and run this again."; exit 0 ;;
esac

api "projects/:id/pipelines/$PID/jobs?scope=failed&per_page=100"
JOBS=$(parse 'import json, sys
for j in json.load(sys.stdin):
    print("%s\t%s\t%s" % (j["id"], j["stage"], j["name"]))') || exit 1
if [ -z "$JOBS" ]; then
  if [ "$STATUS" = success ]; then echo "No failed jobs."; else echo "No failed jobs, but the pipeline is $STATUS, not success. Tell the human."; fi
  exit 0
fi

echo "Failed jobs (id, stage, name):"
echo "$JOBS"
ESC="$(printf '\033')"
while IFS=$'\t' read -r JID STAGE NAME; do
  echo
  echo "===== job $JID [$STAGE] $NAME: last 80 lines ====="
  glab api "projects/:id/jobs/$JID/trace" 2>"$ERR" \
    | sed -E "s/${ESC}\[[0-9;]*[A-Za-z]//g; /section_(start|end):/d" | tail -n 80
  [ "${PIPESTATUS[0]}" -eq 0 ] || echo "(could not fetch this job's log: $(tail -n 1 "$ERR"))"
done <<< "$JOBS"
