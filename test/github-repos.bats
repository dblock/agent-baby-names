#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/github-repos/strategy.sh"
  # A fake gh that records each call and lists repositories of the viewer or of the mongoid organization.
  script "$tmp/stubs/gh" <<'GH'
#!/bin/bash
echo "gh $*" >>"$STUB_LOG"
[[ -z "${GH_FAIL:-}" ]] || { echo "gh: not logged in" >&2; exit 1; }
case "$3" in
  mongoid) printf '%s\n' mongoid_fulltext mongoid_orderable ;;
  *) printf '%s\n' testlanes excalc-rs testlanes ;;
esac
GH
  options="$(jq -cn --arg cache "$tmp/strategy-cache" '{cache: $cache}')"
}

name() {
  jq -cn --arg prompt "$1" --arg cwd "${2:-$tmp}" --arg name "${4:-}" \
    '{prompt: $prompt, cwd: $cwd, host: "claude", name: $name}' | AGENT_BABY_NAMES_OPTIONS="${3:-$options}" "$strategy"
}

calls() {
  grep -c '^gh ' "$STUB_LOG" | tr -d ' '
}

@test "a repository of yours in the prompt" {
  [ "$(name "speed up the testlanes CI")" = "testlanes" ]
  grep -qxF 'gh repo list --limit 1000 --json name --jq .[].name' "$STUB_LOG"
  [ "$(cat "$tmp/strategy-cache/github-repos.txt")" = "$(printf '%s\n' excalc-rs testlanes)" ]
}

@test "the list is cached for a day" {
  name "fix excalc-rs" >/dev/null
  [ "$(name "fix excalc-rs")" = "excalc-rs" ]
  [ "$(calls)" = 1 ]
  touch -t "$(date -v-2d +%Y%m%d%H%M 2>/dev/null || date -d '2 days ago' +%Y%m%d%H%M)" \
    "$tmp/strategy-cache/github-repos.txt"
  name "fix excalc-rs" >/dev/null
  [ "$(calls)" = 2 ]
}

@test "owners add organization repositories, in their own cache" {
  name "fix testlanes" >/dev/null
  owners="$(jq -c '.owners = ["mongoid", "not valid"]' <<<"$options")"
  [ "$(name "fix mongoid_fulltext" / "$owners")" = "mongoid-fulltext" ]
  grep -qxF 'gh repo list mongoid --limit 1000 --json name --jq .[].name' "$STUB_LOG"
  [ "$(calls)" = 3 ]
  [ -s "$tmp/strategy-cache/github-repos-mongoid.txt" ]
}

@test "one owner may be a string" {
  [ "$(name "fix mongoid_orderable" / "$(jq -c '.owners = "mongoid"' <<<"$options")")" = "mongoid-orderable" ]
}

@test "keeps a name it is given without calling gh" {
  [ "$(name "fix testlanes" / "$options" "given")" = "" ]
  [ "$(calls)" = 0 ]
}

@test "a failing gh names from the working directory or nothing, and keeps the old list" {
  clone "$tmp/checkout" https://github.com/dblock/checkout.git
  [ "$(GH_FAIL=1 name "fix testlanes" "$tmp/checkout")" = "checkout" ]
  [ "$(GH_FAIL=1 name "fix testlanes")" = "" ]
  [ ! -e "$tmp/strategy-cache/github-repos.txt" ]
  name "fix testlanes" >/dev/null
  touch -t 202001010000 "$tmp/strategy-cache/github-repos.txt"
  [ "$(GH_FAIL=1 name "fix testlanes")" = "testlanes" ]
  [ "$(cd "$tmp/strategy-cache" && echo *)" = "github-repos.txt" ]
}
