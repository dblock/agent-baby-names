#!/bin/bash
# An example strategy: names a session after the folder it works in, such as "my-project" for ~/source/my-project.
# It reads {"prompt", "cwd", "host"} JSON on standard input and prints one name, or nothing.
#
# Options, all optional:
#   prefix  text to put before the name (default none)
set -uo pipefail

cwd="$(jq -r '.cwd // empty')"
[[ -n "$cwd" && "$cwd" != / ]] || exit 0
prefix="$(jq -r '.prefix // empty | tostring' <<<"${AGENT_BABY_NAMES_OPTIONS:-}" 2>/dev/null)"
echo "$prefix$(basename "$cwd")"
