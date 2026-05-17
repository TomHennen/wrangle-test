#!/usr/bin/env bash
set -euo pipefail

# Minimal shell project for wrangle integration testing.
# build_shell.yml runs shellcheck over this file and bats over test.bats.

# greet NAME — print a friendly greeting. Falls back to "world" when no
# name is supplied.
greet() {
  local name="${1:-world}"
  printf 'hello from wrangle-test, %s\n' "$name"
}

main() {
  greet "$@"
}

main "$@"
