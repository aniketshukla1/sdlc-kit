#!/usr/bin/env bash
# Shows the review comments on MR <IID> that still need an answer: unresolved threads and comments with
# activity since your last "Agent update" note. Threads you already answered are only counted.
# Usage: mr_comments.sh <MR IID>. Requires: glab or gh (authenticated), python3. A failed host call exits 1.
set -uo pipefail

IID="${1:?usage: mr_comments.sh <MR IID>}"
ERR="$(mktemp)"; trap 'rm -f "$ERR"' EXIT
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(bash "$DIR/mr.sh" host)"
if [ "$HOST" = github ]; then
  Q='query($owner: String!, $repo: String!, $number: Int!) { repository(owner: $owner, name: $repo) { pullRequest(number: $number) {
  reviewThreads(first: 100) { nodes { isResolved path line comments(first: 100) { nodes { author { login } body createdAt } } } }
  comments(first: 100) { nodes { author { login } body createdAt } }
  reviews(first: 100) { nodes { author { login } body createdAt } } } } }'
  if ! RESPONSE=$(gh api graphql -F owner='{owner}' -F repo='{repo}' -F number="$IID" -f query="$Q" 2>"$ERR"); then
    echo "gh failed for PR #$IID comments:"; tail -n 5 "$ERR"; exit 1
  fi
elif ! RESPONSE=$(glab api "projects/:id/merge_requests/$IID/discussions?per_page=100" --paginate 2>"$ERR"); then
  echo "glab api failed for MR !$IID discussions:"; tail -n 5 "$ERR"; exit 1
fi

printf '%s' "$RESPONSE" | python3 -c 'import json, sys
text, MARK = sys.stdin.read(), "Agent update"
if sys.argv[1] == "github":  # review threads, conversation comments and review bodies, shaped like GitLab notes
    pr = json.loads(text)["data"]["repository"]["pullRequest"]
    def note(c, **extra):
        return dict(body=c["body"], created_at=c["createdAt"], author={"username": (c["author"] or {}).get("login", "ghost")}, **extra)
    threads = [[note(c, resolvable=True, resolved=t["isResolved"], position={"new_path": t["path"], "new_line": t["line"]})
                for c in t["comments"]["nodes"]] for t in pr["reviewThreads"]["nodes"]]
    threads += [[note(c)] for c in pr["comments"]["nodes"] + pr["reviews"]["nodes"] if c["body"].strip()]
else:
    decoder, i, discussions = json.JSONDecoder(), 0, []
    while i < len(text):  # --paginate prints one JSON array per page
        if text[i].isspace():
            i += 1
            continue
        page, i = decoder.raw_decode(text, i)
        discussions += page
    threads = [[n for n in d["notes"] if not n["system"]] for d in discussions]
threads = [t for t in threads if t]
last = max((n["created_at"] for t in threads for n in t if n["body"].startswith(MARK)), default="")
todo = waiting = 0
for t in threads:
    resolvable = [n for n in t if n.get("resolvable")]
    if t[0]["body"].startswith(MARK) or (resolvable and all(n.get("resolved") for n in resolvable)):
        continue
    if all(n["created_at"] <= last for n in t):  # answered in an earlier round
        waiting += bool(resolvable)
        continue
    todo += 1
    pos = t[0].get("position") or {}
    where = " %s:%s" % (pos.get("new_path") or pos.get("old_path"), pos.get("new_line") or pos.get("old_line")) if pos else ""
    print("--- comment %d%s" % (todo, where))
    for n in t:
        print("@%s: %s" % (n["author"]["username"], n["body"].strip().replace("\n", "\n    ")))
print("To handle: %d. Answered, waiting for the reviewer to resolve: %d." % (todo, waiting))' "$HOST" \
  || { echo "Unexpected response from $HOST:"; printf '%s\n' "$RESPONSE" | head -c 500; exit 1; }
