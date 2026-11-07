#!/usr/bin/env bash
# runners/libs/__tests__/unit/utils.lib.unit.spec.sh
# @(#) : BDD unit tests for utils.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# utils.lib.unit.spec.sh - BDD spec for utils.lib.sh

# cspell:words TMPBASE

# --- Test infrastructure -----------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- Target under test -------------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/utils.lib.sh"

# --- Internal helpers --------------------------------------------------------

# Constants

# Root of the fake directories. Placed in the temp area ShellSpec removes when the run ends
_RC_FIXTURE_ROOT="${SPEC_FIXTURE_BASE}/utils-resolve-config-fixture"

# Existing XDG_CONFIG_HOME holding global-configs (input of T-LIB-RC-01)
_RC_XDG_DIR="${_RC_FIXTURE_ROOT}/xdg"

# global-configs under _RC_XDG_DIR (expected value of T-LIB-RC-01)
_RC_XDG_GLOBAL_DIR="${_RC_XDG_DIR}/global-configs"

# Existing XDG_CONFIG_HOME without global-configs (input of T-LIB-RC-06)
_RC_XDG_WITHOUT_GLOBAL="${_RC_FIXTURE_ROOT}/xdg-without-global"

# HOME with `.config/global-configs` (input of T-LIB-RC-02/03/05/06)
_RC_HOME_WITH_CONFIG="${_RC_FIXTURE_ROOT}/home-with-config"

# `.config/global-configs` under _RC_HOME_WITH_CONFIG (expected value of T-LIB-RC-02/03/05/06)
_RC_HOME_CONFIG_DIR="${_RC_HOME_WITH_CONFIG}/.config/global-configs"

# HOME without `.config` (input of T-LIB-RC-04)
_RC_HOME_WITHOUT_CONFIG="${_RC_FIXTURE_ROOT}/home-without-config"

# Nonexistent XDG_CONFIG_HOME (input of T-LIB-RC-03/04)
_RC_MISSING_DIR="${_RC_FIXTURE_ROOT}/missing"

# Root of the fake projects and config directories for resolve_config_file()
_RCF_FIXTURE_ROOT="${SPEC_FIXTURE_BASE}/utils-resolve-config-file-fixture"

# Config path relative to the global config directory (first argument of resolve_config_file)
_RCF_GLOBAL_RELPATH='tool/tool.yaml'

# Config path relative to PROJECT_ROOT (second argument of resolve_config_file)
_RCF_LOCAL_RELPATH='configs/tool.yaml'

# PROJECT_ROOT holding the local config (input of T-LIB-RCF-01)
_RCF_PROJECT_WITH_LOCAL="${_RCF_FIXTURE_ROOT}/project-with-local"

# PROJECT_ROOT without the local config (input of T-LIB-RCF-02/03/04/05)
_RCF_PROJECT_WITHOUT_LOCAL="${_RCF_FIXTURE_ROOT}/project-without-local"

# XDG_CONFIG_HOME whose global-configs holds the global config (input of T-LIB-RCF-01/02)
_RCF_XDG_WITH_FILE="${_RCF_FIXTURE_ROOT}/xdg-with-file"

# Existing XDG_CONFIG_HOME whose global-configs lacks the global config (input of T-LIB-RCF-03/06, T-LIB-CNF-02, T-LIB-RQ-04)
_RCF_XDG_WITHOUT_FILE="${_RCF_FIXTURE_ROOT}/xdg-without-file"

# HOME whose .config/global-configs holds the global config (input of T-LIB-RCF-05/06)
_RCF_HOME_WITH_FILE="${_RCF_FIXTURE_ROOT}/home-with-file"

# HOME without `.config` (input of T-LIB-RCF-03/04)
_RCF_HOME_WITHOUT_CONFIG="${_RCF_FIXTURE_ROOT}/home-without-config"

# Nonexistent XDG_CONFIG_HOME (input of T-LIB-RCF-04/05)
_RCF_MISSING_DIR="${_RCF_FIXTURE_ROOT}/missing"

# Functions

#
# @description Build the fake directories for resolve_global_configdir().
#              mkdir -p is idempotent, so repeated calls under `--jobs 4` are safe
# @arg none
# @return 0 when the fixture directories exist
# @sideeffect Creates _RC_FIXTURE_ROOT and its contents on disk
#
_setup_resolve_global_configdir_fixture() {
  mkdir -p "$_RC_XDG_GLOBAL_DIR" "$_RC_XDG_WITHOUT_GLOBAL" "$_RC_HOME_CONFIG_DIR" "$_RC_HOME_WITHOUT_CONFIG"
}

#
# @description Build the fake projects and config directories for resolve_config_file().
#              mkdir -p and `: >` are idempotent, so repeated calls under `--jobs 4` are safe
# @arg none
# @return 0 when the fixture files exist
# @sideeffect Creates _RCF_FIXTURE_ROOT and its contents on disk
#
_setup_resolve_config_file_fixture() {
  mkdir -p "${_RCF_PROJECT_WITH_LOCAL}/configs" "$_RCF_PROJECT_WITHOUT_LOCAL"     "${_RCF_XDG_WITH_FILE}/global-configs/tool" "${_RCF_XDG_WITHOUT_FILE}/global-configs"     "${_RCF_HOME_WITH_FILE}/.config/global-configs/tool" "$_RCF_HOME_WITHOUT_CONFIG"
  : > "${_RCF_PROJECT_WITH_LOCAL}/${_RCF_LOCAL_RELPATH}"
  : > "${_RCF_XDG_WITH_FILE}/global-configs/${_RCF_GLOBAL_RELPATH}"
  : > "${_RCF_HOME_WITH_FILE}/.config/global-configs/${_RCF_GLOBAL_RELPATH}"
}

# --- Test body ---------------------------------------------------------------

#
# Utility lib shared by the runner scripts.
#
Describe 'utils.lib.sh'
  #
  # Exit code constants shared by the runner scripts
  #
  Describe 'T-LIB-EC: exit code constants'
    Describe 'When: Normal cases'
      It '[Normal] T-LIB-EC-01: EXIT_CONFIG_NOT_FOUND is 78 (EX_CONFIG)'
        The value "$EXIT_CONFIG_NOT_FOUND" should equal 78
      End
    End
  End

  #
  # Resolve the user-shared global-configs directory. Prefers XDG_CONFIG_HOME/global-configs,
  # falls back to ${HOME}/.config/global-configs, and fails with no output if neither exists
  #
  Describe 'T-LIB-RC: resolve_global_configdir()'
    Before '_setup_resolve_global_configdir_fixture'

    Describe 'When: Normal cases'
      It '[Normal] T-LIB-RC-01: returns global-configs under an existing XDG_CONFIG_HOME'
        export XDG_CONFIG_HOME="$_RC_XDG_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_XDG_GLOBAL_DIR"
        The status should be success
      End

      It '[Normal] T-LIB-RC-02: returns .config/global-configs under HOME when XDG_CONFIG_HOME is unset'
        unset XDG_CONFIG_HOME
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It '[Error] T-LIB-RC-03: falls back to .config/global-configs under HOME when XDG_CONFIG_HOME does not exist'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End

      It '[Error] T-LIB-RC-04: prints nothing and fails when neither directory exists'
        export XDG_CONFIG_HOME="$_RC_MISSING_DIR"
        export HOME="$_RC_HOME_WITHOUT_CONFIG"
        When call resolve_global_configdir
        The output should equal ""
        The status should be failure
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-LIB-RC-05: treats an empty XDG_CONFIG_HOME as unset'
        export XDG_CONFIG_HOME=''
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End

      It '[Edge] T-LIB-RC-06: falls back to HOME when XDG_CONFIG_HOME exists without global-configs'
        export XDG_CONFIG_HOME="$_RC_XDG_WITHOUT_GLOBAL"
        export HOME="$_RC_HOME_WITH_CONFIG"
        When call resolve_global_configdir
        The output should equal "$_RC_HOME_CONFIG_DIR"
        The status should be success
      End
    End
  End

  #
  # Resolve a tool config file. Prefers the local config under PROJECT_ROOT,
  # falls back to the file under the first global config directory candidate holding it, and fails with no output
  # if none is found (1: no global config directory, 2: directories exist but none holds the file)
  #
  Describe 'T-LIB-RCF: resolve_config_file()'
    Before '_setup_resolve_config_file_fixture'

    Describe 'When: Normal cases'
      It '[Normal] T-LIB-RCF-01: returns the local config even when the global config exists'
        export PROJECT_ROOT="$_RCF_PROJECT_WITH_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_XDG_WITH_FILE"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "${_RCF_PROJECT_WITH_LOCAL}/${_RCF_LOCAL_RELPATH}"
        The status should be success
      End

      It '[Normal] T-LIB-RCF-02: returns the global config under XDG_CONFIG_HOME when the local config is absent'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_XDG_WITH_FILE"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "${_RCF_XDG_WITH_FILE}/global-configs/${_RCF_GLOBAL_RELPATH}"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It '[Error] T-LIB-RCF-03: prints nothing and returns 2 when a global config directory exists but lacks the file'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_XDG_WITHOUT_FILE"
        export HOME="$_RCF_HOME_WITHOUT_CONFIG"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal ""
        The status should equal 2
      End

      It '[Error] T-LIB-RCF-04: prints nothing and returns 1 when no global config directory exists'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_MISSING_DIR"
        export HOME="$_RCF_HOME_WITHOUT_CONFIG"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal ""
        The status should equal 1
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-LIB-RCF-05: falls back to the global config under HOME/.config/global-configs when XDG_CONFIG_HOME does not exist'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_MISSING_DIR"
        export HOME="$_RCF_HOME_WITH_FILE"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "${_RCF_HOME_WITH_FILE}/.config/global-configs/${_RCF_GLOBAL_RELPATH}"
        The status should be success
      End

      It '[Edge] T-LIB-RCF-06: falls back to the global config under HOME when XDG global-configs exists but lacks the file'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_XDG_WITHOUT_FILE"
        export HOME="$_RCF_HOME_WITH_FILE"
        When call resolve_config_file "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "${_RCF_HOME_WITH_FILE}/.config/global-configs/${_RCF_GLOBAL_RELPATH}"
        The status should be success
      End
    End
  End

  #
  # Format the not-found message from the resolve_config_file() status.
  # Status 1 lists the global-configs directory candidates, status 2 lists the config file candidates
  #
  Describe 'T-LIB-CNF: format_config_not_found()'
    Describe 'When: Normal cases'
      It '[Normal] T-LIB-CNF-01: status 1 lists the local config and the global-configs directory candidates'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_MISSING_DIR"
        export HOME="$_RCF_HOME_WITHOUT_CONFIG"
        When call format_config_not_found 1 "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "config file not found: ${_RCF_PROJECT_WITHOUT_LOCAL}/${_RCF_LOCAL_RELPATH} (local), no global-configs directory: ${_RCF_MISSING_DIR}/global-configs, ${_RCF_HOME_WITHOUT_CONFIG}/.config/global-configs (global)"
        The status should be success
      End

      It '[Normal] T-LIB-CNF-02: status 2 lists the local config and the global config file candidates'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        export XDG_CONFIG_HOME="$_RCF_XDG_WITHOUT_FILE"
        export HOME="$_RCF_HOME_WITHOUT_CONFIG"
        When call format_config_not_found 2 "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "config file not found: ${_RCF_PROJECT_WITHOUT_LOCAL}/${_RCF_LOCAL_RELPATH} (local), ${_RCF_XDG_WITHOUT_FILE}/global-configs/${_RCF_GLOBAL_RELPATH}, ${_RCF_HOME_WITHOUT_CONFIG}/.config/global-configs/${_RCF_GLOBAL_RELPATH} (global)"
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      It '[Edge] T-LIB-CNF-03: status 1 with XDG_CONFIG_HOME unset lists only the HOME candidate'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        unset XDG_CONFIG_HOME
        export HOME="$_RCF_HOME_WITHOUT_CONFIG"
        When call format_config_not_found 1 "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "config file not found: ${_RCF_PROJECT_WITHOUT_LOCAL}/${_RCF_LOCAL_RELPATH} (local), no global-configs directory: ${_RCF_HOME_WITHOUT_CONFIG}/.config/global-configs (global)"
        The status should be success
      End

      It '[Edge] T-LIB-CNF-04: status 1 with XDG_CONFIG_HOME and HOME unset reports no global-configs directory without candidates'
        export PROJECT_ROOT="$_RCF_PROJECT_WITHOUT_LOCAL"
        unset XDG_CONFIG_HOME HOME
        When call format_config_not_found 1 "$_RCF_GLOBAL_RELPATH" "$_RCF_LOCAL_RELPATH"
        The output should equal "config file not found: ${_RCF_PROJECT_WITHOUT_LOCAL}/${_RCF_LOCAL_RELPATH} (local), no global-configs directory (global)"
        The status should be success
      End
    End
  End
End
