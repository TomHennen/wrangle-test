#!/usr/bin/env bats

@test "script.sh runs without error" {
  run bash ./shell/script.sh
  [ "$status" -eq 0 ]
  [ "$output" = "hello from wrangle-test" ]
}
