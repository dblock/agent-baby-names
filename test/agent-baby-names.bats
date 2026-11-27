#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  bin="$root/bin/agent-baby-names"
}

@test "--version prints the version" {
  run "$bin" --version
  [ "$status" -eq 0 ]
  [ "$output" = "agent-baby-names 0.1.0" ]
}

@test "--help prints usage" {
  run "$bin" --help
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: agent-baby-names"* ]]
}

@test "an unknown argument prints usage to stderr and fails" {
  run --separate-stderr "$bin" --nope
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == "Usage: agent-baby-names"* ]]
}

@test "the manifests and the script share one version" {
  version="$("$bin" --version | cut -d' ' -f2)"
  [ "$(jq -r .version "$root/.claude-plugin/plugin.json")" = "$version" ]
  [ "$(jq -r '.plugins[0].version' "$root/.claude-plugin/marketplace.json")" = "$version" ]
  [ "$(jq -r .version "$root/.github/plugin/plugin.json")" = "$version" ]
}
