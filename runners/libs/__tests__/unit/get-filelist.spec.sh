#!/usr/bin/env bash
# runners/libs/__tests__/unit/get-filelist.spec.sh
# @(#) : BDD unit tests for get-filelist.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# get-filelist.spec.sh - BDD spec for get-filelist.lib.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/get-filelist.lib.sh"

Describe 'T-RUN-GFL: get_filelist()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'no filter'
    It 'T-RUN-GFL-01: returns all spec files'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      The output should include '.spec.sh'
      The status should be success
    End

    It 'T-RUN-GFL-02: output has no backslashes'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      # shellcheck disable=SC1003
      The output should not include '\'
      The status should be success
    End
  End

  Describe 'str_filter (argument without slash)'
    It 'T-RUN-GFL-03: filters by plain string kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "kv-store"
      The output should include 'kv-store'
      The output should not include 'args-normalize'
      The status should be success
    End

    It 'T-RUN-GFL-04: filters by glob init*'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "init*"
      The output should include 'init'
      The status should be success
    End
  End

  Describe 'dir_filter (argument with slash)'
    It 'T-RUN-GFL-05: restricts to runners/ directory'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/"
      The output should include 'runners/'
      The output should not include 'skills/'
      The status should be success
    End

    It 'T-RUN-GFL-06: restricts to runners/libs/__tests__/unit path'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/libs/__tests__/unit"
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End

    It 'T-RUN-GFL-07: restricts to __tests__/unit path filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "__tests__/unit"
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End
  End

  Describe 'dir_filter + str_filter combined'
    It 'T-RUN-GFL-08: combines runners/ + kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/" "kv-store"
      The output should include 'kv-store'
      The output should not include 'skills/'
      The status should be success
    End
  End

  Describe 'backslash path support'
    It 'T-RUN-GFL-09: handles backslash dir_filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" 'runners\libs\__tests__\unit'
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End
  End

  Describe 'no files'
    It 'T-RUN-GFL-10: returns empty for nonexistent filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "nonexistent-filter-xyz"
      The output should equal ''
      The status should be success
    End
  End
End

# --- Internal helpers -------------------------------------------------------

# Creates the fixtures under _TEST_DIR.
#   .ignore             : allow-lists .hidden/ so rg lists it, as the repo's .gitignore does for .github/
#   .hidden/x/a.spec.sh : hidden path (rg output has no ./ prefix)
#   visible/b.spec.sh   : visible path (rg output gets ./ prefix)
_setup_env() {
  make_temp_dir _TEST_DIR || return 1
  mkdir -p "${_TEST_DIR}/.hidden/x" "${_TEST_DIR}/visible"
  printf '%s\n' '!.hidden/' > "${_TEST_DIR}/.ignore"
  : > "${_TEST_DIR}/.hidden/x/a.spec.sh"
  : > "${_TEST_DIR}/visible/b.spec.sh"
}

# --- Test cases -------------------------------------------------------------

Describe 'get_filelist'
  BeforeEach '_setup_env'
  AfterEach 'remove_temp_dir _TEST_DIR'

  Describe 'Then: Task T-01-01 - leading ./ in dir filters'
    It '[Normal] T-01-01-01: filter "./.hidden/x" -> ".hidden/x/a.spec.sh"'
      When call get_filelist "${_TEST_DIR}" "*.spec.sh" "./.hidden/x"
      The output should equal ".hidden/x/a.spec.sh"
    End

    It '[Normal] T-01-01-02: filter "./visible" -> "./visible/b.spec.sh"'
      When call get_filelist "${_TEST_DIR}" "*.spec.sh" "./visible"
      The output should equal "./visible/b.spec.sh"
    End

    It '[Normal] T-01-01-03: filter ".hidden/x" -> ".hidden/x/a.spec.sh"'
      When call get_filelist "${_TEST_DIR}" "*.spec.sh" ".hidden/x"
      The output should equal ".hidden/x/a.spec.sh"
    End
  End
End
