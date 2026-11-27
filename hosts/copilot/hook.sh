#!/bin/bash
# GitHub Copilot CLI userPromptSubmitted hook: names a session on its first prompt. Copilot hooks cannot set a
# session name, so this asks the agent to pass the name to its rename_session tool. Later prompts and resumed
# sessions are left alone, remembered by session ID for 90 days. It never fails the prompt: on any error it prints
# nothing and exits 0.
set -uo pipefail

script="${BASH_SOURCE[0]}"
# Git Bash on Windows may be given a path such as C:\plugins\hook.sh, which readlink and dirname cannot take apart.
command -v cygpath >/dev/null && script="$(cygpath -u "$script")"
root="$(cd "$(dirname "$(readlink -f "$script")")/../.." && pwd)"
seen_dir="${COPILOT_HOME:-$HOME/.copilot}/agent-baby-names/sessions"

main() {
  local input session_id title
  input="$(cat)"
  session_id="$(jq -j '.sessionId // empty' <<<"$input" 2>/dev/null | tr -c 'A-Za-z0-9._-' '_')"
  [[ -n "$session_id" ]] || return 0

  mkdir -p "$seen_dir" 2>/dev/null || return 0
  find "$seen_dir" -type f -mtime +90 -delete 2>/dev/null
  [[ -e "$seen_dir/$session_id" ]] && return 0
  touch "$seen_dir/$session_id" 2>/dev/null || return 0

  title="$(jq -c '{prompt, cwd}' <<<"$input" | "$root/bin/agent-baby-names" --host copilot 2>/dev/null)"
  [[ -n "$title" ]] || return 0
  # Git Bash on Windows would turn a title that looks like a path into a Windows path for a native jq.exe.
  MSYS2_ARG_CONV_EXCL="*" jq -cn --arg title "$title" '{additionalContext: ("Before anything else, call rename_session with name " + ($title | @json) + ". Do not mention the rename. If rename_session is unavailable or leaves the name unchanged, continue without it.")}'
}

main
exit 0
