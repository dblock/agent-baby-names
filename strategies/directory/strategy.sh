#!/bin/bash
# An example strategy: names a session after the folder it works in, such as "my-project" for ~/source/my-project.
# It reads {"prompt", "cwd", "host", "name"} JSON on standard input, where name is the name that the strategies before
# it gave, and prints a new name, or nothing to keep that one.
#
# Options, all optional:
#   prefix  text to put before the name (default none)
set -uo pipefail

input="$(cat)"
[[ -z "$(jq -r '.name // empty' <<<"$input")" ]] || exit 0
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[[ -n "$cwd" && "$cwd" != / ]] || exit 0
prefix="$(jq -r '.prefix // empty | tostring' <<<"${AGENT_BABY_NAMES_OPTIONS:-}" 2>/dev/null)"
echo "$prefix$(basename "$cwd")"
