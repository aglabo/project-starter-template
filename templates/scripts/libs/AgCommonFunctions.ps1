# src: /scripts/common/CommonFunctions.ps1
# @(#) : Common functions library
#
# Copyright (c) 2026- Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


function commandExists {
    param (
        [string]$command
    )

    try {
        & $command --version | Out-Null
        return $true
    } catch {
        return $false
    }
}
