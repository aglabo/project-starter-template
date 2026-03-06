# src: /scripts/libs/AgInstaller.ps1
# @(#) : Package installer library
#
# Copyright (c) 2026- Furukawa Atsushi <atsushifx@gmail.com>
# Released under the MIT License.

<#
.SYNOPSIS
    Generates parameters for eget.

.DESCRIPTION
    Accepts a "name,repo" format string and returns parameters to pass to eget (--to, repository name, --asset).
#>
function AgInstaller-EgetBuildParams {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Package
    )
    ($name, $repo) = $Package.Split(",").trim()
    return @("--to", "c:/app/$name.exe", $repo, "--asset", '".xz"')
}

<#
.SYNOPSIS
    Generates parameters for winget.

.DESCRIPTION
    Accepts a "name,id" format string and returns --id and --location arguments to pass to winget install.
#>
function AgInstaller-WinGetBuildParams {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Package
    )
    ($name, $id) = $Package.Split(",").trim()
    return @("--id", $id, "--location", "c:/app/develop/utils/$name")
}

<#
.SYNOPSIS
    Installs packages in batch via winget.

.DESCRIPTION
    Accepts "name,id" format packages via pipeline or argument and installs them sequentially with winget.

.PARAMETER Packages
    Package name and winget ID pair string (e.g., "git,Git.Git")

.EXAMPLE
    Install-WinGetPackages -Packages @("git,Git.Git")
.EXAMPLE
    "7zip,7zip.7zip" | Install-WinGetPackages
#>
function Install-WinGetPackages {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Packages
    )

    begin { $pkgList = @() }
    process {
        foreach ($pkg in $Packages) {
            if ($pkg -and ($pkg -notmatch '^\s*#')) {
                $pkgList += $pkg
            }
        }
    }
    end {
        if ($pkgList.Count -eq 0) {
            Write-Warning "ïýzL No valid packages to install via winget."
            return
        }

        foreach ($pkg in $pkgList) {
            $args = AgInstaller-WinGetBuildParams -Package $pkg
            Write-Host "ïýzŽ¥ Installing $pkg áäyÛØinget $($args -join ' ')" -ForegroundColor Cyan
            $args2 = @("install") + $args
            try {
                Start-Process "winget" -ArgumentList $args2 -Wait -NoNewWindow -ErrorAction Stop
            } catch {
                Write-Warning "Failed to install: $pkg"
            }
        }
        Write-Host "áús?winget packages installed." -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Installs tools via Scoop.

.DESCRIPTION
    Installs tool names passed via pipeline or argument using Scoop. Comment lines (#) are skipped.

.PARAMETER Tools
    Tool names to install

.EXAMPLE
    Install-ScoopPackages -Tools @("git", "dprint")
.EXAMPLE
    "gitleaks" | Install-ScoopPackages
#>
function Install-ScoopPackages {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Tools
    )

    begin { $toolList = @() }
    process {
        foreach ($tool in $Tools) {
            if ($tool -and ($tool -notmatch '^\s*#')) {
                $toolList += $tool
            }
        }
    }
    end {
        if ($toolList.Count -eq 0) {
            Write-Warning "ïýzL No valid tools to install via scoop."
            return
        }

        foreach ($tool in $toolList) {
            Write-Host "ïýzŽ¥ Installing: $tool" -ForegroundColor Cyan
            scoop install $tool
        }
        Write-Host "áús?Scoop tools installed." -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Installs development packages globally via pnpm.

.DESCRIPTION
    Installs packages in batch via pnpm add --global after removing comment lines.

.PARAMETER Packages
    Package name string or array

.EXAMPLE
    Install-PnpmPackages -Packages @("cspell", "secretlint")
.EXAMPLE
    "cspell" | Install-PnpmPackages
#>
function Install-PnpmPackages {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Packages
    )

    begin { $pkgList = @() }
    process {
        foreach ($pkg in $Packages) {
            if ($pkg -and ($pkg -notmatch '^\s*#')) {
                $pkgList += $pkg
            }
        }
    }
    end {
        if ($pkgList.Count -eq 0) {
            Write-Warning "ïýzL No valid packages to install."
            return
        }

        $cmd = "pnpm add --global " + ($pkgList -join " ")
        Write-Host "ïýzE Installing via pnpm: $cmd" -ForegroundColor Cyan
        Invoke-Expression $cmd
        Write-Host "áús?pnpm packages installed." -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Downloads and installs binaries from GitHub releases using eget.

.DESCRIPTION
    Accepts "name,repo" format packages via pipeline or argument, and downloads/saves .exe files using eget.

.PARAMETER Packages
    Package name and GitHub repository name pair (e.g., "codegpt,appleboy/codegpt")

.EXAMPLE
    Install-EgetPackages -Packages @("dprint,dprint/dprint")
.EXAMPLE
    "pnpm,pnpm/pnpm" | Install-EgetPackages
#>
function Install-EgetPackages {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$Packages
    )

    begin { $pkgList = @() }
    process {
        foreach ($pkg in $Packages) {
            if ($pkg -and ($pkg -notmatch '^\s*#')) {
                $pkgList += $pkg
            }
        }
    }
    end {
        if ($pkgList.Count -eq 0) {
            Write-Warning "ïýzL No valid packages to install via eget."
            return
        }

        foreach ($pkg in $pkgList) {
            $args = AgInstaller-EgetBuildParams -Package $pkg
            Write-Host "ïýzŽ¥ Installing $pkg áäyÛÆget $($args -join ' ')" -ForegroundColor Cyan
            try {
                Start-Process "eget" -ArgumentList $args -Wait -NoNewWindow -ErrorAction Stop
            } catch {
                Write-Warning "Failed to install: $pkg"
            }
        }
        Write-Host "áús?eget packages installed." -ForegroundColor Green
    }
}
