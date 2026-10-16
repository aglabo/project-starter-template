#!/usr/bin/env bash
# runners/__tests__/unit/run-shellspec.spec.sh
# @(#) : BDD unit tests for run-shellspec.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# run-shellspec.spec.sh - BDD spec for run-shellspec.sh

# --- Test infrastructure ----------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/__tests__/spec_helper.sh"

# --- Subject under test -----------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/run-shellspec.sh"

SCRIPT="${SHELLSPEC_PROJECT_ROOT}/runners/run-shellspec.sh"

# --- Internal helpers -------------------------------------------------------

# Constants

# `uname -s` value for a Windows shell environment. Input that should take the WSL path
_WINDOWS_OS_NAME='MINGW64_NT-10.0-26200'

# `uname -s` value for a non-Windows shell environment. Input that should take the local path
_LOCAL_OS_NAME='Linux'

# `uname -s` values for non-Windows shell environments (input table for T-RUN-SUW-03)
%const _SUW_OTHER_OS_NAMES: Linux Darwin

# `%const` word lists cannot hold an empty word, so a sentinel stands for the empty string
_NO_WSL_EMPTY_TOKEN='EMPTY'

# SHELLSPEC_NO_WSL values that check any value other than `1` keeps the WSL path
# (input table for T-RUN-SUW-04. `EMPTY` is the empty string represented by _NO_WSL_EMPTY_TOKEN)
%const _SUW_KEEP_WSL_FLAGS: 0 EMPTY

# spec file argument passed to the entry point. Checks it reaches the executor uninterpreted
_SPEC_ARG='foo.spec.sh'

# ShellSpec option argument passed to the entry point. Checks its order after the spec argument is kept
_OPTION_ARG='--repair'

# Observed output of the arguments dispatch() should forward unchanged to the executor
_FORWARDED_ARGS_OUTPUT="[${_SPEC_ARG}][${_OPTION_ARG}]"

# Executor path dispatch() should pass to the WSL side (relative to PROJECT_ROOT)
_EXPECTED_EXEC_SCRIPT='runners/exec/shellspec-exec.sh'

# Value for _setup_dispatch_stubs() meaning wsl.exe can be invoked
_WSL_AVAILABLE='available'

# Value for _setup_dispatch_stubs() meaning wsl.exe cannot be invoked
_WSL_MISSING='missing'

# Exit code returned by failing stubs. Neither 0 nor 1, so pass-through can be told apart
_DSP_STUB_EXIT_CODE=3

# Missing command dispatch() detects before launching WSL (input and expected output of T-RUN-DSP-07)
_DSP_MISSING_COMMAND='jq'

# Functions

#
# @description Applies a value from the input table to SHELLSPEC_NO_WSL.
#              The empty string, which `%const` word lists cannot express, arrives as the sentinel `EMPTY`
# @arg $1 string Input table value, or _NO_WSL_EMPTY_TOKEN
# @return 0 always
# @sideeffect Sets SHELLSPEC_NO_WSL
#
_set_no_wsl_flag() {
  if [[ "$1" == "$_NO_WSL_EMPTY_TOKEN" ]]; then
    SHELLSPEC_NO_WSL=''
  else
    SHELLSPEC_NO_WSL="$1"
  fi
}

#
# @description Replaces the dispatch() collaborators with shell functions that "only print
#              their own name and arguments as `[%s]`", so the path taken and the forwarded
#              arguments can be observed from the output alone. To avoid depending on a real
#              wsl.exe, is_wsl_available() and find_missing_wsl_commands() are replaced too.
#              The latter reports "no missing commands" by default. SHELLSPEC_NO_WSL is also
#              unset so a value left in the caller environment does not sway the decision
# @arg $1 string `available` makes is_wsl_available() succeed; anything else makes it fail
# @return 0 always
# @sideeffect Defines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_dispatch_stubs() {
  local __wsl_state="$1"
  unset SHELLSPEC_NO_WSL
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  run_local() {
    printf '[run_local]'
    printf '[%s]' "$@"
  }
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  exec_in_wsl() {
    printf '[exec_in_wsl]'
    printf '[%s]' "$@"
  }
  if [[ "$__wsl_state" == "$_WSL_AVAILABLE" ]]; then
    # shellcheck disable=SC2329 # called indirectly from dispatch()
    is_wsl_available() { return 0; }
  else
    # shellcheck disable=SC2329 # called indirectly from dispatch()
    is_wsl_available() { return 1; }
  fi
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  find_missing_wsl_commands() { :; }
}

#
# @description Replaces the dispatch() collaborators with shell functions that fail with
#              _DSP_STUB_EXIT_CODE. Used to observe that the exit code is returned unmodified
# @arg $1 string `available` makes is_wsl_available() succeed; anything else makes it fail
# @return 0 always
# @sideeffect Defines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_failing_dispatch_stubs() {
  _setup_dispatch_stubs "$1"
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  run_local() { return "$_DSP_STUB_EXIT_CODE"; }
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  exec_in_wsl() { return "$_DSP_STUB_EXIT_CODE"; }
}

#
# @description Replaces only find_missing_wsl_commands() among the dispatch() collaborators
#              with a stub that "returns _DSP_MISSING_COMMAND as a single line".
#              Simulates required commands missing on the WSL side without a real WSL
# @arg $1 string `available` makes is_wsl_available() succeed; anything else makes it fail
# @return 0 always
# @sideeffect Defines the same shell functions as _setup_dispatch_stubs()
# @sideeffect Unsets SHELLSPEC_NO_WSL
#
_setup_missing_commands_stubs() {
  _setup_dispatch_stubs "$1"
  # shellcheck disable=SC2329 # called indirectly from dispatch()
  find_missing_wsl_commands() { printf '%s\n' "$_DSP_MISSING_COMMAND"; }
}

#
# @description Removes the shell functions replaced by _setup_dispatch_stubs()
# @arg none
# @return 0 always
# @sideeffect Undefines the run_local, exec_in_wsl, is_wsl_available and
#             find_missing_wsl_commands shell functions
#
_teardown_dispatch_stubs() {
  unset -f run_local exec_in_wsl is_wsl_available find_missing_wsl_commands
}

# --- Test body --------------------------------------------------------------

#
# Entry script for running ShellSpec. It inspects the environment and only decides whether
# to run the executor (exec/shellspec-exec.sh) locally or on WSL.
#
Describe 'run-shellspec.sh'
  #
  # Pure function that decides on the WSL path from only the `uname -s` value and SHELLSPEC_NO_WSL.
  # It does not call uname itself, so OS names can be fed in from a table
  #
  Describe 'T-RUN-SUW: should_use_wsl()'
    # Use WSL when launched from a Windows shell and not disabled
    Describe 'When: normal cases'
      It 'Then: [Normal] T-RUN-SUW-01: decides to use WSL on a Windows host with SHELLSPEC_NO_WSL unset'
        unset SHELLSPEC_NO_WSL
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be success
      End
    End

    # SHELLSPEC_NO_WSL=1 explicitly disables the WSL path
    Describe 'When: error cases'
      It 'Then: [Error] T-RUN-SUW-02: does not use WSL even on a Windows host when SHELLSPEC_NO_WSL=1'
        # shellcheck disable=SC2034 # read by should_use_wsl()
        SHELLSPEC_NO_WSL=1
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be failure
      End

      # shellcheck disable=SC2086 # split the %const table into one case per word
      Parameters:value $_SUW_OTHER_OS_NAMES

      It "Then: [Error] T-RUN-SUW-03: does not use WSL for OS name $1"
        unset SHELLSPEC_NO_WSL
        When call should_use_wsl "$1"
        The status should be failure
      End
    End

    # Only `1` disables it; any other value keeps the WSL path
    Describe 'When: edge cases'
      # shellcheck disable=SC2086 # split the %const table into one case per word
      Parameters:value $_SUW_KEEP_WSL_FLAGS

      It "Then: [Edge] T-RUN-SUW-04: does not disable the WSL path when SHELLSPEC_NO_WSL is $1"
        _set_no_wsl_flag "$1"
        When call should_use_wsl "$_WINDOWS_OS_NAME"
        The status should be success
      End
    End
  End

  #
  # Routes to local or WSL execution based on the decision. Arguments are never interpreted
  # and are passed to the executor in the order received
  #
  Describe 'T-RUN-DSP: dispatch()'
    After '_teardown_dispatch_stubs'

    # On non-Windows hosts, run the executor in this shell as before
    Describe 'When: normal cases'
      It 'Then: [Normal] T-RUN-DSP-01: forwards arguments unchanged to run_local on a non-Windows host'
        _setup_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_LOCAL_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should equal "[run_local]${_FORWARDED_ARGS_OUTPUT}"
        The output should not include 'exec_in_wsl'
        The status should be success
      End

      It 'Then: [Normal] T-RUN-DSP-02: calls exec_in_wsl with PROJECT_ROOT and the executor path prepended on a Windows host'
        _setup_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should equal "[exec_in_wsl][${PROJECT_ROOT}][${_EXPECTED_EXEC_SCRIPT}]${_FORWARDED_ARGS_OUTPUT}"
        The output should not include 'run_local'
        The status should be success
      End

      It 'Then: [Normal] T-RUN-DSP-06: calls exec_in_wsl without warnings when no commands are missing'
        _setup_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The output should start with '[exec_in_wsl]'
        The stderr should be blank
        The status should be success
      End
    End

    # On Windows without a callable wsl.exe, do not run silently; report the reason in one line
    Describe 'When: error cases'
      It 'Then: [Error] T-RUN-DSP-03: fails with a one-line error on a Windows host that cannot invoke wsl.exe'
        _setup_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The lines of stderr should equal 1
        The stderr should include 'wsl.exe'
        The output should be blank
        The status should equal 1
      End

      It 'Then: [Error] T-RUN-DSP-04: returns the run_local exit code unchanged on the local path'
        _setup_failing_dispatch_stubs "$_WSL_MISSING"
        When call dispatch "$_LOCAL_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The status should equal "$_DSP_STUB_EXIT_CODE"
      End

      It 'Then: [Error] T-RUN-DSP-05: returns the exec_in_wsl exit code unchanged on the WSL path'
        _setup_failing_dispatch_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The status should equal "$_DSP_STUB_EXIT_CODE"
      End

      It 'Then: [Error] T-RUN-DSP-07: fails with a one-line error and does not launch WSL when a required command is missing in WSL'
        _setup_missing_commands_stubs "$_WSL_AVAILABLE"
        When call dispatch "$_WINDOWS_OS_NAME" "$_SPEC_ARG" "$_OPTION_ARG"
        The lines of stderr should equal 1
        The stderr should include "$_DSP_MISSING_COMMAND"
        The output should be blank
        The status should equal 1
      End
    End
  End

  #
  # Behavior when actually launched as the entry point. It is a thin layer that only passes
  # the uname result to dispatch(), so it is verified as an integration test in a separate process
  #
  Describe 'T-RUN-MSL: main()'
    Before 'setup_shellspec_stub'
    After 'teardown_shellspec_stub'

    # With WSL disabled, the executor runs in this shell on any host
    Describe 'When: normal cases'
      It 'Then: [Normal] T-RUN-MSL-01: with SHELLSPEC_NO_WSL=1, arguments reach ShellSpec through the executor'
        When run env SHELLSPEC="$_SHELLSPEC_STUB" SHELLSPEC_NO_WSL=1 bash "$SCRIPT" "$_SPEC_ARG"
        The output should equal "[${_SPEC_ARG}]"
        The status should be success
      End
    End
  End
End
