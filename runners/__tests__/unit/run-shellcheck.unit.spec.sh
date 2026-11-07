#!/usr/bin/env bash
# src: ./runners/__tests__/unit/run-shellcheck.unit.spec.sh
# @(#) : ShellSpec unit tests for run-shellcheck.sh main()
# shellcheck shell=bash

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellcheck.sh"

# ─── Internal Helpers

# Creates the fixture directory (_TEST_DIR) and the stub argument log (_STUB_LOG).
_setup_env() {
  _TEST_DIR=$(mktemp -d)
  _STUB_LOG=$(mktemp)
}

# Removes the fixture directory and the stub argument log.
_cleanup_env() {
  rm -rf "${_TEST_DIR}"
  rm -f "${_STUB_LOG}"
}

# Creates empty fixture files under _TEST_DIR, making parent directories.
# Arguments: $@ - paths relative to _TEST_DIR
_make_files() {
  local _rel
  for _rel in "$@"; do
    mkdir -p "$(dirname "${_TEST_DIR}/${_rel}")"
    : > "${_TEST_DIR}/${_rel}"
  done
}

# Stub replacing shellcheck: appends each argument to _STUB_LOG, one per line.
# main() calls shellcheck in a subshell, so a file is used instead of a variable.
shellcheck() {
  printf '%s\n' "$@" >> "${_STUB_LOG}"
}

# ─── Tests

Describe 'T-RUN-MSC: run-shellcheck.sh main()'
  BeforeEach '_setup_env'
  AfterEach '_cleanup_env'

  # A directory scan prunes node_modules and .tools and skips *.spec.sh
  Describe 'When: Normal cases'
    It "[Normal] T-RUN-MSC-01: <tmp>/node_modules/pkg/x.sh is not passed, <tmp>/a.sh is"
      _make_files "a.sh" "node_modules/pkg/x.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
      The contents of file "${_STUB_LOG}" should not include "${_TEST_DIR}/node_modules/pkg/x.sh"
    End

    It "[Normal] T-RUN-MSC-02: <tmp>/sub/node_modules/pkg/x.sh is not passed, <tmp>/a.sh is"
      _make_files "a.sh" "sub/node_modules/pkg/x.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
      The contents of file "${_STUB_LOG}" should not include "${_TEST_DIR}/sub/node_modules/pkg/x.sh"
    End

    It "[Normal] T-RUN-MSC-03: <tmp>/.tools/tool/y.sh is not passed, <tmp>/a.sh is"
      _make_files "a.sh" ".tools/tool/y.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
      The contents of file "${_STUB_LOG}" should not include "${_TEST_DIR}/.tools/tool/y.sh"
    End

    It "[Normal] T-RUN-MSC-04: <tmp>/a.sh is passed"
      _make_files "a.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
    End

    It "[Normal] T-RUN-MSC-05: <tmp>/lib/b.sh is passed"
      _make_files "lib/b.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/lib/b.sh"
    End

    It "[Normal] T-RUN-MSC-10: <tmp>/__tests__/unit/a.unit.spec.sh is not passed in a directory scan, <tmp>/a.sh is"
      _make_files "a.sh" "__tests__/unit/a.unit.spec.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
      The contents of file "${_STUB_LOG}" should not include "${_TEST_DIR}/__tests__/unit/a.unit.spec.sh"
    End
  End

  Describe 'When: Error cases'
    It "[Error] T-RUN-MSC-06: --bogus -> returns 1, reports Unknown option, and does not call shellcheck"
      When call main --bogus
      The status should equal 1
      The stderr should include "Unknown option: --bogus"
      The contents of file "${_STUB_LOG}" should equal ""
    End
  End

  # .sh files at the boundary of the exclusion patterns: node_modules/.tools are pruned only in directory scans,
  # *.spec.sh is skipped both in directory scans and when given explicitly
  Describe 'When: Edge cases'
    It "[Edge] T-RUN-MSC-07: only <tmp>/.tools/tool/y.sh exists -> No .sh files found, shellcheck not called"
      _make_files ".tools/tool/y.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The stderr should include "No .sh files found."
      The contents of file "${_STUB_LOG}" should equal ""
    End

    It "[Edge] T-RUN-MSC-08: <tmp>/.tools_backup/c.sh is passed"
      _make_files ".tools_backup/c.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/.tools_backup/c.sh"
    End

    It "[Edge] T-RUN-MSC-09: <tmp>/.tools/tool/y.sh given as a file is passed (exclusion applies only to directory scans)"
      _make_files ".tools/tool/y.sh"
      When call main "${_TEST_DIR}/.tools/tool/y.sh"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/.tools/tool/y.sh"
    End

    It "[Edge] T-RUN-MSC-11: <tmp>/a.spec.sh given as a file is not passed, <tmp>/a.sh given with it is"
      _make_files "a.sh" "a.spec.sh"
      When call main "${_TEST_DIR}/a.sh" "${_TEST_DIR}/a.spec.sh"
      The status should equal 0
      The contents of file "${_STUB_LOG}" should include "${_TEST_DIR}/a.sh"
      The contents of file "${_STUB_LOG}" should not include "${_TEST_DIR}/a.spec.sh"
    End

    It "[Edge] T-RUN-MSC-12: only spec files given -> No .sh files found, shellcheck not called"
      _make_files "a.spec.sh"
      When call main "${_TEST_DIR}/a.spec.sh"
      The status should equal 0
      The stderr should include "No .sh files found."
      The contents of file "${_STUB_LOG}" should equal ""
    End

    It "[Edge] T-RUN-MSC-13: only <tmp>/node_modules/pkg/x.sh exists -> No .sh files found, shellcheck not called"
      _make_files "node_modules/pkg/x.sh"
      When call main "${_TEST_DIR}"
      The status should equal 0
      The stderr should include "No .sh files found."
      The contents of file "${_STUB_LOG}" should equal ""
    End
  End
End
