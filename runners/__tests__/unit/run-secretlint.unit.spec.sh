#!/usr/bin/env bash
# src: ./runners/__tests__/unit/run-secretlint.unit.spec.sh
# @(#) : ShellSpec unit tests for run-secretlint.sh main()
# shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-secretlint.sh"

# ─── Internal Helpers

# Creates the fixture directory (_TEST_DIR), the stub argument log (_STUB_LOG),
# and resets the stub exit code (_STUB_RC) to 0.
# Points PROJECT_ROOT at _TEST_DIR so the repository's configs/secretlint.config.yaml is not found.
_setup_env() {
  _TEST_DIR=$(mktemp -d)
  # shellcheck disable=SC2034 # read by main() via resolve_config_file in utils.lib.sh
  PROJECT_ROOT="${_TEST_DIR}"
  _STUB_LOG=$(mktemp)
  _STUB_RC=0
}

# Creates the repository config configs/secretlint.config.yaml under PROJECT_ROOT (_TEST_DIR).
_create_local_config() {
  mkdir -p "${_TEST_DIR}/configs"
  : > "${_TEST_DIR}/configs/secretlint.config.yaml"
}

# Creates the global config global-configs/secretlint.config.yaml under the given config directory.
# Arguments: $1 - user config directory (e.g. <tmp>/xdg or <tmp>/home/.config)
_create_global_config() {
  mkdir -p "$1/global-configs"
  : > "$1/global-configs/secretlint.config.yaml"
}

# Creates the ignore file .gitignore under PROJECT_ROOT (_TEST_DIR).
_create_gitignore() {
  : > "${_TEST_DIR}/.gitignore"
}

# Removes the fixture directory and the stub argument log.
_cleanup_env() {
  rm -rf "${_TEST_DIR}"
  rm -f "${_STUB_LOG}"
}

# Stub replacing secretlint: appends each argument to _STUB_LOG, one per line,
# and returns _STUB_RC.
secretlint() {
  printf '%s\n' "$@" >> "${_STUB_LOG}"
  return "${_STUB_RC}"
}

# ─── Tests

Describe 'T-RUN-MSL: run-secretlint.sh main()'
  BeforeEach '_setup_env'
  AfterEach '_cleanup_env'

  Describe 'When: Normal cases'
    It "[Normal] T-RUN-MSL-01: no arguments, .gitignore exists -> --secretlintrc <global> --maskSecrets --secretlintignore <root>/.gitignore ."
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      _create_gitignore
      When call main
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 6
      The line 1 of contents of file "${_STUB_LOG}" should equal "--secretlintrc"
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/secretlint.config.yaml"
      The line 3 of contents of file "${_STUB_LOG}" should equal "--maskSecrets"
      The line 4 of contents of file "${_STUB_LOG}" should equal "--secretlintignore"
      The line 5 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/.gitignore"
      The line 6 of contents of file "${_STUB_LOG}" should equal "."
    End

    It "[Normal] T-RUN-MSL-02: main a b -> paths forwarded in order after the options"
      _create_local_config
      _create_gitignore
      When call main a b
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 7
      The line 6 of contents of file "${_STUB_LOG}" should equal "a"
      The line 7 of contents of file "${_STUB_LOG}" should equal "b"
    End

    It "[Normal] T-RUN-MSL-03: <tmp>/configs/secretlint.config.yaml exists -> the repository config takes priority"
      _create_local_config
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main
      The status should equal 0
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/configs/secretlint.config.yaml"
    End
  End

  Describe 'When: Error cases'
    It "[Error] T-RUN-MSL-04: secretlint returns 1 (secrets found) -> main returns 1 unchanged"
      _STUB_RC=1
      _create_local_config
      When call main a
      The status should equal 1
    End

    It "[Error] T-RUN-MSL-05: no config locally or globally -> returns 78, secretlint not called"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      When call main
      The status should equal 78
      The stderr should equal "Error: config file not found: ${_TEST_DIR}/configs/secretlint.config.yaml (local), no global-configs directory: ${_TEST_DIR}/xdg/global-configs, ${_TEST_DIR}/home/.config/global-configs (global)"
      The contents of file "${_STUB_LOG}" should equal ""
    End
  End

  Describe 'When: Edge cases'
    It "[Edge] T-RUN-MSL-06: no .gitignore -> --secretlintignore is omitted"
      _create_local_config
      When call main
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 4
      The line 3 of contents of file "${_STUB_LOG}" should equal "--maskSecrets"
      The line 4 of contents of file "${_STUB_LOG}" should equal "."
    End

    It "[Edge] T-RUN-MSL-07: main \"my file.txt\" -> forwarded as a single argument"
      _create_local_config
      When call main "my file.txt"
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 4
      The line 4 of contents of file "${_STUB_LOG}" should equal "my file.txt"
    End
  End
End
