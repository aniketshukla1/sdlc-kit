#!/usr/bin/env bash
# Sourced from backend/ by check_migration.sh and check_backend.sh: db_guard refuses a database that isn't local.
# The URL comes from $DB_URL_VAR (default DATABASE_URL), else from backend/.env. Only its host is printed,
# never the URL (it holds the password). Local hosts: LOCAL_DB_HOSTS (space-separated).
DB_VAR="${DB_URL_VAR:-DATABASE_URL}"
DB_URL="${!DB_VAR:-$(sed -n "s/^\(export \)\{0,1\}${DB_VAR}=//p" .env 2>/dev/null | tail -n 1)}"
DB_URL=${DB_URL//[\"\']/}

db_guard() {  # $1 = required (refuse when no URL is found) | optional
  local host h
  if [ -z "$DB_URL" ]; then
    [ "$1" = optional ] && return 0
    echo "Refusing: can't tell which database this would use. Set $DB_VAR to your local database URL."; return 1
  fi
  host="${DB_URL#*://}"; host="${host##*@}"; host="${host%%/*}"
  case "$host" in \[*) host="${host#[}"; host="${host%%]*}" ;; *) host="${host%:*}" ;; esac
  [ -z "$host" ] && return 0  # unix socket or sqlite file
  for h in ${LOCAL_DB_HOSTS:-localhost 127.0.0.1 ::1 db mysql mariadb}; do [ "$host" = "$h" ] && return 0; done
  echo "Refusing: $DB_VAR points at host '$host', which isn't a local database. Use a local DB, or add its host to LOCAL_DB_HOSTS."
  return 1
}
