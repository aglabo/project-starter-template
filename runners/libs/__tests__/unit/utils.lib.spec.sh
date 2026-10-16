#!/usr/bin/env bash
# runners/libs/__tests__/unit/utils.lib.spec.sh
# @(#) : BDD unit tests for utils.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# utils.lib.spec.sh - BDD spec for utils.lib.sh

# cspell:words TMPBASE

# --- Test infrastructure -----------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- Target under test -------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/utils.lib.sh"

# --- Internal helpers --------------------------------------------------------

# Constants

# Root of the fake directories. Placed in the temp area ShellSpec removes when the run ends
_RC_FIXTURE_ROOT="${SPEC_FIXTURE_BASE}/utils-resolve-config-fixture"

# Existing XDG_CONFIG_HOME (input and expected value of T-RUN-RC-01)
_RC_XDG_DIR="${_RC_FIXTURE_ROOT}/xdg"

# HOME with `.config` (input of T-RUN-RC-02/03/05)
_RC_HOME_WITH_CONFIG="${_RC_FIXTURE_ROOT}/home-with-config"

# `.config` under _RC_HOME_WITH_CONFIG (expected value of T-RUN-RC-02/03/05)
_RC_HOME_CONFIG_DIR="${_RC_HOME_WITH_CONFIG}/.config"

# HOME without `.config` (input of T-RUN-RC-04)
_RC_HOME_WITHOUT_CONFIG="${_RC_FIXTURE_ROOT}/home-without-config"

# Nonexistent XDG_CONFIG_HOME (input of T-RUN-RC-03/04)
_RC_MISSING_DIR="${_RC_FIXTURE_ROOT}/missing"

# Functions

#
# @description Build the fake directories for resolve_global_configdir().
#              mkdir -p is idempotent, so repeated calls under `--jobs 4` are safe
# @arg none
# @return 0 when the fixture directories exist
# @sideeffect Creates _RC_FIXTURE_ROOT and its contents on disk
#
_setup_resolve_global_configdir_fixture() {
  mkdir -p "$_RC_XDG_DIR" "$_RC_HOME_CONFIG_DIR" "$_RC_HOME_WITHOUT_CONFIG"
}

# --- Test body ---------------------------------------------------------------

#
# Utility lib shared by the runner scripts.
#
Describe 'utils.lib.sh'
  #
  # Resolve the user config directory. Prefers XDG_CONFIG_HOME,
  # falls back to ${HOME}/.config, and returns an empty string if neither exists
  #
  Describe 'T-RUN-RC: resolve_global_configdir()'
    Before '_setup_resolve_global_configdir_fixture'

    Describe 'When: Normal cases'
      It 'Then: [Normal] T-RUN-RC-01: returns an existing XDG_CONFIG_HOME as is'
        export XDG_CONFIG_HOME="$_RC_XDG_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_XDG_DIR"
        The status should be success
      End

      It 'Then: [Normal] T-RUN-RC-02: returns .config under HOME when XDG_CONFIG_HOME is unset'
        unset XDG_CONFIG_HOME
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It 'Then: [Error] T-RUN-RC-03: falls back to .config under HOME when XDG_CONFIG_HOME does not exist'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End

      It 'Then: [Error] T-RUN-RC-04: returns an empty string when neither directory exists'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITHOUT_CONFIG"
        When call resolve_global_configdir
        The output should equal ""
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It 'Then: [Edge] T-RUN-RC-05: treats an empty XDG_CONFIG_HOME as unset'
        export XDG_CONFIG_HOME=''
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End
  End
End
