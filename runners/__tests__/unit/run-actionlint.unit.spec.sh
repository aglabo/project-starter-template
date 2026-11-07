#!/usr/bin/env bash
# src: ./runners/__tests__/unit/run-actionlint.unit.spec.sh
# @(#) : ShellSpec unit tests for run-actionlint.sh main()
# shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-actionlint.sh"

# ─── Internal Helpers

# Creates the fixture directory (_TEST_DIR), the stub argument log (_STUB_LOG),
# and resets the stub exit code (_STUB_RC) to 0.
# Points PROJECT_ROOT at _TEST_DIR so the repository's configs/jactionlint.yaml is not found.
_setup_env() {
  _TEST_DIR=$(mktemp -d)
  # shellcheck disable=SC2034 # read by main() via resolve_config_file in utils.lib.sh
  PROJECT_ROOT="${_TEST_DIR}"
  _STUB_LOG=$(mktemp)
  _STUB_RC=0
}

# Creates the repository config configs/jactionlint.yaml under PROJECT_ROOT (_TEST_DIR).
_create_local_config() {
  mkdir -p "${_TEST_DIR}/configs"
  : > "${_TEST_DIR}/configs/jactionlint.yaml"
}

# Creates the global config global-configs/jactionlint.yaml under the given config directory.
# Arguments: $1 - user config directory (e.g. <tmp>/xdg or <tmp>/home/.config)
_create_global_config() {
  mkdir -p "$1/global-configs"
  : > "$1/global-configs/jactionlint.yaml"
}

# Removes the fixture directory and the stub argument log.
_cleanup_env() {
  rm -rf "${_TEST_DIR}"
  rm -f "${_STUB_LOG}"
}

# Stub replacing jactionlint: appends each argument to _STUB_LOG, one per line,
# and returns _STUB_RC.
jactionlint() {
  printf '%s\n' "$@" >> "${_STUB_LOG}"
  return "${_STUB_RC}"
}

# ─── Tests

Describe 'T-RUN-MAL: run-actionlint.sh main()'
  BeforeEach '_setup_env'
  AfterEach '_cleanup_env'

  Describe 'When: Normal cases'
    It "[Normal] T-RUN-MAL-01: XDG_CONFIG_HOME=<tmp>/xdg -> --config-file <tmp>/xdg/global-configs/jactionlint.yaml"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      When call main
      The status should equal 0
      The line 1 of contents of file "${_STUB_LOG}" should equal "--config-file"
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/jactionlint.yaml"
    End

    It "[Normal] T-RUN-MAL-02: main a.yml -> --config-file <config> a.yml"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main a.yml
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 3
      The line 1 of contents of file "${_STUB_LOG}" should equal "--config-file"
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/jactionlint.yaml"
      The line 3 of contents of file "${_STUB_LOG}" should equal "a.yml"
    End

    It "[Normal] T-RUN-MAL-03: main -color a.yml b.yml -> arguments forwarded in order after the config option"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main -color a.yml b.yml
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 5
      The line 3 of contents of file "${_STUB_LOG}" should equal "-color"
      The line 4 of contents of file "${_STUB_LOG}" should equal "a.yml"
      The line 5 of contents of file "${_STUB_LOG}" should equal "b.yml"
    End

    It "[Normal] T-RUN-MAL-04: <tmp>/configs/jactionlint.yaml exists -> the repository config takes priority"
      _create_local_config
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      When call main a.yml
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 3
      The line 1 of contents of file "${_STUB_LOG}" should equal "--config-file"
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/configs/jactionlint.yaml"
      The line 3 of contents of file "${_STUB_LOG}" should equal "a.yml"
    End
  End

  Describe 'When: Error cases'
    It "[Error] T-RUN-MAL-05: jactionlint returns 3 -> main returns 3 unchanged"
      _STUB_RC=3
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main a.yml
      The status should equal 3
      The line 3 of contents of file "${_STUB_LOG}" should equal "a.yml"
    End

    It "[Error] T-RUN-MAL-06: no config locally or globally -> returns 78, reports the global-configs directory candidates, jactionlint not called"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      When call main a.yml
      The status should equal 78
      The stderr should equal "Error: config file not found: ${_TEST_DIR}/configs/jactionlint.yaml (local), no global-configs directory: ${_TEST_DIR}/xdg/global-configs, ${_TEST_DIR}/home/.config/global-configs (global)"
      The contents of file "${_STUB_LOG}" should equal ""
    End

    It "[Error] T-RUN-MAL-12: global-configs exists without jactionlint.yaml -> returns 78, reports the config file candidates, jactionlint not called"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      mkdir -p "${_TEST_DIR}/xdg/global-configs"
      When call main a.yml
      The status should equal 78
      The stderr should equal "Error: config file not found: ${_TEST_DIR}/configs/jactionlint.yaml (local), ${_TEST_DIR}/xdg/global-configs/jactionlint.yaml, ${_TEST_DIR}/home/.config/global-configs/jactionlint.yaml (global)"
      The contents of file "${_STUB_LOG}" should equal ""
    End
  End

  Describe 'When: Edge cases'
    It "[Edge] T-RUN-MAL-07: XDG_CONFIG_HOME unset -> <tmp>/home/.config/global-configs/jactionlint.yaml"
      unset XDG_CONFIG_HOME
      HOME="${_TEST_DIR}/home"
      _create_global_config "${_TEST_DIR}/home/.config"
      When call main
      The status should equal 0
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/home/.config/global-configs/jactionlint.yaml"
    End

    It "[Edge] T-RUN-MAL-08: XDG_CONFIG_HOME=\"\" -> <tmp>/home/.config/global-configs/jactionlint.yaml"
      XDG_CONFIG_HOME=""
      HOME="${_TEST_DIR}/home"
      _create_global_config "${_TEST_DIR}/home/.config"
      When call main
      The status should equal 0
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/home/.config/global-configs/jactionlint.yaml"
    End

    It "[Edge] T-RUN-MAL-09: no arguments -> only the two config arguments, no unbound variable error"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main
      The status should equal 0
      The stderr should equal ""
      The lines of contents of file "${_STUB_LOG}" should equal 2
      The line 1 of contents of file "${_STUB_LOG}" should equal "--config-file"
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/xdg/global-configs/jactionlint.yaml"
    End

    It "[Edge] T-RUN-MAL-10: main \"my flow.yml\" -> forwarded as a single argument"
      # shellcheck disable=SC2034 # read by main() via utils.lib.sh
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      _create_global_config "${_TEST_DIR}/xdg"
      When call main "my flow.yml"
      The status should equal 0
      The lines of contents of file "${_STUB_LOG}" should equal 3
      The line 3 of contents of file "${_STUB_LOG}" should equal "my flow.yml"
    End

    It "[Edge] T-RUN-MAL-11: repository config exists, XDG_CONFIG_HOME unset -> --config-file <tmp>/configs/jactionlint.yaml"
      _create_local_config
      unset XDG_CONFIG_HOME
      HOME="${_TEST_DIR}/home"
      When call main
      The status should equal 0
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/configs/jactionlint.yaml"
    End

    It "[Edge] T-RUN-MAL-13: <tmp>/xdg/global-configs lacks the file, <tmp>/home/.config/global-configs has it -> the HOME config is used"
      XDG_CONFIG_HOME="${_TEST_DIR}/xdg"
      HOME="${_TEST_DIR}/home"
      mkdir -p "${_TEST_DIR}/xdg/global-configs"
      _create_global_config "${_TEST_DIR}/home/.config"
      When call main a.yml
      The status should equal 0
      The line 2 of contents of file "${_STUB_LOG}" should equal "${_TEST_DIR}/home/.config/global-configs/jactionlint.yaml"
    End
  End
End
