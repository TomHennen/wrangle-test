#!/usr/bin/env bash
set -euo pipefail

# Minimal shell script for wrangle integration testing.
# This file exists so build_shell.yml has something to shellcheck.

main() {
  printf 'hello from wrangle-test\n'
}

main "$@"
