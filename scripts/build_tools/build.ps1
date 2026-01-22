<#
.SYNOPSIS
  One-click release build (Windows + Web) (PowerShell)

.DESCRIPTION
  This is a "composite script" that runs Windows + Web release builds in one go.
  By default, it executes in sequence:
  - Windows: scripts\build_tools\build_win.ps1
  - Web: scripts\build_tools\build_web.ps1

  If you only want to run one of them, use -SkipWindows / -SkipWeb.
  When deploying Web to a sub-path, use -BaseHref.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build.ps1 -BaseHref /gait_charts/

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build.ps1 -SkipWindows
#>

[CmdletBinding()]
param(
  [switch]$SkipWindows,
  [switch]$SkipWeb,
  [string]$BaseHref,
  [switch]$Wasm,
  [switch]$SkipIconUpdate
)

. "$PSScriptRoot\..\_lib\common.ps1"

Write-Section 'Release Build (Windows + Web)'

if ((-not $SkipWindows) -or (-not $SkipWeb)) {
  if (-not $SkipIconUpdate) {
    & (Join-Path $PSScriptRoot 'update_app_icon.ps1')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host ''
  }
}

if (-not $SkipWindows) {
  & (Join-Path $PSScriptRoot 'build_win.ps1')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host ''
}

if (-not $SkipWeb) {
  $webArgs = @()
  if ($BaseHref) { $webArgs += @('-BaseHref', $BaseHref) }
  if ($Wasm) { $webArgs += '-Wasm' }

  & (Join-Path $PSScriptRoot 'build_web.ps1') @webArgs
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host ''
}

Write-Host 'All builds completed.'


