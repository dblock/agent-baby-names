#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/emoji/strategy.sh"
  printf 'hello-world 🧪\n' >"$tmp/pins.txt"
  # A fake model that records each question and answers with EMOJI.
  script "$tmp/ask" <<'ASK'
#!/bin/bash
echo "$(cat)" >>"$STUB_LOG"
echo "${EMOJI:-🦀}"
ASK
  options="$(jq -cn --arg pins "$tmp/pins.txt" --arg cache "$tmp/strategy-cache" --arg ask "$tmp/ask" \
    '{pins: $pins, cache: $cache, ask: $ask}')"
}

name() {
  jq -cn --arg name "$1" '{prompt: "x", cwd: "/", host: "claude", name: $name}' |
    AGENT_BABY_NAMES_OPTIONS="${2:-$options}" "$strategy"
}

asked() {
  grep -c '' "$STUB_LOG" | tr -d ' '
}

@test "a pinned emoji skips the model" {
  [ "$(name hello-world)" = "🧪 hello-world" ]
  [ "$(asked)" = 0 ]
}

@test "the model picks an emoji, which is cached by the slugged name" {
  [ "$(name "Loud Fan")" = "🦀 Loud Fan" ]
  grep -qxF 'Reply with one emoji that fits a coding session named "Loud Fan". Output only the emoji.' "$STUB_LOG"
  [ "$(cat "$tmp/strategy-cache/emojis.txt")" = "loud-fan 🦀" ]
  : >"$STUB_LOG"
  [ "$(EMOJI=🐢 name loud-fan)" = "🦀 loud-fan" ]
  [ "$(asked)" = 0 ]
}

@test "an invalid model emoji falls back and is not cached" {
  [ "$(EMOJI="not an emoji" name gizmo)" = "💬 gizmo" ]
  [ ! -s "$tmp/strategy-cache/emojis.txt" ]
}

@test "a name without letters or digits is not cached" {
  [ "$(name "!!!")" = "🦀 !!!" ]
  [ ! -s "$tmp/strategy-cache/emojis.txt" ]
}

@test "names nothing without a name" {
  [ "$(name "")" = "" ]
  [ "$(asked)" = 0 ]
}

@test "ask none gives the default emoji" {
  [ "$(name gizmo "$(jq -c '.ask = "none"' <<<"$options")")" = "💬 gizmo" ]
}

@test "position right puts the emoji after the name" {
  [ "$(name hello-world "$(jq -c '.position = "right"' <<<"$options")")" = "hello-world 🧪" ]
}

@test "position left, or an unknown position, puts the emoji before the name" {
  [ "$(name hello-world "$(jq -c '.position = "left"' <<<"$options")")" = "🧪 hello-world" ]
  [ "$(name hello-world "$(jq -c '.position = "middle"' <<<"$options")")" = "🧪 hello-world" ]
}

@test "the bundled pins and the XDG cache apply by default" {
  [ "$(name dotfiles "{\"ask\": \"$tmp/ask\"}")" = "🏠 dotfiles" ]
  [ "$(name gizmo "{\"ask\": \"$tmp/ask\"}")" = "🦀 gizmo" ]
  grep -qxF "gizmo 🦀" "$XDG_CACHE_HOME/agent-baby-names/emojis.txt"
}
