#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  ask="$root/lib/ask"
  # Stub host commands that record their arguments, working folder, nesting, and question.
  for host in claude copilot; do
    script "$tmp/stubs/$host" <<'STUB'
#!/bin/bash
{
  echo "$(basename "$0") $*"
  echo "pwd=$PWD nested=${AGENT_BABY_NAMES_NESTED:-} copilot_home=${COPILOT_HOME:-}"
  echo "stdin=$(cat)"
} >>"$STUB_LOG"
printf '%b' "${ANSWER-🍼\nmore}"
STUB
  done
}

@test "auto asks Haiku through Claude Code with no hooks, tools, or saved session" {
  AGENT_BABY_NAMES_HOST=claude run "$ask" auto <<<"Which emoji?"
  [ "$status" -eq 0 ]
  [ "$output" = "🍼" ]
  grep -qxF 'claude -p --model haiku --no-session-persistence --settings {"disableAllHooks":true} --tools ' "$STUB_LOG"
  grep -qxF 'stdin=Which emoji?' "$STUB_LOG"
  grep -qxF "pwd=$XDG_CACHE_HOME/agent-baby-names nested=1 copilot_home=$COPILOT_HOME" "$STUB_LOG"
}

@test "auto asks Haiku through Copilot CLI in a throwaway home" {
  AGENT_BABY_NAMES_HOST=copilot run "$ask" auto <<<"Which emoji?"
  [ "$status" -eq 0 ]
  [ "$output" = "🍼" ]
  grep -qxF 'copilot -p Which emoji? -s --model claude-haiku-4.5 --available-tools  --no-custom-instructions --disable-builtin-mcps --no-auto-update' "$STUB_LOG"
  grep -qxF 'stdin=' "$STUB_LOG"
  home="$(sed -nE 's/.*copilot_home=(.*)/\1/p' "$STUB_LOG")"
  [ -n "$home" ] && [ "$home" != "$COPILOT_HOME" ] && [ ! -e "$home" ]
}

@test "the models can be changed" {
  AGENT_BABY_NAMES_HOST=claude AGENT_BABY_NAMES_CLAUDE_MODEL=sonnet run "$ask" auto <<<"q"
  grep -q '^claude -p --model sonnet ' "$STUB_LOG"
  AGENT_BABY_NAMES_HOST=copilot AGENT_BABY_NAMES_COPILOT_MODEL=gpt-5 run "$ask" auto <<<"q"
  grep -q '^copilot -p q -s --model gpt-5 ' "$STUB_LOG"
}

@test "auto is the default" {
  AGENT_BABY_NAMES_HOST=claude run "$ask" <<<"q"
  [ "$output" = "🍼" ]
}

@test "auto without a known host answers nothing" {
  run "$ask" auto <<<"q"
  [ "$status" -eq 1 ]
  AGENT_BABY_NAMES_HOST=other run "$ask" auto <<<"q"
  [ "$status" -eq 1 ]
  [ ! -s "$STUB_LOG" ]
}

@test "none answers nothing" {
  AGENT_BABY_NAMES_HOST=claude run "$ask" none <<<"q"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ ! -s "$STUB_LOG" ]
}

@test "a command reads the question and may take arguments" {
  run "$ask" "tr a-z A-Z | sed 's/^/> /'" <<<"which emoji"
  [ "$status" -eq 0 ]
  [ "$output" = "> WHICH EMOJI" ]
}

@test "a command runs in the cache folder given by AGENT_BABY_NAMES_CACHE" {
  # shellcheck disable=SC2016 # The command expands the variable itself.
  AGENT_BABY_NAMES_CACHE="$tmp/elsewhere" run "$ask" 'pwd; echo "nested=$AGENT_BABY_NAMES_NESTED"' <<<"q"
  [ "$output" = "$tmp/elsewhere" ]
}

@test "an empty or failing answer fails" {
  AGENT_BABY_NAMES_HOST=claude ANSWER='' run "$ask" auto <<<"q"
  [ "$status" -eq 1 ]
  run --separate-stderr "$ask" 'echo oops >&2; exit 2' <<<"q"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ -z "$stderr" ]
}
