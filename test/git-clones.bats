#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/git-clones/strategy.sh"
  src="$tmp/source"
  clone "$src/testlanes/master" git@github.com:dblock/testlanes.git
  git -C "$src/testlanes/master" -c user.name=Test -c user.email=test@example.com commit -q --allow-empty -m Start
  git -C "$src/testlanes/master" worktree add -q -b topic "$src/testlanes/implementation"
  clone "$src/testlanes/dblock-testlanes" https://github.com/dblock/testlanes
  clone "$src/excalc"
  clone "$src/excalc-rs" https://github.com/dblock/excalc-rs.git
  clone "$src/mongoid/mongoid_fulltext/upstream-mongoid_fulltext" https://github.com/mongoid/mongoid_fulltext.git
  clone "$src/mongoid/mongoid_orderable" https://github.com/mongoid/mongoid_orderable.git
  clone "$src/g"
  printf 'testlanes 🧪\n' >"$tmp/pins.txt"
  # A fake model that records each question, answering emoji questions with 🦀 and title requests with a title.
  script "$tmp/ask" <<'ASK'
#!/bin/bash
question="$(cat)"
echo "nested=${AGENT_BABY_NAMES_NESTED:-} pwd=$PWD :: $question" >>"$STUB_LOG"
case "$question" in
  *"one emoji"*) echo "${EMOJI:-🦀}" ;;
  *) echo "${TITLE:-🔊 Loud Laptop Fan}" ;;
esac
ASK
  options="$(jq -cn --arg root "$src" --arg pins "$tmp/pins.txt" --arg cache "$tmp/strategy-cache" \
    --arg ask "$tmp/ask" '{root: $root, pins: $pins, cache: $cache, ask: $ask}')"
}

name() {
  jq -cn --arg prompt "$1" --arg cwd "${2:-$tmp}" '{prompt: $prompt, cwd: $cwd, host: "claude"}' |
    AGENT_BABY_NAMES_OPTIONS="${3:-$options}" "$strategy"
}

asked() {
  grep -c "${1:-}" "$STUB_LOG" | tr -d ' '
}

@test "lists each checkout once, named after its remote" {
  name "" >/dev/null
  [ "$(cat "$tmp/strategy-cache/git-clones.txt")" = "$(printf '%s\n' excalc excalc-rs g mongoid_fulltext \
    mongoid_orderable testlanes)" ]
}

@test "a pinned checkout in the prompt" {
  [ "$(name "let's improve TestLanes.")" = "🧪 testlanes" ]
  [ "$(asked)" = 0 ]
}

@test "the longest matching checkout" {
  [ "$(name "port excalc to excalc-rs")" = "🦀 excalc-rs" ]
}

@test "a checkout in an organization folder, hyphenated" {
  [ "$(name "fix mongoid_fulltext search")" = "🦀 mongoid-fulltext" ]
}

@test "folder names of checkouts with a remote are not repositories" {
  [ "$(name "work on implementation")" = "🔊 loud-laptop-fan" ]
  [ "$(name "merge upstream-mongoid_fulltext")" = "🔊 loud-laptop-fan" ]
}

@test "an upstream remote names a checkout without an origin" {
  clone "$src/renamed"
  git -C "$src/renamed" remote add upstream https://github.com/dblock/real-name/
  [ "$(name "fix real-name")" = "🦀 real-name" ]
}

@test "checkouts deeper than three folders or inside a checkout are not listed" {
  clone "$src/a/b/c/deep"
  clone "$src/excalc/vendor/inner"
  name "" >/dev/null
  run ! grep -qxE 'deep|inner' "$tmp/strategy-cache/git-clones.txt"
}

@test "names shorter than three characters are ignored" {
  [ "$(name "g is great")" = "🔊 loud-laptop-fan" ]
}

@test "the checkout that holds the working directory" {
  mkdir -p "$src/testlanes/implementation/lib"
  [ "$(name "fix the build" "$src/testlanes/implementation/lib")" = "🧪 testlanes" ]
}

@test "a working directory checkout outside the root" {
  clone "$tmp/elsewhere" git@github.com:someone/elsewhere.git
  [ "$(name "fix the build" "$tmp/elsewhere")" = "🦀 elsewhere" ]
}

@test "a working directory that is missing or outside a checkout gets a topic" {
  [ "$(name "fix the build" "$tmp/missing")" = "🔊 loud-laptop-fan" ]
  [ "$(name "fix the build" "")" = "🔊 loud-laptop-fan" ]
}

@test "a prompt repository wins over the working directory" {
  [ "$(name "update excalc" "$src/testlanes/master")" = "🦀 excalc" ]
}

@test "a cached emoji skips the model" {
  name "update excalc" >/dev/null
  : >"$STUB_LOG"
  [ "$(name "update excalc")" = "🦀 excalc" ]
  [ "$(asked)" = 0 ]
  [ "$(grep -c '^excalc ' "$tmp/strategy-cache/emojis.txt" | tr -d ' ')" = 1 ]
}

@test "the model writes a slugged topic for other prompts" {
  [ "$(name "why is my laptop fan loud")" = "🔊 loud-laptop-fan" ]
  grep -qF 'Write a session title for this request: "why is my laptop fan loud".' "$STUB_LOG"
}

@test "the model is asked in the cache folder and marked nested" {
  name "port excalc-rs" >/dev/null
  name "why is my laptop fan loud" >/dev/null
  [ "$(asked)" = 2 ]
  [ "$(asked "^nested=1 pwd=$tmp/strategy-cache ::")" = 2 ]
}

@test "a long prompt is cut to 1000 characters for the model" {
  long="$(printf 'a%.0s' {1..1200})"
  name "$long" >/dev/null
  grep -qF "\"$(printf 'a%.0s' {1..1000})\"." "$STUB_LOG"
}

@test "the list is rebuilt when the root changes" {
  name "update excalc" >/dev/null
  touch -t 202001010000 "$tmp/strategy-cache/git-clones.txt"
  clone "$src/newproject"
  [ "$(name "start newproject")" = "🦀 newproject" ]
}

@test "the list is rebuilt after a day" {
  name "update excalc" >/dev/null
  clone "$src/later"
  touch -t 202001010000 "$src"
  [ "$(name "start later")" = "🔊 loud-laptop-fan" ]
  touch -t 202001010000 "$src"
  touch -t "$(date -v-2d +%Y%m%d%H%M 2>/dev/null || date -d '2 days ago' +%Y%m%d%H%M)" "$tmp/strategy-cache/git-clones.txt"
  [ "$(name "start later")" = "🦀 later" ]
}

@test "an invalid model emoji falls back and is not cached" {
  [ "$(EMOJI="not an emoji" name "update excalc")" = "🗂️ excalc" ]
  [ ! -s "$tmp/strategy-cache/emojis.txt" ]
}

@test "an invalid model emoji in a title falls back" {
  [ "$(TITLE="loud laptop fan" name "why is it loud")" = "💬 laptop-fan" ]
}

@test "a model title without a space names nothing" {
  [ "$(TITLE="loud" name "why is it loud")" = "" ]
}

@test "a model title without words names nothing" {
  [ "$(TITLE="🔊 !!!" name "why is it loud")" = "" ]
}

@test "an empty prompt outside a checkout names nothing" {
  [ "$(name "")" = "" ]
  [ "$(asked)" = 0 ]
}

@test "ask none gives no generated title and the default emoji" {
  none="$(jq -c '.ask = "none"' <<<"$options")"
  [ "$(name "hello there" / "$none")" = "" ]
  [ "$(name "start excalc" / "$none")" = "🗂️ excalc" ]
  [ "$(asked)" = 0 ]
}

@test "the bundled pins apply without a pins option" {
  clone "$src/dotfiles" git@github.com:dblock/dotfiles.git
  [ "$(name "fix dotfiles" / "$(jq -c 'del(.pins)' <<<"$options")")" = "🏠 dotfiles" ]
}

@test "defaults to ~/source and the XDG cache" {
  clone "$HOME/source/babynames"
  [ "$(name "name babynames" / "{\"ask\": \"$tmp/ask\"}")" = "🦀 babynames" ]
  grep -qxF "babynames 🦀" "$XDG_CACHE_HOME/agent-baby-names/emojis.txt"
}

@test "expands ~ in folder options" {
  clone "$HOME/code/babynames"
  tilde="$(jq -cn --arg ask "$tmp/ask" '{root: "~/code/", cache: "~/cache", ask: $ask}')"
  [ "$(name "name babynames" / "$tilde")" = "🦀 babynames" ]
  [ -s "$HOME/cache/git-clones.txt" ]
}

@test "a missing root names only from the model" {
  [ "$(name "update excalc" / "$(jq -c ".root = \"$tmp/missing\"" <<<"$options")")" = "🔊 loud-laptop-fan" ]
}

@test "auto asks the host with the configured model" {
  script "$tmp/stubs/claude" <<'STUB'
#!/bin/bash
echo "claude $*" >>"$STUB_LOG"
echo "🦀"
STUB
  models="$(jq -c '.ask = "auto" | .claude_model = "sonnet"' <<<"$options")"
  [ "$(AGENT_BABY_NAMES_HOST=claude name "update excalc" / "$models")" = "🦀 excalc" ]
  grep -q '^claude -p --model sonnet ' "$STUB_LOG"
}
