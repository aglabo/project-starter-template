#!/usr/bin/env bash
# src: runners/run-secretlint.sh
# @(#) : secretlint runner
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# shellcheck disable=SC1091

set -euo pipefail

# Init variables
# shellcheck source=runners/libs/init-vars.lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/libs/init-vars.lib.sh"

# load utility library
# shellcheck source=runners/libs/utils.lib.sh
. "${SCRIPT_ROOT}/libs/utils.lib.sh"

# Config file path relative to the global config directory
readonly CONFIG_GLOBAL_RELPATH='secretlint.config.yaml'

# Config file path relative to PROJECT_ROOT
readonly CONFIG_LOCAL_RELPATH='configs/secretlint.config.yaml'

# Ignore file path relative to PROJECT_ROOT
# (.gitignore whitelists the tracked paths, so secretlint scans the same files as git)
readonly IGNORE_LOCAL_RELPATH='.gitignore'

# @description Run secretlint with the checked-in config,
#              or with the global config when the checked-in one is absent.
#              Secrets are masked in the output; PROJECT_ROOT/.gitignore is used as the ignore file when present
# @arg $@ string Paths to scan (default: the current directory)
# @stderr "Error: <not-found message>" when no config file is found
# @exitcode 0 No secrets found
# @exitcode 1 Secrets found
# @exitcode 78 (EXIT_CONFIG_NOT_FOUND) Config file not found
main() {
  local -a targets=("$@")
  local configFile status=0
  configFile="$(resolve_config_file "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" || status=$?
  if [[ $status -ne 0 ]]; then
    echo "Error: $(format_config_not_found "$status" "$CONFIG_GLOBAL_RELPATH" "$CONFIG_LOCAL_RELPATH")" >&2
    return "$EXIT_CONFIG_NOT_FOUND"
  fi

  local -a opts=(--secretlintrc "${configFile}" --maskSecrets)
  if [[ -f "${PROJECT_ROOT}/${IGNORE_LOCAL_RELPATH}" ]]; then
    opts+=(--secretlintignore "${PROJECT_ROOT}/${IGNORE_LOCAL_RELPATH}")
  fi
  [[ ${#targets[@]} -eq 0 ]] && targets=(.)

  secretlint "${opts[@]}" "${targets[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
  exit $?
fi
