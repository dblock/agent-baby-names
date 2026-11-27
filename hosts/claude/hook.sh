#!/bin/bash
# Claude Code UserPromptSubmit hook: names a session that has no title yet. Sessions that already have a title,
# because this hook or the user named them, are left alone. It never fails the prompt: on any error it prints
# nothing and exits 0.
set -uo pipefail

root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../.." && pwd)"

main() {
  local input title
  input="$(cat)"
  jq -e 'type == "object" and (.session_title // "") == ""' <<<"$input" >/dev/null 2>&1 || return 0
  title="$(jq -c '{prompt, cwd}' <<<"$input" | "$root/bin/agent-baby-names" --host claude 2>/dev/null)"
  [[ -n "$title" ]] || return 0
  jq -cn --arg title "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $title}}'
}

main
exit 0
