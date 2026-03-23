#!/usr/bin/env bash
# src: /scripts/lint-actionlint
# @(#) : Document linting and writing tools installation script
#
# Copyright (c) 2026- Furukawa Atsushi <atsushifx@gmail.com>
#
# Released under the MIT License.
# https://opensource.org/licenses/MIT

set -euo pipefail

mapfile -t files < <(git ls-files ".github/workflows/*.yml" ".github/workflows/*.yaml")

if [[ ${#files[@]} -gt 0 ]]; then
  pnpm exec actionlint "${files[@]}"
else
  echo "No workflow files found."
fi
