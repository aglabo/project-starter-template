#!/usr/bin/env bash
# src: runners/libs/utils.lib.sh
# @(#): utils.lib.sh: common utility library
#
# Copyright (c) 2026- atsushifx <https://github.com/atsushifx>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Guard against double sourcing
[[ -n "${_UTILS_LIB_SH:-}" ]] && return 0
readonly _UTILS_LIB_SH=1

# Exit code returned by runners when no config file is found (EX_CONFIG, the BSD configuration error code)
# shellcheck disable=SC2034 # read by the runner scripts that source this file
readonly EXIT_CONFIG_NOT_FOUND=78

#
# @description Resolve the global (user) config directory.
#              Use XDG_CONFIG_HOME when it points to an existing directory,
#              otherwise fall back to ${HOME}/.config when it exists
# @stdout Path to the config directory; nothing when no directory exists
# @exitcode 0 Config directory found
# @exitcode 1 Config directory not found
#
resolve_global_configdir() {
  local __xdg_config="${XDG_CONFIG_HOME:-}"
  local __home_config="${HOME:-}/.config"

  if [[ -n "$__xdg_config" && -d "$__xdg_config" ]]; then
    echo "$__xdg_config"
  elif [[ -n "${HOME:-}" && -d "$__home_config" ]]; then
    echo "$__home_config"
  else
    return 1
  fi
}

#
# @description Resolve a tool config file.
#              Use the local config file in the project when it exists,
#              otherwise use the file under the global config directory when it exists.
#              Prints nothing when no file is found
# @arg $1 string Config file path relative to the global config directory
# @arg $2 string Local config file path relative to PROJECT_ROOT
# @stdout Path to the config file; nothing when no file is found
# @exitcode 0 Config file found
# @exitcode 1 Config file not found
#
resolve_config_file() {
  local __global_relpath="$1"
  local __local_config="${PROJECT_ROOT}/$2"
  local __configdir

  if [[ -f "$__local_config" ]]; then
    echo "$__local_config"
    return 0
  fi

  if __configdir="$(resolve_global_configdir)" && [[ -f "${__configdir}/${__global_relpath}" ]]; then
    echo "${__configdir}/${__global_relpath}"
    return 0
  fi

  return 1
}
