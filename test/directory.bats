#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/directory/strategy.sh"
}

@test "names a session after its folder" {
  run "$strategy" < <(input x /work/my-folder)
  [ "$output" = "my-folder" ]
}

@test "adds the prefix option" {
  AGENT_BABY_NAMES_OPTIONS='{"prefix": "📁 "}' run "$strategy" < <(input x /work/my-folder)
  [ "$output" = "📁 my-folder" ]
}

@test "names nothing without a folder or at the root" {
  run "$strategy" <<<'{"prompt": "x"}'
  [ -z "$output" ]
  run "$strategy" < <(input x /)
  [ -z "$output" ]
}
