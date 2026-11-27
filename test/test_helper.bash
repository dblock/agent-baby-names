# shellcheck shell=bash disable=SC2034 # The tests that source this file use its variables.
# Shared setup: every test runs with a temporary home, cache, configuration, and Copilot home, so it never reads the
# user's own files, and with stub claude and copilot commands first on PATH, so it never calls a real model.

bats_require_minimum_version 1.5.0

common_setup() {
  root="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  bin="$root/bin/agent-baby-names"
  tmp="$BATS_TEST_TMPDIR"
  export HOME="$tmp/home"
  export XDG_CONFIG_HOME="$tmp/config"
  export XDG_CACHE_HOME="$tmp/cache"
  export COPILOT_HOME="$tmp/copilot"
  export AGENT_BABY_NAMES_CONFIG="$tmp/config.json"
  unset AGENT_BABY_NAMES_NESTED AGENT_BABY_NAMES_OPTIONS AGENT_BABY_NAMES_HOST AGENT_BABY_NAMES_ROOT
  unset AGENT_BABY_NAMES_CACHE AGENT_BABY_NAMES_CLAUDE_MODEL AGENT_BABY_NAMES_COPILOT_MODEL
  mkdir -p "$HOME" "$tmp/stubs"
  export PATH="$tmp/stubs:$PATH"
  export STUB_LOG="$tmp/stub.log"
  : >"$STUB_LOG"
}

# Writes the configuration file from JSON.
config() {
  printf '%s\n' "$1" >"$AGENT_BABY_NAMES_CONFIG"
}

# Writes an executable script from standard input.
script() {
  cat >"$1"
  chmod +x "$1"
}

# Prints {"prompt", "cwd"} JSON.
input() {
  jq -cn --arg prompt "$1" --arg cwd "${2:-/}" '{prompt: $prompt, cwd: $cwd}'
}
