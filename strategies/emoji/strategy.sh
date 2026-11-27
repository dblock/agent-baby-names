#!/bin/bash
# Puts an emoji before the name so far, such as "🧪 hello-world". The emoji comes from the pins file, else the cache,
# else the model, whose pick is cached. Without a name it names nothing.
#
# Options, all optional, besides those in lib/strategy:
#   pins  a file of "<name> <emoji>" lines that override cached emojis (default emojis.txt next to this file)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/strategy
source "$dir/../../lib/strategy"

[[ -n "$name" ]] || exit 0
pins_file="$(option pins "$dir/emojis.txt" path)"
emojis_cache="$cache_dir/emojis.txt"
key="$(slug "$name")"

# One emoji without letters or spaces, or nothing.
valid_emoji() {
  [[ -n "$1" && ${#1} -le 8 && "$1" != *[[:alnum:][:space:]]* ]]
}

lookup() {
  [[ -n "$key" && -f "$1" ]] && awk -v k="$key" '$1 == k { print $2; exit }' "$1"
}

emoji="$(lookup "$pins_file")"
[[ -z "$emoji" ]] && emoji="$(lookup "$emojis_cache")"
if [[ -z "$emoji" ]]; then
  emoji="$(ask_model "Reply with one emoji that fits a coding session named \"$name\". Output only the emoji.")"
  emoji="${emoji//[[:space:]]/}"
  [[ -n "$key" ]] && valid_emoji "$emoji" && echo "$key $emoji" >>"$emojis_cache"
fi
valid_emoji "$emoji" || emoji="💬"
echo "$emoji $name"
