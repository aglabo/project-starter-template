#!/usr/bin/env bash
# src: ./runners/__tests__/unit/run-betterleaks.unit.spec.sh
# @(#) : ShellSpec unit tests for run-betterleaks.sh main()
# shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-betterleaks.sh"

# ─── Internal Helpers

# Creates the fixture directory (_TEST_DIR), the stub argument log (_STUB_LOG),
# and resets the stub exit code (_STUB_RC) to 0.
# Points PROJECT_ROOT at _TEST_DIR so the repository's configs/betterleaks.toml is not found.
_setup_env() {
  _TEST_DIR=$(mktemp -d)
  # shellcheck disable=SC2034 # read by main() via resolve_config_file in utils.lib.sh
  PROJECT_ROOT="${_TEST_DIR}"
  _STUB_LOG=$(mktemp)
  _STUB_RC=0
}

# Creates the repository config configs/betterleaks.toml under PROJECT_ROOT (_TEST_DIR).
_create_local_config() {
  mkdir -p "${_TEST_DIR}/configs"
  : > "${_TEST_DIR}/configs/betterleaks.toml"
}

# Creates the global config global-configs/betterleaks.toml under the given config directory.
# Arguments: $1 - user config directory (e.g. <tmp>/xdg or <tmp>/home/.config)
_create_global_config() {
  mkdir -p "$1/global-configs"
  : > "$1/global-configs/betterleaks.toml"
}

# Removes the fixture directory and the stub argument log.
_cleanup_env() {
  rm -rf "${_TEST_DIR}"
  rm -f "${_STUB_LOG}"
}

# Stub replacing betterleaks: appends each argument to _STUB_LOG, one per line,
# and returns _STUB_RC.
betterleaks() {
  printf '%s\n' "$@" >> "${_STUB_LOG}"
  return "${_STUB_RC}"
}

# ─── Tests

Describe 'T-RUN-MBL: run-betterleaks.sh main()'
  BeforeEach '_setup_env'
  AfterEach '_cleanup_env'

  Describe 'When: Normal cases'
    It "[Normal] T-RUN-MBL-01: no arguments -> dir --config <global> --no-banner --redact --verbose ."
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 7
      The line 1 of contents of file "${_STUB_LOG}" should equal "dir"
      The line 2 of contents of file "${_STUB_LOG}" should equal "--config"
      The line 3 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/betterleaks.toml"
      The line 4 of contents of file "${_STUB_LOG}" should equal "--no-banner"
      The line 5 of contents of file "${_STUB_LOG}" should equal "--redact"
      The line 6 of contents of file "${_STUB_LOG}" should equal "--verbose"
      The line 7 of contents of file "${_STUB_LOG}" should equal "."
    End

    It "[Normal] T-RUN-MBL-02: main a b -> dir <options> a, then dir <options> b"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main a b
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 14
      The line 1 of contents of file "${_STUB_LOG}" should equal "dir"
      The line 7 of contents of file "${_STUB_LOG}" should equal "a"
      The line 8 of contents of file "${_STUB_LOG}" should equal "dir"
      The line 14 of contents of file "${_STUB_LOG}" should equal "b"
    End

    It "[Normal] T-RUN-MBL-03: main --staged -> git --pre-commit --staged <options>"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main --staged
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 8
      The line 1 of contents of file "${_STUB_LOG}" should equal "git"
      The line 2 of contents of file "${_STUB_LOG}" should equal "--pre-commit"
      The line 3 of contents of file "${_STUB_LOG}" should equal "--staged"
      The line 4 of contents of file "${_STUB_LOG}" should equal "--config"
      The line 5 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/betterleaks.toml"
      The line 6 of contents of file "${_STUB_LOG}" should equal "--no-banner"
      The line 7 of contents of file "${_STUB_LOG}" should equal "--redact"
      The line 8 of contents of file "${_STUB_LOG}" should equal "--verbose"
    End

    It "[Normal] T-RUN-MBL-04: <tmp>/configs/betterleaks.toml exists -> the repository config takes priority"
      _create_local_config
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main
      The status should equal 0
      The line 3 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/configs/betterleaks.toml"
    End
  End

  Describe 'When: Error cases'
    It "[Error] T-RUN-MBL-05: betterleaks returns 1 (leaks found) -> main returns 1 unchanged"
      _STUB_RC=1
      _create_local_config
      When call main
      The status should equal 1
    End

    It "[Error] T-RUN-MBL-06: no config locally or globally -> returns 78, betterleaks not called"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      When call main
      The status should equal 78
      The stderr should equal "Error: config file not found: ${_TEST_DIR}/configs/betterleaks.toml (local), no global-configs directory: ${_TEST_DIR}/xdg/global-configs, ${_TEST_DIR}/home/.config/global-configs (global)"
      The contents of file "${_STUB_LOG}" should equal ""
    End
  End

  Describe 'When: Edge cases'
    It "[Edge] T-RUN-MBL-07: main --staged a -> paths are ignored in staged mode"
      _create_local_config
      When call main --staged a
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 8
      The line 1 of contents of file "${_STUB_LOG}" should equal "git"
    End

    It "[Edge] T-RUN-MBL-08: main \"my dir\" -> forwarded as a single argument"
      _create_local_config
      When call main "my dir"
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 7
      The line 7 of contents of file "${_STUB_LOG}" should equal "my dir"
    End

    It "[Edge] T-RUN-MBL-09: main a b with betterleaks returning 1 -> both scanned, returns 1"
      _STUB_RC=1
      _create_local_config
      When call main a b
      The status should equal 1
      The lines of contents of file "${_STUB_LOG}" should equal 14
      The line 7 of contents of file "${_STUB_LOG}" should equal "a"
      The line 14 of contents of file "${_STUB_LOG}" should equal "b"
    End
  End
End
