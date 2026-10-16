#!/usr/bin/env bash
# runners/libs/__tests__/unit/wsl.lib.spec.sh
# @(#) : BDD unit tests for wsl.lib.sh
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# shellcheck shell=bash
# wsl.lib.spec.sh - BDD spec for wsl.lib.sh

# --- Test infrastructure ---------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/__tests__/spec_helper.sh"

# --- Target under test -----------------------------------------------------

Include "${SHELLSPEC_PROJECT_ROOT}/runners/libs/wsl.lib.sh"

# --- Internal helpers ------------------------------------------------------

# Constants

# `uname -s` values that is_windows_host() must treat as a Windows host (input table for T-RUN-IWH-01)
%const _IWH_WINDOWS_OS_NAMES: MINGW64_NT-10.0-26200 MSYS_NT-10.0-26200 CYGWIN_NT-10.0

# `uname -s` values that is_windows_host() must not treat as a Windows host (input table for T-RUN-IWH-02)
%const _IWH_OTHER_OS_NAMES: Linux Darwin

# The lib under test. Kept as an absolute path because the PATH-swapped probe loads it
_WSL_LIB="${SHELLSPEC_PROJECT_ROOT}/runners/libs/wsl.lib.sh"

# Windows-side current directory passed to exec_in_wsl() (the `wsl.exe --cd` argument)
_EIW_WIN_CWD='C:\ws\deckrd'

# Script passed to exec_in_wsl() to run on the WSL side (relative to cwd)
_EIW_SCRIPT='runners/exec/shellspec-exec.sh'

# Exit code returned by the failing stub. Neither 0 nor 1, so pass-through is distinguishable
_EIW_STUB_EXIT_CODE=3

# Commands checked by find_missing_wsl_commands() that are callable inside the fake WSL
# (input for T-RUN-FMW-01/04. Names not listed here are treated as "missing commands")
_FMW_PRESENT_COMMANDS=('bash' 'git' 'rg')

# Argument list mixing in exactly 1 command absent from the fake WSL (input for T-RUN-FMW-02)
_FMW_ONE_MISSING_COMMANDS=('bash' 'jq' 'git')

# The entries of _FMW_ONE_MISSING_COMMANDS not callable inside the fake WSL (expected output for T-RUN-FMW-02)
_FMW_ONE_MISSING_EXPECTED='jq'

# Argument list mixing in 2 commands absent from the fake WSL (input for T-RUN-FMW-03)
_FMW_TWO_MISSING_COMMANDS=('jq' 'bash' 'fzf')

# The entries of _FMW_TWO_MISSING_COMMANDS not callable inside the fake WSL, in argument order (expected output for T-RUN-FMW-03)
_FMW_TWO_MISSING_EXPECTED=('jq' 'fzf')

# Number of wsl.exe launches. Must stay at this count no matter how many commands are checked (expected value for T-RUN-FMW-04)
_FMW_EXPECTED_WSL_CALLS=1

# Functions

#
# @description Build a stub environment for swapping PATH. To avoid depending on the real wsl.exe,
#              prepare one directory with wsl.exe and one without, and place a probe script
#              that calls is_wsl_available() with the given PATH.
#              Passing PATH via env(1) makes env itself look up bash in the new PATH and
#              fail, so the PATH swap happens inside the probe
# @arg none
# @return 0 when the stub tree is ready
# @sideeffect Sets _STUB_DIR, _WSL_BIN_DIR, _EMPTY_BIN_DIR and _WSL_PROBE
# @sideeffect Creates those directories, the wsl.exe stub and the probe script on disk
#
_setup_wsl_path_probe() {
  make_temp_dir _STUB_DIR || return 1
  _WSL_BIN_DIR="${_STUB_DIR}/with-wsl"
  _EMPTY_BIN_DIR="${_STUB_DIR}/without-wsl"
  mkdir -p "$_WSL_BIN_DIR" "$_EMPTY_BIN_DIR"

  # shellcheck disable=SC2016 # stub body, expanded when the stub runs
  write_bash_stub "${_WSL_BIN_DIR}/wsl.exe" 'printf "[%s]" "$@"'

  _WSL_PROBE="${_STUB_DIR}/is-wsl-available-probe.sh"
  # shellcheck disable=SC2016 # Script body written to the probe. Must not be expanded here
  write_bash_stub "$_WSL_PROBE" \
    'PATH="$1"' \
    "$(printf '. %q' "$_WSL_LIB")" \
    'is_wsl_available'
}

#
# @description Remove the stub environment created by _setup_wsl_path_probe()
# @arg none
# @return 0 always
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
_teardown_wsl_path_probe() {
  remove_temp_dir _STUB_DIR
  unset _WSL_BIN_DIR _EMPTY_BIN_DIR _WSL_PROBE
}

#
# @description Replace wsl.exe with a shell function that only prints its arguments as [%s].
#              Used to observe the argument list built by exec_in_wsl() as-is
# @arg none
# @return 0 always
# @sideeffect Defines the wsl.exe shell function
#
_setup_wsl_exe_stub() {
  # shellcheck disable=SC2329 # Called indirectly from exec_in_wsl()
  wsl.exe() { printf '[%s]' "$@"; }
}

#
# @description Replace wsl.exe with a shell function that fails with _EIW_STUB_EXIT_CODE
# @arg none
# @return 0 always
# @sideeffect Defines the wsl.exe shell function
#
_setup_failing_wsl_exe_stub() {
  # shellcheck disable=SC2329 # Called indirectly from exec_in_wsl()
  wsl.exe() { return "$_EIW_STUB_EXIT_CODE"; }
}

#
# @description Remove the wsl.exe stub function
# @arg none
# @return 0 always
# @sideeffect Undefines the wsl.exe shell function
#
_teardown_wsl_exe_stub() {
  unset -f wsl.exe
}

#
# @description Replace wsl.exe with a shell function that acts as a fake WSL.
#              It extracts `-c <probe>` from the arguments and runs the probe with bash, using a PATH
#              set to a bin directory containing only _FMW_PRESENT_COMMANDS.
#              Depends on neither the real WSL nor the real PATH.
#              bash cannot be found from the swapped PATH, so bash is launched by absolute path.
#              Each launch appends 1 line to _FMW_CALL_LOG so the launch count can be counted later
# @arg none
# @return 0 when the fake WSL is ready
# @sideeffect Sets _FMW_STUB_DIR, _FMW_WSL_BIN, _FMW_CALL_LOG and _FMW_BASH
# @sideeffect Creates the fake bin tree and defines the wsl.exe shell function
#
_setup_fake_wsl() {
  make_temp_dir _FMW_STUB_DIR || return 1
  _FMW_WSL_BIN="${_FMW_STUB_DIR}/bin"
  _FMW_CALL_LOG="${_FMW_STUB_DIR}/wsl-calls.log"
  _FMW_BASH="$(command -v bash)"
  mkdir -p "$_FMW_WSL_BIN"
  : >"$_FMW_CALL_LOG"

  local __command
  for __command in "${_FMW_PRESENT_COMMANDS[@]}"; do
    write_bash_stub "${_FMW_WSL_BIN}/${__command}"
  done

  # shellcheck disable=SC2329 # Called indirectly from find_missing_wsl_commands()
  wsl.exe() {
    printf 'wsl.exe\n' >>"$_FMW_CALL_LOG"
    local __probe=''
    while (($# > 0)); do
      if [[ "$1" == '-c' ]]; then
        __probe="$2"
        shift 2
        break
      fi
      shift
    done
    # Drop the word that becomes $0 in `bash -c <script> <$0> <args>...`, keeping only the commands to check
    if (($# > 0)); then
      shift
    fi
    PATH="$_FMW_WSL_BIN" "$_FMW_BASH" -c "$__probe" 'wsl-probe' "$@"
  }
}

#
# @description Clean up the fake WSL created by _setup_fake_wsl()
# @arg none
# @return 0 always
# @sideeffect Deletes _FMW_STUB_DIR, undefines wsl.exe and unsets the stub variables
#
_teardown_fake_wsl() {
  remove_temp_dir _FMW_STUB_DIR
  unset -f wsl.exe
  unset _FMW_WSL_BIN _FMW_CALL_LOG _FMW_BASH
}

#
# @description Return the number of fake WSL launches recorded by _setup_fake_wsl()
# @arg none
# @return 0 when at least one launch was recorded
# @stdout The number of wsl.exe launches recorded so far
#
_fake_wsl_call_count() {
  grep -c . "$_FMW_CALL_LOG"
}

# --- Test body -------------------------------------------------------------

#
# Lib responsible only for Windows host detection and delegation to WSL.
#
Describe 'wsl.lib.sh'
  #
  # Pure function that decides whether this is a Windows shell environment from `uname -s` alone.
  # It does not call uname itself, so OS names can be fed in from a table
  #
  Describe 'T-RUN-IWH: is_windows_host()'
    # uname -s on Git Bash / MSYS2 / Cygwin indicates a Windows host
    Describe 'When: Normal cases'
      # shellcheck disable=SC2086 # Split the %const table into one word per case
      Parameters:value $_IWH_WINDOWS_OS_NAMES

      It "Then: [Normal] T-RUN-IWH-01: treats OS name $1 as a Windows host"
        When call is_windows_host "$1"
        The status should be success
      End
    End

    # Non-Windows OS names must not pass the check
    Describe 'When: Error cases'
      # shellcheck disable=SC2086 # Split the %const table into one word per case
      Parameters:value $_IWH_OTHER_OS_NAMES

      It "Then: [Error] T-RUN-IWH-02: does not treat OS name $1 as a Windows host"
        When call is_windows_host "$1"
        The status should be failure
      End
    End

    # Callers that failed to get uname may pass an empty string
    Describe 'When: Edge cases'
      It 'Then: [Edge] T-RUN-IWH-03: does not treat an empty OS name as a Windows host'
        When call is_windows_host ''
        The status should be failure
      End
    End
  End

  #
  # Decides whether wsl.exe can be called from this shell.
  # To avoid depending on the real WSL, verify via a probe with a swapped PATH
  #
  Describe 'T-RUN-IWA: is_wsl_available()'
    Before '_setup_wsl_path_probe'
    After '_teardown_wsl_path_probe'

    Describe 'When: Normal cases'
      It 'Then: [Normal] T-RUN-IWA-01: returns success when wsl.exe is on PATH'
        When run bash "$_WSL_PROBE" "$_WSL_BIN_DIR"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      It 'Then: [Error] T-RUN-IWA-02: returns failure when wsl.exe is not on PATH'
        When run bash "$_WSL_PROBE" "$_EMPTY_BIN_DIR"
        The status should be failure
      End
    End
  End

  #
  # Runs a script on WSL. Variables holding Windows-side paths are not passed through;
  # only SKIP_INTEGRATION_TESTS is passed via env(1)
  #
  Describe 'T-RUN-EIW: exec_in_wsl()'
    After '_teardown_wsl_exe_stub'

    Describe 'When: Normal cases'
      Before '_setup_wsl_exe_stub'

      It 'Then: [Normal] T-RUN-EIW-01: calls wsl.exe with --cd / -e env / bash / script / extra args in order'
        # shellcheck disable=SC2034 # Read by exec_in_wsl()
        SKIP_INTEGRATION_TESTS=0
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT" 'foo.spec.sh' '--repair'
        The output should equal "[--cd][${_EIW_WIN_CWD}][-e][env][SKIP_INTEGRATION_TESTS=0][bash][${_EIW_SCRIPT}][foo.spec.sh][--repair]"
        The status should be success
      End
    End

    Describe 'When: Edge cases'
      Before '_setup_wsl_exe_stub'

      It 'Then: [Edge] T-RUN-EIW-02: passes 1 when SKIP_INTEGRATION_TESTS is unset'
        unset SKIP_INTEGRATION_TESTS
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT"
        The output should equal "[--cd][${_EIW_WIN_CWD}][-e][env][SKIP_INTEGRATION_TESTS=1][bash][${_EIW_SCRIPT}]"
        The status should be success
      End
    End

    Describe 'When: Error cases'
      Before '_setup_failing_wsl_exe_stub'

      It 'Then: [Error] T-RUN-EIW-03: returns the wsl.exe exit code as-is'
        When call exec_in_wsl "$_EIW_WIN_CWD" "$_EIW_SCRIPT"
        The status should equal "$_EIW_STUB_EXIT_CODE"
      End
    End
  End

  #
  # Finds commands that cannot be called on the WSL side. wsl.exe is expensive to launch,
  # so it is launched only once regardless of how many commands are checked.
  # To avoid depending on the real WSL, verify via a wsl.exe stub that acts as a fake WSL
  #
  Describe 'T-RUN-FMW: find_missing_wsl_commands()'
    Before '_setup_fake_wsl'
    After '_teardown_fake_wsl'

    # If the WSL side has everything, there is nothing to tell the caller
    Describe 'When: Normal cases'
      It 'Then: [Normal] T-RUN-FMW-01: outputs nothing when all are callable inside WSL'
        When call find_missing_wsl_commands "${_FMW_PRESENT_COMMANDS[@]}"
        The output should be blank
        The status should be success
      End

      It 'Then: [Normal] T-RUN-FMW-04: launches wsl.exe only once even when checking multiple commands'
        When call find_missing_wsl_commands "${_FMW_PRESENT_COMMANDS[@]}"
        The value "$(_fake_wsl_call_count)" should equal "$_FMW_EXPECTED_WSL_CALLS"
        The status should be success
      End
    End

    # Return only the uncallable ones. Must not report available commands mixed in
    Describe 'When: Error cases'
      It 'Then: [Error] T-RUN-FMW-02: outputs only the commands missing inside WSL'
        When call find_missing_wsl_commands "${_FMW_ONE_MISSING_COMMANDS[@]}"
        The output should equal "$_FMW_ONE_MISSING_EXPECTED"
        The status should be success
      End

      It 'Then: [Error] T-RUN-FMW-03: outputs one per line in argument order when several are missing'
        When call find_missing_wsl_commands "${_FMW_TWO_MISSING_COMMANDS[@]}"
        The output should equal "$(printf '%s\n' "${_FMW_TWO_MISSING_EXPECTED[@]}")"
        The status should be success
      End
    End
  End
End
