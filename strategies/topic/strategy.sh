#!/bin/bash
# Names a session after a short topic that the model writes from the prompt, such as "loud-laptop-fan": lowercase words
# joined by hyphens. A session that already has a name keeps it, and an empty prompt names nothing.
#
# Options, all optional: those in lib/strategy.
set -uo pipefail

dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=lib/strategy
source "$dir/../../lib/strategy"

[[ -z "$name" && -n "$prompt" ]] || exit 0
reply="$(ask_model "Write a session title for this request: \"${prompt:0:1000}\". Rules: lowercase words joined by hyphens, 2 to 4 words, no punctuation. Output only the title.")"
slug "$(head -1 <<<"$reply")"
