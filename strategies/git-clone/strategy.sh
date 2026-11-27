#!/bin/bash
# Names a session after a Git checkout under the root folder that the prompt mentions, else the checkout that holds the
# working directory; see lib/repos. Without a root, only the working directory's checkout counts. A checkout is named after its origin, else upstream, remote, so ~/source/foo/master
# and a fork checkout in ~/source/foo/octocat-foo are both foo. Checkouts are found up to three folders deep, without
# looking inside a checkout. The list is cached and rebuilt when the root folder changes or after a day.
#
# Options, all optional, besides the cache option in lib/strategy:
#   root  where checkouts live (default none)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/repos
source "$dir/../../lib/repos"

root="$(option root "" path)"
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

name_session "${root:+git-clone.txt}"
