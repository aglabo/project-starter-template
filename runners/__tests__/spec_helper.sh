#!/usr/bin/env bash
# runners/__tests__/spec_helper.sh
# @(#) : common test helper for runners tests
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# spec_helper.sh - temporary directory and stub helpers shared by every runners test

# shellcheck shell=bash

# --- Constants --------------------------------------------------------------

# Base directory for build-once fixtures shared across examples.
# ShellSpec removes SHELLSPEC_TMPBASE wholesale when the run ends, so nothing leaks
# shellcheck disable=SC2034 # used by runners/libs helpers and specs
SPEC_FIXTURE_BASE="${SHELLSPEC_TMPBASE:-${TMPDIR:-/tmp}}"

# --- Temporary directories --------------------------------------------------

#
# @description Create a private temporary directory and store its path in a variable.
#              Use it for per-example trees that may be mutated; the shared fixture
#              from setup_temp_specs() is read-only
# @arg $1 string Name of the variable that receives the directory path
# @return 0 when the directory was created; 1 otherwise
# @sideeffect Sets the variable named by $1
# @sideeffect Creates the directory on disk
#
make_temp_dir() {
  local __dir
  __dir="$(mktemp -d)" || return 1
  printf -v "$1" '%s' "$__dir"
}

#
# @description Remove directories created by make_temp_dir() and unset their variables.
#              Variables that are unset or empty are skipped
# @arg $@ string Names of the variables holding the directory paths
# @return 0 always
# @sideeffect Deletes the directories and unsets the variables
#
remove_temp_dir() {
  local __var
  for __var in "$@"; do
    if [[ -n "${!__var:-}" ]]; then
      rm -rf "${!__var}"
    fi
    unset "$__var"
  done
}

# --- Stubs ------------------------------------------------------------------

#
# @description Write an executable bash script made of a shebang and the given lines.
#              Lines are written verbatim, so quote them to defer expansion to run time
# @arg $1 string Path of the script to write
# @arg $@ string Body lines (after $1)
# @return 0 when the script was written and made executable; non-zero otherwise
# @sideeffect Creates or overwrites the script at $1
#
write_bash_stub() {
  local __path="$1"
  shift
  {
    echo '#!/usr/bin/env bash'
    printf '%s\n' "$@"
  } >"$__path" && chmod +x "$__path"
}

#
# @description Install a ShellSpec stub that only prints its arguments as `[%s]`.
#              The output shows which arguments reached ShellSpec
# @arg none
# @return 0 when the stub is ready
# @sideeffect Sets _STUB_DIR and _SHELLSPEC_STUB
# @sideeffect Creates the stub directory and the stub script on disk
#
setup_shellspec_stub() {
  make_temp_dir _STUB_DIR || return 1
  _SHELLSPEC_STUB="${_STUB_DIR}/shellspec-stub"
  # shellcheck disable=SC2016 # stub body, expanded when the stub runs
  write_bash_stub "$_SHELLSPEC_STUB" 'printf "[%s]" "$@"'
}

#
# @description Remove the stub installed by setup_shellspec_stub() or any other setup
#              that stores its stub in _STUB_DIR / _SHELLSPEC_STUB
# @arg none
# @return 0 always
# @sideeffect Deletes _STUB_DIR and unsets the stub variables
#
teardown_shellspec_stub() {
  remove_temp_dir _STUB_DIR
  unset _SHELLSPEC_STUB
}
