#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  # A strategy that records what it receives and answers with NAME.
  script "$tmp/record.sh" <<'STRATEGY'
#!/bin/bash
{
  echo "input=$(cat)"
  echo "options=$AGENT_BABY_NAMES_OPTIONS"
  echo "host=$AGENT_BABY_NAMES_HOST"
  echo "root=$AGENT_BABY_NAMES_ROOT"
} >>"$STUB_LOG"
printf '%b' "${NAME:-}"
exit "${STATUS:-0}"
STRATEGY
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

@test "--host needs a value" {
  run --separate-stderr "$bin" --host
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: --host needs a value." ]
}

@test "the manifests and the script share one version" {
  version="$("$bin" --version | cut -d' ' -f2)"
  [ "$(jq -r .version "$root/.claude-plugin/plugin.json")" = "$version" ]
  [ "$(jq -r '.plugins[0].version' "$root/.claude-plugin/marketplace.json")" = "$version" ]
  [ "$(jq -r .version "$root/.github/plugin/plugin.json")" = "$version" ]
}

@test "runs a strategy given by path with its options, the input, and the host" {
  config "{\"strategy\": \"$tmp/record.sh\", \"strategies\": {\"$tmp/record.sh\": {\"greeting\": \"hi\"}}}"
  NAME='🍼 baby' run "$bin" --host claude < <(input "hello there" /work)
  [ "$status" -eq 0 ]
  [ "$output" = "🍼 baby" ]
  grep -qxF 'input={"prompt":"hello there","cwd":"/work","host":"claude"}' "$STUB_LOG"
  grep -qxF 'options={"greeting":"hi"}' "$STUB_LOG"
  grep -qxF 'host=claude' "$STUB_LOG"
  grep -qxF "root=$root" "$STUB_LOG"
}

@test "expands ~ in a strategy path" {
  cp "$tmp/record.sh" "$HOME/mine.sh"
  config '{"strategy": "~/mine.sh"}'
  NAME='mine' run "$bin" < <(input x)
  [ "$output" = "mine" ]
  grep -qxF 'options={}' "$STUB_LOG"
  grep -qxF 'input={"prompt":"x","cwd":"/","host":""}' "$STUB_LOG"
}

@test "prints only the first line of the name, trimmed" {
  config "{\"strategy\": \"$tmp/record.sh\"}"
  NAME='  first name  \nsecond' run "$bin" < <(input x)
  [ "$output" = "first name" ]
}

@test "prints nothing when the strategy names nothing" {
  config "{\"strategy\": \"$tmp/record.sh\"}"
  NAME='  \n' run "$bin" < <(input x)
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fails when the strategy fails" {
  config "{\"strategy\": \"$tmp/record.sh\"}"
  NAME='ignored' STATUS=3 run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "agent-baby-names: Strategy \"$tmp/record.sh\" failed with status 3." ]
}

@test "uses git-clones without a configuration file" {
  clone "$HOME/source/babynames"
  run "$bin" < <(input "name the babynames project")
  [ "$status" -eq 0 ]
  [ "$output" = "🗂️ babynames" ]
}

@test "reads the configuration from the XDG config folder" {
  unset AGENT_BABY_NAMES_CONFIG
  mkdir -p "$XDG_CONFIG_HOME/agent-baby-names"
  echo '{"strategy": "directory"}' >"$XDG_CONFIG_HOME/agent-baby-names/config.json"
  run "$bin" < <(input x /work/my-folder)
  [ "$output" = "my-folder" ]
}

@test "reads the configuration from ~/.config without XDG_CONFIG_HOME" {
  unset AGENT_BABY_NAMES_CONFIG XDG_CONFIG_HOME
  mkdir -p "$HOME/.config/agent-baby-names"
  echo '{"strategy": "directory"}' >"$HOME/.config/agent-baby-names/config.json"
  run "$bin" < <(input x /work/my-folder)
  [ "$output" = "my-folder" ]
}

@test "runs a bundled strategy by name" {
  config '{"strategy": "directory", "strategies": {"directory": {"prefix": "👶 "}}}'
  run "$bin" < <(input x /work/my-folder)
  [ "$output" = "👶 my-folder" ]
}

@test "fails on an unknown strategy" {
  config '{"strategy": "nope"}'
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ "$stderr" = 'agent-baby-names: Unknown strategy "nope".' ]
}

@test "does not treat a strategy name as a path" {
  config '{"strategy": "../bin"}'
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ "$stderr" = 'agent-baby-names: Unknown strategy "../bin".' ]
  config '{"strategy": "Directory"}'
  run --separate-stderr "$bin" < <(input x)
  [ "$stderr" = 'agent-baby-names: Unknown strategy "Directory".' ]
}

@test "fails on a strategy path that is not executable" {
  touch "$tmp/plain.sh"
  config "{\"strategy\": \"$tmp/plain.sh\"}"
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: Unknown strategy \"$tmp/plain.sh\"." ]
}

@test "fails on a configuration that is not a JSON object" {
  config '["git-clones"]'
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: $AGENT_BABY_NAMES_CONFIG is not a JSON object." ]
  config '{ nope'
  run --separate-stderr "$bin" < <(input x)
  [ "$stderr" = "agent-baby-names: $AGENT_BABY_NAMES_CONFIG is not a JSON object." ]
}

@test "fails on strategy options that are not an object" {
  config '{"strategy": "directory", "strategies": {"directory": "nope"}}'
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: The options of strategy \"directory\" in $AGENT_BABY_NAMES_CONFIG must be an object." ]
  config '{"strategies": ["nope"]}'
  run --separate-stderr "$bin" < <(input x)
  [ "$status" -eq 1 ]
}

@test "fails on input that is not a JSON object" {
  run --separate-stderr "$bin" <<<"not json"
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: The input must be a JSON object." ]
  run --separate-stderr "$bin" <<<"42"
  [ "$stderr" = "agent-baby-names: The input must be a JSON object." ]
}

@test "a nested call names nothing" {
  config "{\"strategy\": \"$tmp/record.sh\"}"
  NAME='baby' AGENT_BABY_NAMES_NESTED=1 run "$bin" < <(input x)
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -s "$STUB_LOG" ]
}

@test "fails without jq" {
  mkdir -p "$tmp/nojq"
  ln -s "$(command -v bash)" "$tmp/nojq/bash"
  for tool in dirname readlink; do ln -s "$(command -v "$tool")" "$tmp/nojq/$tool"; done
  run --separate-stderr env PATH="$tmp/nojq" "$tmp/nojq/bash" "$bin" <<<'{}'
  [ "$status" -eq 1 ]
  [ "$stderr" = "agent-baby-names: jq is required." ]
}
