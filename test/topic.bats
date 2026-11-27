#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/topic/strategy.sh"
  # A fake model that records each question and answers with TITLE.
  script "$tmp/ask" <<'ASK'
#!/bin/bash
echo "nested=${AGENT_BABY_NAMES_NESTED:-} pwd=$PWD :: $(cat)" >>"$STUB_LOG"
printf '%b\n' "${TITLE-Loud Laptop Fan}"
ASK
  options="$(jq -cn --arg cache "$tmp/strategy-cache" --arg ask "$tmp/ask" '{cache: $cache, ask: $ask}')"
}

name() {
  jq -cn --arg prompt "$1" --arg name "${3:-}" '{prompt: $prompt, cwd: "/", host: "claude", name: $name}' |
    AGENT_BABY_NAMES_OPTIONS="${2:-$options}" "$strategy"
}

asked() {
  grep -c "${1:-}" "$STUB_LOG" | tr -d ' '
}

@test "the model writes a slugged topic" {
  [ "$(name "why is my laptop fan loud")" = "loud-laptop-fan" ]
  grep -qF 'Write a session title for this request: "why is my laptop fan loud".' "$STUB_LOG"
}

@test "only the first line of the reply, without an emoji or punctuation" {
  [ "$(TITLE='🔊 Loud, laptop fan!\nmore' name "why is it loud")" = "loud-laptop-fan" ]
}

@test "the model is asked in the cache folder and marked nested" {
  name "why is my laptop fan loud" >/dev/null
  [ "$(asked "^nested=1 pwd=$tmp/strategy-cache ::")" = 1 ]
}

@test "a long prompt is cut to 1000 characters for the model" {
  name "$(printf 'a%.0s' {1..1200})" >/dev/null
  grep -qF "\"$(printf 'a%.0s' {1..1000})\"." "$STUB_LOG"
}

@test "keeps a name it is given" {
  [ "$(name "why is it loud" "$options" given)" = "" ]
  [ "$(asked)" = 0 ]
}

@test "an empty prompt names nothing" {
  [ "$(name "")" = "" ]
  [ "$(asked)" = 0 ]
}

@test "a reply without words names nothing" {
  [ "$(TITLE='🔊 !!!' name "why is it loud")" = "" ]
}

@test "ask none names nothing" {
  [ "$(name "hello there" "$(jq -c '.ask = "none"' <<<"$options")")" = "" ]
  [ "$(asked)" = 0 ]
}

@test "auto asks the host with the configured model" {
  script "$tmp/stubs/claude" <<'STUB'
#!/bin/bash
echo "claude $*" >>"$STUB_LOG"
echo "loud-fan"
STUB
  models="$(jq -c '.ask = "auto" | .claude_model = "sonnet"' <<<"$options")"
  [ "$(AGENT_BABY_NAMES_HOST=claude name "why is it loud" "$models")" = "loud-fan" ]
  grep -q '^claude -p --model sonnet ' "$STUB_LOG"
}
