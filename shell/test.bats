#!/usr/bin/env bats

# Unit tests for shell/script.sh, run by wrangle's build_shell.yml (bats).
# A failing test here fails the shell build — proof the bats step runs.

@test "greet defaults to 'world' when given no name" {
  run bash "${BATS_TEST_DIRNAME}/script.sh"
  [ "$status" -eq 0 ]
  [ "$output" = "hello from wrangle-test, world" ]
}

@test "greet uses the supplied name" {
  run bash "${BATS_TEST_DIRNAME}/script.sh" Ada
  [ "$status" -eq 0 ]
  [ "$output" = "hello from wrangle-test, Ada" ]
}

@test "greet emits exactly one line" {
  run bash "${BATS_TEST_DIRNAME}/script.sh" Grace
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
}
