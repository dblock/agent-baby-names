#!/bin/bash
# Claude Code UserPromptSubmit hook: names a session that has no title yet. Sessions that already have a title,
# because this hook or the user named them, are left alone. It never fails the prompt: on any error it prints
# nothing and exits 0.
set -uo pipefail

script="${BASH_SOURCE[0]}"
# Git Bash on Windows may be given a path such as C:\plugins\hook.sh, which readlink and dirname cannot take apart.
command -v cygpath >/dev/null && script="$(cygpath -u "$script")"
root="$(cd "$(dirname "$(readlink -f "$script")")/../.." && pwd)"

main() {
  local input title
  input="$(cat)"
  jq -e 'type == "object" and (.session_title // "") == ""' <<<"$input" >/dev/null 2>&1 || return 0
  title="$(jq -c '{prompt, cwd}' <<<"$input" | "$root/bin/agent-baby-names" --host claude 2>/dev/null)"
  [[ -n "$title" ]] || return 0
  # Git Bash on Windows would turn a title that looks like a path into a Windows path for a native jq.exe.
  MSYS2_ARG_CONV_EXCL="*" jq -cn --arg title "$title" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $title}}'
}

main
exit 0
