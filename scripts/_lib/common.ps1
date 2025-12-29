<#
.SYNOPSIS
  Gait Charts scripts common utility functions (PowerShell)

.DESCRIPTION
  Provides shared utilities for scripts:
  - Get project root directory (inferred from scripts/ location)
  - Resolve and invoke flutter / python commands uniformly
  - Unified output formatting and error handling
  - Open browser (prefer Chrome, fallback to Edge / default browser)
  - Gradle daemon stop / transforms cache cleanup (fixes metadata.bin read errors)
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
  <#
  .SYNOPSIS
    Get project root directory (parent of scripts/)
  #>
  # File location: scripts\_lib\common.ps1
  # Project root = two levels up from common.ps1 directory
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-Section([string]$Title) {
  Write-Host ("=" * 60)
  Write-Host " [Gait Charts] $Title"
  Write-Host ("=" * 60)
  Write-Host ""
}

function Resolve-FlutterCommand {
  <#
  .SYNOPSIS
    Resolve Flutter command (prefer flutter.bat on Windows)
  #>
  $cmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  throw "[ERROR] Flutter not found. Please ensure Flutter SDK is installed and Flutter SDK bin is added to PATH."
}

function Invoke-Flutter {
  <#
  .SYNOPSIS
    Invoke flutter (unified entry point, avoids PATH/extension resolution differences)
  #>
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args,
    [switch]$IgnoreExitCode
  )

  $flutter = Resolve-FlutterCommand
  & $flutter @Args
  $code = $LASTEXITCODE
  if (-not $IgnoreExitCode -and $code -ne 0) {
    $joined = ($Args -join " ")
    throw "[ERROR] flutter failed (exit=$code): $flutter $joined"
  }
  return $code
}

function Resolve-PythonCommand {
  <#
  .SYNOPSIS
    Resolve Python command (prefer python, fallback to py -3)
  #>
  $py = Get-Command python -ErrorAction SilentlyContinue
  if ($py) {
    return @{
      File = $py.Source
      PrefixArgs = @()
    }
  }

  $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
  if ($pyLauncher) {
    return @{
      File = $pyLauncher.Source
      PrefixArgs = @("-3")
    }
  }

  throw "[ERROR] Python not found (python / py). Please install Python or add it to PATH."
}

function Open-Url {
  <#
  .SYNOPSIS
    Open URL (prefer Chrome, fallback to Edge, then default browser)
  #>
  param([Parameter(Mandatory = $true)][string]$Url)

  $chrome = @(
    (Get-Command chrome -ErrorAction SilentlyContinue | ForEach-Object Source),
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

  if ($chrome) {
    Start-Process -FilePath $chrome -ArgumentList @($Url) | Out-Null
    return
  }

  $edge = (Get-Command msedge -ErrorAction SilentlyContinue | ForEach-Object Source)
  if ($edge) {
    Start-Process -FilePath $edge -ArgumentList @($Url) | Out-Null
    return
  }

  Start-Process -FilePath $Url | Out-Null
}

function Stop-GradleDaemon {
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $gradlew = Join-Path $ProjectRoot "android\gradlew.bat"
  if (Test-Path $gradlew) {
    Push-Location (Join-Path $ProjectRoot "android")
    try {
      & $gradlew --stop | Out-Null
    } finally {
      Pop-Location
    }
  }
}

function Get-GradleWrapperVersion {
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $prop = Join-Path $ProjectRoot "android\gradle\wrapper\gradle-wrapper.properties"
  if (-not (Test-Path $prop)) { return $null }

  $line = (Get-Content $prop | Where-Object { $_ -match "^\s*distributionUrl=" } | Select-Object -First 1)
  if (-not $line) { return $null }

  $url = ($line -split "=", 2)[1]
  if ($url -match "gradle-([0-9.]+)-(all|bin)\.zip") {
    return $Matches[1]
  }
  return $null
}

function Clear-GradleTransformsCache {
  <#
  .SYNOPSIS
    Clear Gradle transforms cache (fixes metadata.bin read errors)
  #>
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $ver = Get-GradleWrapperVersion -ProjectRoot $ProjectRoot
  $cachesRoot = Join-Path $env:USERPROFILE ".gradle\caches"

  if ($ver) {
    $target = Join-Path $cachesRoot "$ver\transforms"
    Write-Host "[FixGradle] Detected Gradle: $ver"
    if (Test-Path $target) {
      Write-Host "[FixGradle] Deleting: $target"
      Remove-Item $target -Recurse -Force
    } else {
      Write-Host "[FixGradle] Not found (skip): $target"
    }
    return
  }

  Write-Host "[FixGradle] Could not detect Gradle version. Will try to delete all caches\*\transforms"
  if (Test-Path $cachesRoot) {
    Get-ChildItem $cachesRoot -Directory -ErrorAction SilentlyContinue |
      ForEach-Object {
        $t = Join-Path $_.FullName "transforms"
        if (Test-Path $t) {
          Write-Host "[FixGradle] Deleting: $t"
          Remove-Item $t -Recurse -Force
        }
      }
  }
}


