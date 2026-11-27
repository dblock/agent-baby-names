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
  options="$(jq -cn --arg root "$src" --arg cache "$tmp/strategy-cache" '{root: $root, cache: $cache}')"
}

name() {
  jq -cn --arg prompt "$1" --arg cwd "${2:-$tmp}" --arg name "${4:-}" \
    '{prompt: $prompt, cwd: $cwd, host: "claude", name: $name}' | AGENT_BABY_NAMES_OPTIONS="${3:-$options}" "$strategy"
}

@test "lists each checkout once, named after its remote" {
  name "" >/dev/null
  [ "$(cat "$tmp/strategy-cache/git-clones.txt")" = "$(printf '%s\n' excalc excalc-rs g mongoid_fulltext \
    mongoid_orderable testlanes)" ]
}

@test "a checkout in the prompt, ignoring case" {
  [ "$(name "let's improve TestLanes.")" = "testlanes" ]
}

@test "the longest matching checkout" {
  [ "$(name "port excalc to excalc-rs")" = "excalc-rs" ]
}

@test "a checkout in an organization folder, hyphenated" {
  [ "$(name "fix mongoid_fulltext search")" = "mongoid-fulltext" ]
}

@test "folder names of checkouts with a remote are not repositories" {
  [ "$(name "work on implementation")" = "" ]
  [ "$(name "merge upstream-mongoid_fulltext")" = "" ]
}

@test "an upstream remote names a checkout without an origin" {
  clone "$src/renamed"
  git -C "$src/renamed" remote add upstream https://github.com/dblock/real-name/
  [ "$(name "fix real-name")" = "real-name" ]
}

@test "checkouts deeper than three folders or inside a checkout are not listed" {
  clone "$src/a/b/c/deep"
  clone "$src/excalc/vendor/inner"
  name "" >/dev/null
  run ! grep -qxE 'deep|inner' "$tmp/strategy-cache/git-clones.txt"
}

@test "names shorter than three characters are ignored" {
  [ "$(name "g is great")" = "" ]
}

@test "the checkout that holds the working directory" {
  mkdir -p "$src/testlanes/implementation/lib"
  [ "$(name "fix the build" "$src/testlanes/implementation/lib")" = "testlanes" ]
}

@test "a working directory checkout outside the root" {
  clone "$tmp/elsewhere" git@github.com:someone/elsewhere.git
  [ "$(name "fix the build" "$tmp/elsewhere")" = "elsewhere" ]
}

@test "a working directory that is missing or outside a checkout names nothing" {
  [ "$(name "fix the build" "$tmp/missing")" = "" ]
  [ "$(name "fix the build" "")" = "" ]
}

@test "a prompt repository wins over the working directory" {
  [ "$(name "update excalc" "$src/testlanes/master")" = "excalc" ]
}

@test "keeps a name it is given" {
  [ "$(name "update excalc" "$src/testlanes/master" "$options" "given")" = "" ]
  [ ! -e "$tmp/strategy-cache/git-clones.txt" ]
}

@test "the list is rebuilt when the root changes" {
  name "update excalc" >/dev/null
  touch -t 202001010000 "$tmp/strategy-cache/git-clones.txt"
  clone "$src/newproject"
  [ "$(name "start newproject")" = "newproject" ]
}

@test "the list is rebuilt after a day" {
  name "update excalc" >/dev/null
  clone "$src/later"
  touch -t 202001010000 "$src"
  [ "$(name "start later")" = "" ]
  touch -t 202001010000 "$src"
  touch -t "$(date -v-2d +%Y%m%d%H%M 2>/dev/null || date -d '2 days ago' +%Y%m%d%H%M)" "$tmp/strategy-cache/git-clones.txt"
  [ "$(name "start later")" = "later" ]
}

@test "defaults to ~/source and the XDG cache" {
  clone "$HOME/source/babynames"
  [ "$(name "name babynames" / "{}")" = "babynames" ]
  [ -s "$XDG_CACHE_HOME/agent-baby-names/git-clones.txt" ]
}

@test "expands ~ in folder options" {
  clone "$HOME/code/babynames"
  [ "$(name "name babynames" / '{"root": "~/code/", "cache": "~/cache"}')" = "babynames" ]
  [ -s "$HOME/cache/git-clones.txt" ]
}

@test "a missing root names nothing" {
  [ "$(name "update excalc" / "$(jq -c ".root = \"$tmp/missing\"" <<<"$options")")" = "" ]
}
