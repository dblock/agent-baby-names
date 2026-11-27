#!/usr/bin/env bats

# shellcheck source=test/test_helper.bash
source "$BATS_TEST_DIRNAME/test_helper.bash"

setup() {
  common_setup
  strategy="$root/strategies/repo/strategy.sh"
}

@test "names a session after the origin of its checkout, from a subfolder" {
  clone "$tmp/foo/dblock-foo" git@github.com:dblock/foo.git
  mkdir -p "$tmp/foo/dblock-foo/lib"
  run "$strategy" < <(input x "$tmp/foo/dblock-foo/lib")
  [ "$output" = "foo" ]
}

@test "names a linked worktree after its repository" {
  clone "$tmp/foo/master" https://github.com/dblock/foo.git
  git -C "$tmp/foo/master" -c user.name=Test -c user.email=test@example.com commit -q --allow-empty -m Start
  git -C "$tmp/foo/master" worktree add -q -b topic "$tmp/foo/implementation"
  run "$strategy" < <(input x "$tmp/foo/implementation")
  [ "$output" = "foo" ]
}

@test "uses the upstream remote without an origin" {
  clone "$tmp/renamed"
  git -C "$tmp/renamed" remote add upstream https://github.com/dblock/real-name/
  run "$strategy" < <(input x "$tmp/renamed")
  [ "$output" = "real-name" ]
}

@test "names a checkout without a remote after its folder" {
  clone "$tmp/local"
  mkdir -p "$tmp/local/src"
  run "$strategy" < <(input x "$tmp/local/src")
  [ "$output" = "local" ]
}

@test "names a folder outside a checkout after itself" {
  mkdir -p "$tmp/notes"
  run "$strategy" < <(input x "$tmp/notes")
  [ "$output" = "notes" ]
}

@test "names nothing without a folder, for a missing folder, at the root, or in the home folder" {
  run "$strategy" <<<'{"prompt": "x"}'
  [ -z "$output" ]
  run "$strategy" < <(input x "$tmp/missing")
  [ -z "$output" ]
  run "$strategy" < <(input x /)
  [ -z "$output" ]
  run "$strategy" < <(input x "$HOME")
  [ -z "$output" ]
}
