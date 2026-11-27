#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/github-repos/strategy.sh"
  # A fake gh that records each call and lists repositories of the viewer or of the acme organization.
  script "$tmp/stubs/gh" <<'GH'
#!/bin/bash
echo "gh $*" >>"$STUB_LOG"
[[ -z "${GH_FAIL:-}" ]] || { echo "gh: not logged in" >&2; exit 1; }
case "$3" in
  acme) printf '%s\n' acme_widgets acme_orderable ;;
  *) printf '%s\n' hello-world widget-rs hello-world ;;
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
  [ "$(name "speed up the hello-world CI")" = "hello-world" ]
  grep -qxF 'gh repo list --limit 1000 --json name --jq .[].name' "$STUB_LOG"
  [ "$(cat "$tmp/strategy-cache/github-repos.txt")" = "$(printf '%s\n' hello-world widget-rs)" ]
}

@test "the list is cached for a day" {
  name "fix widget-rs" >/dev/null
  [ "$(name "fix widget-rs")" = "widget-rs" ]
  [ "$(calls)" = 1 ]
  touch -t "$(date -v-2d +%Y%m%d%H%M 2>/dev/null || date -d '2 days ago' +%Y%m%d%H%M)" \
    "$tmp/strategy-cache/github-repos.txt"
  name "fix widget-rs" >/dev/null
  [ "$(calls)" = 2 ]
}

@test "owners add organization repositories, in their own cache" {
  name "fix hello-world" >/dev/null
  owners="$(jq -c '.owners = ["acme", "not valid"]' <<<"$options")"
  [ "$(name "fix acme_widgets" / "$owners")" = "acme-widgets" ]
  grep -qxF 'gh repo list acme --limit 1000 --json name --jq .[].name' "$STUB_LOG"
  [ "$(calls)" = 3 ]
  [ -s "$tmp/strategy-cache/github-repos-acme.txt" ]
}

@test "one owner may be a string" {
  [ "$(name "fix acme_orderable" / "$(jq -c '.owners = "acme"' <<<"$options")")" = "acme-orderable" ]
}

@test "keeps a name it is given without calling gh" {
  [ "$(name "fix hello-world" / "$options" "given")" = "" ]
  [ "$(calls)" = 0 ]
}

@test "a failing gh names from the working directory or nothing, and keeps the old list" {
  clone "$tmp/checkout" https://github.com/octocat/checkout.git
  [ "$(GH_FAIL=1 name "fix hello-world" "$tmp/checkout")" = "checkout" ]
  [ "$(GH_FAIL=1 name "fix hello-world")" = "" ]
  [ ! -e "$tmp/strategy-cache/github-repos.txt" ]
  name "fix hello-world" >/dev/null
  touch -t 202001010000 "$tmp/strategy-cache/github-repos.txt"
  [ "$(GH_FAIL=1 name "fix hello-world")" = "hello-world" ]
  [ "$(cd "$tmp/strategy-cache" && echo *)" = "github-repos.txt" ]
}
