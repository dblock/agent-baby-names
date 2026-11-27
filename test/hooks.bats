#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  claude_hook="$root/hosts/claude/hook.sh"
  copilot_hook="$root/hosts/copilot/hook.sh"
  # A strategy that records its input and answers with NAME.
  script "$tmp/record.sh" <<'STRATEGY'
#!/bin/bash
echo "input=$(cat)" >>"$STUB_LOG"
printf '%s' "${NAME:-}"
exit "${STATUS:-0}"
STRATEGY
  config "{\"strategy\": \"$tmp/record.sh\"}"
}

claude() {
  "$claude_hook" <<<"$1"
}

copilot() {
  jq -cn --arg s "$1" --arg p "$2" '{sessionId: $s, timestamp: 1, cwd: "/work", prompt: $p}' | "$copilot_hook"
}

@test "Claude Code: sets the title of an untitled session" {
  out="$(NAME='🧪 testlanes' claude '{"session_id": "s1", "prompt": "speed up the testlanes CI", "cwd": "/work"}')"
  [ "$out" = '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"🧪 testlanes"}}' ]
  grep -qxF 'input={"prompt":"speed up the testlanes CI","cwd":"/work","host":"claude","name":""}' "$STUB_LOG"
}

@test "Claude Code: keeps an existing title" {
  [ -z "$(NAME='🧪 testlanes' claude '{"prompt": "improve testlanes", "cwd": "/", "session_title": "mine"}')" ]
  [ ! -s "$STUB_LOG" ]
}

@test "Claude Code: names a session whose title is empty" {
  [ -n "$(NAME='🧪 testlanes' claude '{"prompt": "x", "cwd": "/", "session_title": ""}')" ]
}

@test "Claude Code: encodes quotes in the title" {
  out="$(NAME='💬 say "hi"' claude '{"prompt": "x", "cwd": "/"}')"
  [ "$(jq -r .hookSpecificOutput.sessionTitle <<<"$out")" = '💬 say "hi"' ]
}

@test "Claude Code: stays quiet without a name, on errors, and on invalid input" {
  run claude '{"prompt": "hello", "cwd": "/"}'
  [ "$status" -eq 0 ] && [ -z "$output" ]
  NAME='x' STATUS=1 run claude '{"prompt": "hello", "cwd": "/"}'
  [ "$status" -eq 0 ] && [ -z "$output" ]
  config '{"strategy": "nope"}'
  run --separate-stderr claude '{"prompt": "hello", "cwd": "/"}'
  [ "$status" -eq 0 ] && [ -z "$output" ] && [ -z "$stderr" ]
  run claude 'not json'
  [ "$status" -eq 0 ] && [ -z "$output" ]
  run claude '[]'
  [ "$status" -eq 0 ] && [ -z "$output" ]
}

@test "Copilot CLI: asks the agent to rename a new session" {
  out="$(NAME='🧪 testlanes' copilot s1 'speed up the testlanes CI')"
  [ "$(jq -r .additionalContext <<<"$out")" = 'Before anything else, call rename_session with name "🧪 testlanes". Do not mention the rename. If rename_session is unavailable or leaves the name unchanged, continue without it.' ]
  grep -qxF 'input={"prompt":"speed up the testlanes CI","cwd":"/work","host":"copilot","name":""}' "$STUB_LOG"
}

@test "Copilot CLI: leaves later prompts alone" {
  NAME='🧪 testlanes' copilot s1 'first' >/dev/null
  [ -z "$(NAME='🧪 testlanes' copilot s1 'and the lint job')" ]
  [ "$(grep -c '^input=' "$STUB_LOG" | tr -d ' ')" = 1 ]
}

@test "Copilot CLI: forgets sessions after 90 days" {
  mkdir -p "$COPILOT_HOME/agent-baby-names/sessions"
  touch -t 202001010000 "$COPILOT_HOME/agent-baby-names/sessions/old"
  NAME='🧪 testlanes' copilot s1 'x' >/dev/null
  [ ! -e "$COPILOT_HOME/agent-baby-names/sessions/old" ]
  [ -e "$COPILOT_HOME/agent-baby-names/sessions/s1" ]
}

@test "Copilot CLI: encodes quotes in the name" {
  out="$(NAME='💬 say "hi"' copilot s2 'x')"
  [ "$(jq -r .additionalContext <<<"$out" | cut -d. -f1)" = 'Before anything else, call rename_session with name "💬 say \"hi\""' ]
}

@test "Copilot CLI: stays quiet without a name, a session ID, or valid input" {
  run copilot s3 'hello'
  [ "$status" -eq 0 ] && [ -z "$output" ]
  NAME='🏠 dotfiles' run "$copilot_hook" <<<'{"prompt": "x", "cwd": "/"}'
  [ "$status" -eq 0 ] && [ -z "$output" ]
  run --separate-stderr "$copilot_hook" <<<'not json'
  [ "$status" -eq 0 ] && [ -z "$output" ] && [ -z "$stderr" ]
}

@test "Copilot CLI: keeps session IDs inside its folder" {
  NAME='🏠 dotfiles' copilot '../escape' 'x' >/dev/null
  [ -f "$COPILOT_HOME/agent-baby-names/sessions/.._escape" ]
  [ ! -e "$COPILOT_HOME/agent-baby-names/escape" ]
}

@test "Copilot CLI: stays quiet when its folder cannot be created" {
  touch "$COPILOT_HOME"
  run --separate-stderr copilot s4 'x'
  [ "$status" -eq 0 ] && [ -z "$output" ] && [ -z "$stderr" ]
}

@test "the Claude Code hook registration runs the Claude Code hook" {
  command="$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' "$root/hooks/hooks.json")"
  # shellcheck disable=SC2016 # The registration names the variable literally.
  [ "$command" = '"${CLAUDE_PLUGIN_ROOT}/hosts/claude/hook.sh"' ]
  out="$(NAME='🍼 baby' CLAUDE_PLUGIN_ROOT="$root" bash -c "$command" <<<'{"prompt": "x", "cwd": "/"}')"
  [ "$(jq -r .hookSpecificOutput.sessionTitle <<<"$out")" = "🍼 baby" ]
}

@test "the Copilot CLI hook registration runs the Copilot CLI hook" {
  file="$root/$(jq -r .hooks "$root/.github/plugin/plugin.json")"
  hook="$(jq -c '.hooks.userPromptSubmitted[0]' "$file")"
  # shellcheck disable=SC2016 # The registration names the variable literally.
  [ "$(jq -r '.env.AGENT_BABY_NAMES_PLUGIN_ROOT' <<<"$hook")" = '${PLUGIN_ROOT}' ]
  out="$(NAME='🍼 baby' AGENT_BABY_NAMES_PLUGIN_ROOT="$root" bash -c "$(jq -r .bash <<<"$hook")" \
    <<<'{"sessionId": "s5", "prompt": "x", "cwd": "/"}')"
  [[ "$(jq -r .additionalContext <<<"$out")" == *'"🍼 baby"'* ]]
}
