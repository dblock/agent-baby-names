#!/bin/bash
# Names a session "<emoji> <repo>" after one of your GitHub repositories, forks included, that the prompt mentions,
# else the Git checkout that holds the working directory, else a topic; see lib/repos. The list comes from gh, which
# must be logged in, and is cached for a day. Without gh, or when it fails, the old list is kept.
#
# Options, all optional, besides those in lib/repos:
#   owners  organizations or users whose repositories to add, such as ["mongoid"] (default none)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/repos
source "$dir/../../lib/repos"

# GitHub account names only, so each is safe as an argument and in the cache file name.
owners="$(jq -r '.owners // [] | if type == "array" then .[] else . end | tostring' <<<"$options" 2>/dev/null |
  grep -E '^[A-Za-z0-9-]+$' | tr '\n' ' ')"

list_repos() {
  local owner
  {
    gh repo list --limit 1000 --json name --jq '.[].name' || return 1
    for owner in $owners; do
      gh repo list "$owner" --limit 1000 --json name --jq '.[].name' || return 1
    done
  } 2>/dev/null | sort -u
}

key="$(slug "$owners")"
name_session "github-repos${key:+-$key}.txt"
