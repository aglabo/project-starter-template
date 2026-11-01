#!/usr/bin/env bash
# src: runners/run-textlint.sh
# @(#) : textlint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Init variables
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# load utility library
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# @description Run textlint with the checked-in config,
#              or with the global config when the checked-in one is absent
# @arg $@ string Paths to lint
# @exitcode 0 All checks passed
# @exitcode 1 Lint error
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main() {
  local -a targets=("$@")
  local configFile
  local exit_code=0
  configFile="$(resolve_config_file 'linters/textlint/textlintrc.yaml' 'configs/textlintrc.yaml')" || exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    echo "Error: config file not found: configs/textlintrc.yaml (local) or linters/textlint/textlintrc.yaml (global config dir)" >&2
    return "$EXIT_CONFIG_NOT_FOUND"
  fi

  textlint --config "$configFile" --cache --cache-location .cache/textlint/textlintcache "${targets[@]+"${targets[@]}"}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
