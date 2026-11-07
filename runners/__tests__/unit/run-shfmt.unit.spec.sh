#!/usr/bin/env bash
# src: ./runners/__tests__/unit/run-shfmt.unit.spec.sh
# @(#) : ShellSpec unit tests for run-shfmt.sh main()
# shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shfmt.sh"

# ─── Internal Helpers

# Creates the fixture directory (_TEST_DIR), the stub argument log (_STUB_LOG),
# and points PROJECT_ROOT at _TEST_DIR so main() changes into the fixture.
_setup_env() {
  _TEST_DIR=$(mktemp -d)
  _STUB_LOG=$(mktemp)
  # shellcheck disable=SC2034 # read by main() (cd "$PROJECT_ROOT")
  PROJECT_ROOT="${_TEST_DIR}"
}

# Removes the fixture directory and the stub argument log.
_cleanup_env() {
  rm -rf "${_TEST_DIR}"
  rm -f "${_STUB_LOG}"
}

# Stub replacing shfmt: appends each argument to _STUB_LOG, one per line.
# main() calls shfmt in a subshell, so a file is used instead of a variable.
shfmt() {
  printf '%s\n' "$@" >> "${_STUB_LOG}"
}

# ─── Tests

Describe 'T-RUN-MSF: run-shfmt.sh main()'
  BeforeEach '_setup_env'
  AfterEach '_cleanup_env'

  # Targets are passed through to shfmt with --apply-ignore, which makes shfmt apply the
  # .editorconfig ignore rules (spec files, node_modules, .tools) to explicit files and directory walks alike
  Describe 'When: Normal cases'
    It "[Normal] T-RUN-MSF-01: --list a.sh a.spec.sh -> shfmt -ln bash -i 2 -l --apply-ignore -- a.sh a.spec.sh"
      When call main --list a.sh a.spec.sh
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -l --apply-ignore -- a.sh a.spec.sh)"
    End

    It "[Normal] T-RUN-MSF-02: --format a.sh a.spec.sh -> shfmt -ln bash -i 2 -w --apply-ignore -- a.sh a.spec.sh"
      When call main --format a.sh a.spec.sh
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -w --apply-ignore -- a.sh a.spec.sh)"
    End

    It "[Normal] T-RUN-MSF-03: --list runners -> shfmt -ln bash -i 2 -l --apply-ignore -- runners"
      When call main --list runners
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -l --apply-ignore -- runners)"
    End
  End

  # Boundary target lists
  Describe 'When: Edge cases'
    It "[Edge] T-RUN-MSF-04: --list a.spec.sh b/c.spec.sh -> shfmt -ln bash -i 2 -l --apply-ignore -- a.spec.sh b/c.spec.sh"
      When call main --list a.spec.sh b/c.spec.sh
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -l --apply-ignore -- a.spec.sh b/c.spec.sh)"
    End

    It "[Edge] T-RUN-MSF-05: no arguments -> the default target is the project root: shfmt -ln bash -i 2 -l --apply-ignore -- ."
      When call main
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -l --apply-ignore -- .)"
    End

    It "[Edge] T-RUN-MSF-06: --list 'runners\\libs' -> backslashes normalized: shfmt -ln bash -i 2 -l --apply-ignore -- runners/libs"
      When call main --list 'runners\libs'
      The status should equal 0
      The contents of file "${_STUB_LOG}" should equal "$(printf '%s\n' -ln bash -i 2 -l --apply-ignore -- runners/libs)"
    End
  End
End
