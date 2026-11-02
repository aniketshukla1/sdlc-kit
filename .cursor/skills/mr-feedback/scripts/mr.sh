#!/usr/bin/env bash
# One interface to the MR host: GitLab through glab, or GitHub through gh (where an MR is a pull request).
# Usage: mr.sh host | create <title> <body file> [--draft] | find <KEY> | view <id> | checkout <id>
#        | note <id> <body file> | thread <id> <body file> | set-body <id> <body file> | retry <job id>
# The host comes from .agent/git-host.txt (gitlab or github), else from the origin remote's URL.
# There is no merge or approve: a human does those.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)" || exit 1
HOST="$(cat "$ROOT/.agent/git-host.txt" 2>/dev/null | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
[ -n "$HOST" ] || case "$(git remote get-url origin 2>/dev/null)" in *github*) HOST=github ;; *) HOST=gitlab ;; esac
BASE="${BASE_REF:-origin/main}"; BASE="${BASE#origin/}"
CMD="${1:-}"; [ $# -gt 0 ] && shift

case "$HOST:$CMD" in
  *:host) echo "$HOST" ;;
  gitlab:create) glab mr create --source-branch "$(git branch --show-current)" --target-branch "$BASE" --title "$1" \
                   --description "$(cat "$2")" --remove-source-branch --yes ${3:+"$3"} ;;
  github:create) gh pr create --head "$(git branch --show-current)" --base "$BASE" --title "$1" --body-file "$2" ${3:+"$3"} ;;
  gitlab:find) glab mr list --all --search "$1" ;;
  github:find) gh pr list --state all --search "$1 in:title" ;;
  gitlab:view) glab mr view "$1" ;;
  github:view) gh pr view "$1" ;;
  gitlab:checkout) glab mr checkout "$1" ;;
  github:checkout) gh pr checkout "$1" ;;
  gitlab:note) glab mr note "$1" -m "$(cat "$2")" ;;
  gitlab:thread) glab api -X POST "projects/:id/merge_requests/$1/discussions" -f "body=$(cat "$2")" ;;
  github:note|github:thread) gh pr comment "$1" --body-file "$2" ;;  # a resolvable GitHub thread needs a code line
  gitlab:set-body) glab mr update "$1" --description "$(cat "$2")" ;;
  github:set-body) gh pr edit "$1" --body-file "$2" ;;
  gitlab:retry) glab ci retry "$1" ;;
  github:retry) gh run rerun --job "$1" ;;
  *) sed -n '3,4p' "$0" | sed 's/^# //'; exit 2 ;;
esac
