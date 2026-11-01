#!/usr/bin/env bash
# runners/libs/__tests__/unit/get-filelist.unit.spec.sh
# @(#) : BDD unit tests for get-filelist.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# get-filelist.unit.spec.sh - BDD spec for get-filelist.lib.sh

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"
Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/get-filelist.lib.sh"

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

Describe 'T-LIB-GFL: get_filelist()'
  Before 'setup_temp_specs'
  After 'teardown_temp_specs'

  Describe 'When: Normal cases'
    It '[Normal] T-LIB-GFL-01: returns all spec files'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      The output should include '.spec.sh'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-02: output has no backslashes'
      When call get_filelist "$TEMP_DIR" "*.spec.sh"
      # shellcheck disable=SC1003
      The output should not include '\'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-03: filters by plain string kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "kv-store"
      The output should include 'kv-store'
      The output should not include 'args-normalize'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-04: filters by glob init*'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "init*"
      The output should include 'init'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-05: restricts to runners/ directory'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/"
      The output should include 'runners/'
      The output should not include 'skills/'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-06: restricts to runners/libs/__tests__/unit path'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/libs/__tests__/unit"
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-07: restricts to __tests__/unit path filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "__tests__/unit"
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End

    It '[Normal] T-LIB-GFL-08: combines runners/ + kv-store'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "runners/" "kv-store"
      The output should include 'kv-store'
      The output should not include 'skills/'
      The status should be success
    End

    # Only these examples use the _TEST_DIR fixture tree
    Describe 'Fixture: hidden/visible tree'
      Before '_setup_env'
      After 'remove_temp_dir _TEST_DIR'

      It '[Normal] T-LIB-GFL-09: filter "./.hidden/x" -> ".hidden/x/a.spec.sh"'
        When call get_filelist "${_TEST_DIR}" "*.spec.sh" "./.hidden/x"
        The output should equal ".hidden/x/a.spec.sh"
      End

      It '[Normal] T-LIB-GFL-10: filter "./visible" -> "./visible/b.spec.sh"'
        When call get_filelist "${_TEST_DIR}" "*.spec.sh" "./visible"
        The output should equal "./visible/b.spec.sh"
      End

      It '[Normal] T-LIB-GFL-11: filter ".hidden/x" -> ".hidden/x/a.spec.sh"'
        When call get_filelist "${_TEST_DIR}" "*.spec.sh" ".hidden/x"
        The output should equal ".hidden/x/a.spec.sh"
      End
    End
  End

  Describe 'When: Edge cases'
    It '[Edge] T-LIB-GFL-12: handles backslash dir_filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" 'runners\libs\__tests__\unit'
      The output should include '__tests__/unit'
      The output should not include 'integration'
      The status should be success
    End

    It '[Edge] T-LIB-GFL-13: returns empty for nonexistent filter'
      When call get_filelist "$TEMP_DIR" "*.spec.sh" "nonexistent-filter-xyz"
      The output should equal ''
      The status should be success
    End
  End
End

# --- Argument normalization -------------------------------------------------

Describe 'T-LIB-ATF: args_to_filter()'
  Describe 'When: Normal cases'
    It '[Normal] T-LIB-ATF-01: converts trailing wildcard init* to init.*'
      When call args_to_filter "init*"
      The output should equal "init.*"
      The status should be success
    End

    It '[Normal] T-LIB-ATF-02: converts single-char wildcard init? to init.'
      When call args_to_filter "init?"
      The output should equal "init."
      The status should be success
    End

    It '[Normal] T-LIB-ATF-03: returns kv-store unchanged (no glob)'
      When call args_to_filter "kv-store"
      The output should equal "kv-store"
      The status should be success
    End

    It '[Normal] T-LIB-ATF-04: converts path with wildcard unit/init* to unit/init.*'
      When call args_to_filter "unit/init*"
      The output should equal "unit/init.*"
      The status should be success
    End
  End
End

Describe 'normalize_path()'
  Describe 'T-LIB-NP: backslash to forward slash conversion'
    Describe 'When: Normal cases'
      It '[Normal] T-LIB-NP-01: converts backslash separator to forward slash'
        When call normalize_path 'runners\libs\tests'
        The output should equal 'runners/libs/tests'
        The status should be success
      End

      It '[Normal] T-LIB-NP-02: converts spec file path with multiple backslashes'
        When call normalize_path 'runners\libs\tests\unit\kv-store.spec.sh'
        The output should equal 'runners/libs/tests/unit/kv-store.spec.sh'
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-LIB-NP-03: leaves forward slash path unchanged'
        When call normalize_path 'runners/libs/tests'
        The output should equal 'runners/libs/tests'
        The status should be success
      End

      It '[Edge] T-LIB-NP-04: leaves plain filename unchanged'
        When call normalize_path 'kv-store.spec.sh'
        The output should equal 'kv-store.spec.sh'
        The status should be success
      End
    End
  End
End

Describe 'T-LIB-IGP: is_glob_pattern()'
  Describe 'When: Normal cases'
    It '[Normal] T-LIB-IGP-01: returns success for trailing wildcard init*'
      When call is_glob_pattern 'init*'
      The status should be success
    End

    It '[Normal] T-LIB-IGP-02: returns success for single-char wildcard init?'
      When call is_glob_pattern 'init?'
      The status should be success
    End

    It '[Normal] T-LIB-IGP-03: returns success for path with wildcard unit/init*'
      When call is_glob_pattern 'unit/init*'
      The status should be success
    End
  End

  Describe 'When: Error cases'
    It '[Error] T-LIB-IGP-04: returns failure for plain name kv-store'
      When call is_glob_pattern 'kv-store'
      The status should be failure
    End

    It '[Error] T-LIB-IGP-05: returns failure for full file path without glob'
      When call is_glob_pattern 'runners/libs/tests/unit/kv-store.spec.sh'
      The status should be failure
    End
  End
End
