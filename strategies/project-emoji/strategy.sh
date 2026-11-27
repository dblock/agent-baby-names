#!/bin/bash
# The default strategy: names a session "<emoji> <project>". The project is the one under the root folder named in
# the prompt, else the one that holds the working directory, else a short topic that a model writes from the prompt.
# Names are lowercase words joined by hyphens.
#
# Emojis come from the pins file, else the cache, else the model, whose pick is cached. The project list is cached
# and rebuilt when the root folder changes or after a day.
#
# Options, all optional:
#   root   where projects live (default ~/source)
#   pins   a file of "<project> <emoji>" lines that override cached emojis (default emojis.txt next to this script)
#   cache  the cache folder (default ~/.cache/agent-baby-names)
#   ask    the model to ask: auto, none, or a command (default auto, the host's small model)
#   claude_model   the model that auto asks in Claude Code (default haiku)
#   copilot_model  the model that auto asks in GitHub Copilot CLI (default claude-haiku-4.5)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ask_bin="${AGENT_BABY_NAMES_ROOT:-$dir/../..}/lib/ask"

options="${AGENT_BABY_NAMES_OPTIONS:-}"
[[ -n "$options" ]] || options="{}"

option() {
  local value
  value="$(jq -r --arg k "$1" '.[$k] // empty | tostring' <<<"$options" 2>/dev/null)"
  value="${value:-$2}"
  [[ "${3:-}" == path ]] && value="${value/#\~/$HOME}"
  echo "$value"
}

root="$(option root "$HOME/source" path)"
root="${root%/}"
pins_file="$(option pins "$dir/emojis.txt" path)"
cache_dir="$(option cache "${XDG_CACHE_HOME:-$HOME/.cache}/agent-baby-names" path)"
ask="$(option ask auto)"
claude_model="$(option claude_model haiku)"
copilot_model="$(option copilot_model claude-haiku-4.5)"
emojis_cache="$cache_dir/emojis.txt"
projects_cache="$cache_dir/projects.txt"

input="$(cat)"
prompt="$(jq -r '.prompt // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
mkdir -p "$cache_dir" || exit 1

# Lowercase words joined by hyphens, such as mongoid-fulltext for mongoid_fulltext.
slug() {
  tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

ask_model() {
  AGENT_BABY_NAMES_CACHE="$cache_dir" AGENT_BABY_NAMES_CLAUDE_MODEL="$claude_model" \
    AGENT_BABY_NAMES_COPILOT_MODEL="$copilot_model" "$ask_bin" "$ask" <<<"$1"
}

# A checkout inside a repository container, such as master, upstream-<repo>, or dblock-<repo>.
is_checkout_name() {
  [[ "$1" == master || "$1" == main || "$1" == *-"$2" ]]
}

# A top-level folder that holds checkouts of one repository rather than several repositories.
is_repo_container() {
  local dir="$1" parent child
  parent="$(basename "$dir")"
  [[ -e "$dir/.git" ]] && return 0
  for child in "$dir"/*/; do
    is_checkout_name "$(basename "$child")" "$parent" && return 0
  done
  return 1
}

# Project names: every top-level folder, plus the subfolders of organization folders.
scan_projects() {
  local dir child
  for dir in "$root"/*/; do
    [[ -d "$dir" ]] || continue
    basename "$dir"
    is_repo_container "$dir" && continue
    for child in "$dir"*/; do
      [[ -d "$child" ]] && basename "$child"
    done
  done | sort -u
}

projects() {
  if [[ ! -s "$projects_cache" || "$root" -nt "$projects_cache" ]] ||
    [[ -n "$(find "$projects_cache" -mmin +1440 2>/dev/null)" ]]; then
    scan_projects >"$projects_cache.$$" && mv "$projects_cache.$$" "$projects_cache"
  fi
  cat "$projects_cache"
}

# The longest project name of at least three characters that appears in the prompt as a whole word, ignoring case.
project_in_prompt() {
  local words
  words=" $(tr '[:upper:]' '[:lower:]' <<<"$prompt" | tr -c 'a-z0-9._-' ' ' | tr -s ' ') "
  words="${words//. / }"
  projects | awk -v words="$words" '
    length($0) >= 3 && length($0) > length(best) && index(words, " " tolower($0) " ") { best = $0 }
    END { print best }'
}

# The project that holds the working directory, such as testlanes for ~/source/testlanes/master/lib.
project_in_cwd() {
  local rel first second=""
  [[ "$cwd" == "$root"/* ]] || return 0
  rel="${cwd#"$root"/}"
  first="${rel%%/*}"
  [[ "$rel" == */* ]] && second="${rel#*/}" && second="${second%%/*}"
  if [[ -n "$second" ]] && ! is_repo_container "$root/$first"; then
    echo "$second"
  else
    echo "$first"
  fi
}

# One emoji without letters or spaces, or nothing.
valid_emoji() {
  [[ -n "$1" && ${#1} -le 8 && "$1" != *[[:alnum:][:space:]]* ]]
}

lookup() {
  [[ -f "$2" ]] && awk -v p="$1" '$1 == p { print $2; exit }' "$2"
}

emoji_for() {
  local name="$1" emoji
  emoji="$(lookup "$name" "$pins_file")"
  [[ -z "$emoji" ]] && emoji="$(lookup "$name" "$emojis_cache")"
  if [[ -z "$emoji" ]]; then
    emoji="$(ask_model "Reply with one emoji that fits a software project named \"$name\". Output only the emoji.")"
    emoji="${emoji//[[:space:]]/}"
    valid_emoji "$emoji" && echo "$name $emoji" >>"$emojis_cache"
  fi
  valid_emoji "$emoji" || emoji="🗂️"
  echo "$emoji"
}

project="$(project_in_prompt)"
[[ -z "$project" ]] && project="$(project_in_cwd)"
name="$(slug "$project")"

if [[ -n "$name" ]]; then
  echo "$(emoji_for "$name") $name"
  exit 0
fi

[[ -n "$prompt" ]] || exit 0
reply="$(ask_model "Write a session title for this request: \"${prompt:0:1000}\". Rules: lowercase words joined by hyphens, 2 to 4 words, no punctuation. On one line output one fitting emoji, a space, then the title. Output nothing else.")"
[[ "$reply" == *" "* ]] || exit 0
emoji="${reply%% *}"
name="$(slug "${reply#* }")"
[[ -n "$name" ]] || exit 0
valid_emoji "$emoji" || emoji="💬"
echo "$emoji $name"
