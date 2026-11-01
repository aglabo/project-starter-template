#!/usr/bin/env bash
# src: runners/run-actionlint.sh
# @(#) : action lint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Init directory variables
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# load  utility library
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# @description Run jactionlint with the checked-in config,
#              or with the global config when the checked-in one is absent
# @arg $@ Arguments forwarded to jactionlint
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
# @exitcode Exit code of jactionlint otherwise
main() {
  local configFile
  local exit_code=0
  configFile="$(resolve_config_file 'jactionlint/jactionlint.yaml' 'configs/jactionlint.yaml')" || exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo "Error: config file not found: configs/jactionlint.yaml (local) or jactionlint/jactionlint.yaml (global config dir)" >&2
    return "$EXIT_CONFIG_NOT_FOUND"
  fi

  jactionlint --config-file "$configFile" "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
