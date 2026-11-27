#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/prompt/strategy.sh"
  # A fake model that records each question and answers with REPLY.
  script "$tmp/ask" <<'ASK'
#!/bin/bash
echo "$(cat)" >>"$STUB_LOG"
printf '%b\n' "${REPLY-ticket-42-hello-world}"
ASK
  options="$(jq -cn --arg cache "$tmp/strategy-cache" --arg ask "$tmp/ask" \
    '{cache: $cache, ask: $ask, template: "Rename {name} for {prompt} in {cwd} on {host}."}')"
}

name() {
  jq -cn --arg prompt "$1" --arg name "${3-hello-world}" \
    '{prompt: $prompt, cwd: "/work", host: "claude", name: $name}' |
    AGENT_BABY_NAMES_OPTIONS="${2:-$options}" "$strategy"
}

asked() {
  grep -c '' "$STUB_LOG" | tr -d ' '
}

@test "the template's placeholders become the input, and the answer becomes the name" {
  [ "$(name "fix ticket 42")" = "ticket-42-hello-world" ]
  grep -qxF 'Rename hello-world for fix ticket 42 in /work on claude.' "$STUB_LOG"
}

@test "placeholders inside the prompt are not replaced again, and & is kept" {
  name 'say {name} & {host}' >/dev/null
  grep -qxF 'Rename hello-world for say {name} & {host} in /work on claude.' "$STUB_LOG"
}

@test "only the first 1000 characters of the prompt are asked" {
  name "$(printf 'a%.0s' {1..1200})" >/dev/null
  [ "$(grep -o 'a*' "$STUB_LOG" | awk '{ print length }' | sort -n | tail -1)" = 1000 ]
}

@test "the first line of the answer is trimmed of spaces and quotes, and cut at 80 characters" {
  [ "$(REPLY='  "Hello World"  \nmore' name "x")" = "Hello World" ]
  [ "$(REPLY="\`hello\`" name "x")" = "hello" ]
  [ "$(REPLY="$(printf 'b%.0s' {1..100})" name "x" | awk '{ print length }')" = 80 ]
}

@test "an empty answer keeps the name so far" {
  [ "$(REPLY='' name "x")" = "" ]
}

@test "it runs without a name so far" {
  [ "$(name "fix ticket 42" "$options" "")" = "ticket-42-hello-world" ]
  grep -qxF 'Rename  for fix ticket 42 in /work on claude.' "$STUB_LOG"
}

@test "without a template it asks nothing and keeps the name" {
  [ "$(name "x" "$(jq -c 'del(.template)' <<<"$options")")" = "" ]
  [ ! -s "$STUB_LOG" ]
}

@test "ask none keeps the name" {
  [ "$(name "x" "$(jq -c '.ask = "none"' <<<"$options")")" = "" ]
}
