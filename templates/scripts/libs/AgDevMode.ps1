# src: scripts/libs/AgDevMode.ps1
# @(#): Developer mode configuration/retrieval library
#
# Copyright (c) 2026- Furukawa Atsushi <atsushifx@gmail.com>
# Released under MIT License.

## Constants
Set-Variable -Name "DEVMODE_REGPATH" -Option Constant -Value "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
Set-Variable -Name "DEVMODE_VALUE_NAME" -Option Constant -Value "AllowDevelopmentWithoutDevLicense"

## Get mode
function AgDevMode-GetMode {
<#
.SYNOPSIS
    Gets the enabled/disabled state of Windows Developer Mode.

.DESCRIPTION
    Reads the "AllowDevelopmentWithoutDevLicense" value from the "AppModelUnlock" registry key and returns a boolean indicating whether Developer Mode is enabled.

.EXAMPLE
    PS> AgDevMode-GetMode
    True

.NOTES
    Uses constants: $DEVMODE_REGPATH, $DEVMODE_VALUE_NAME
#>
    try {
        $value = Get-ItemProperty -Path $DEVMODE_REGPATH -Name $DEVMODE_VALUE_NAME -ErrorAction Stop
        return ($value.$DEVMODE_VALUE_NAME -eq 1)
    } catch {
        return $false
    }
}

## Set mode
function AgDevMode-SetMode {
<#
.SYNOPSIS
    Enables or disables Windows Developer Mode.

.DESCRIPTION
    Sets the "AllowDevelopmentWithoutDevLicense" value in the "AppModelUnlock" registry key to 1 or 0. Creates the registry key if it does not exist.

.PARAMETER Enable
    Specify -Enable to enable Developer Mode. Defaults to enabled if not specified. Use -Enable:$false to disable.

.EXAMPLE
    PS> AgDevMode-SetMode -Enable:$false

.NOTES
    Uses constants: $DEVMODE_REGPATH, $DEVMODE_VALUE_NAME
#>
    param(
        [switch]$Enable = $true
    )

    if (-not (Test-Path $DEVMODE_REGPATH)) {
        New-Item -Path $DEVMODE_REGPATH -Force | Out-Null
    }

    $value = if ($Enable) { 1 } else { 0 }
    Set-ItemProperty -Path $DEVMODE_REGPATH -Name $DEVMODE_VALUE_NAME -Value $value -ErrorAction Stop
}
