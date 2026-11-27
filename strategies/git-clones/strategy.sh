#!/bin/bash
# The default strategy: names a session "<emoji> <repo>" after a Git checkout under the root folder that the prompt
# mentions, else the checkout that holds the working directory, else a topic; see lib/repos. A checkout is named after
# its origin, else upstream, remote, so ~/source/foo/master and a fork checkout in ~/source/foo/dblock-foo are both foo.
# Checkouts are found up to three folders deep, without looking inside a checkout. The list is cached and rebuilt when
# the root folder changes or after a day.
#
# Options, all optional, besides those in lib/repos:
#   root  where checkouts live (default ~/source)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/repos
source "$dir/../../lib/repos"

root="$(option root "$HOME/source" path)"
root="${root%/}"

# The checkouts in a folder, down to the given depth.
find_clones() {
  local child
  for child in "$1"/*/; do
    [[ -d "$child" ]] || continue
    child="${child%/}"
    if [[ -e "$child/.git" ]]; then
      echo "$child"
    elif (($2 > 1)); then
      find_clones "$child" $(($2 - 1))
    fi
  done
}

list_repos() {
  local clone
  find_clones "$root" 3 | while IFS= read -r clone; do repo_name "$clone"; done | sort -u
}

list_stale() {
  [[ "$root" -nt "$1" ]]
}

name_session git-clones.txt
