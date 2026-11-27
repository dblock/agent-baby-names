#!/bin/bash
# Asks the model a question that you write, and names the session after the first line of its answer. The template's
# {prompt}, {name}, {cwd}, and {host} placeholders become the session's prompt, the name so far, its folder, and its
# host. Without a template, or without an answer, the name so far is kept.
#
# Options, all optional, besides those in lib/strategy:
#   template  the question to ask, with placeholders (default none, which keeps the name so far)
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/strategy
source "$dir/../../lib/strategy"

template="$(option template "")"
[[ -n "$template" ]] || exit 0
host="$(jq -r '.host // empty' <<<"$input")"

# One pass, so a placeholder inside the prompt or the name is not replaced again.
question="$(jq -rn --arg t "$template" --arg prompt "${prompt:0:1000}" --arg name "$name" --arg cwd "$cwd" \
  --arg host "$host" '{$prompt, $name, $cwd, $host} as $v | $t | gsub("\\{(?<k>prompt|name|cwd|host)\\}"; $v[.k])')"
reply="$(ask_model "$question" | head -1)"
# Trim spaces and the quotes or backticks that models put around an answer, and keep at most 80 characters.
reply="$(sed -E 's/^[[:space:]"`'\'']+//; s/[[:space:]"`'\'']+$//' <<<"$reply")"
echo "${reply:0:80}"
