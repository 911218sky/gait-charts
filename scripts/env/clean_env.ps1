<#
.SYNOPSIS
  Clean Flutter project environment (PowerShell)

.DESCRIPTION
  Default: safe local cleanup
  - flutter clean
  - Remove: build / .dart_tool / .packages / pubspec.lock / android\.gradle (if exists)

  With -Deep: aggressive cleanup (WARNING: deletes global Pub cache, packages will be re-downloaded)
  - Remove: %LOCALAPPDATA%\Pub\Cache (or %APPDATA%\Pub\Cache)
  - iOS Pods/.symlinks (if exists)

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\clean_env.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\clean_env.ps1 -Deep -Force
#>

[CmdletBinding()]
param(
  [switch]$Deep,
  [switch]$Force
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

Write-Section 'Clean Flutter environment'
Write-Host "Project path: $root"
Write-Host ''

Write-Host '[1/3] flutter clean'
Invoke-Flutter -Args @('clean') -IgnoreExitCode
Write-Host ''

function Remove-IfExists([string]$Path) {
  if (Test-Path $Path) {
    Write-Host "  - Removing: $Path"
    Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host '[2/3] Deleting project temp/build artifacts'
Remove-IfExists (Join-Path $root 'build')
Remove-IfExists (Join-Path $root '.dart_tool')
Remove-IfExists (Join-Path $root '.packages')
Remove-IfExists (Join-Path $root 'pubspec.lock')
Remove-IfExists (Join-Path $root 'android\.gradle')
Write-Host ''

Write-Host '[3/3] Deep clean (optional)'
if (-not $Deep) {
  Write-Host '  - (skip) To delete global Pub cache / iOS Pods, add -Deep'
  Write-Host ''
  Write-Host 'Clean completed.'
  exit 0
}

if (-not $Force) {
  Write-Host '  WARNING: Deep clean will delete global Pub cache (packages will be re-downloaded).'
  $ans = Read-Host '  Continue? (y/N)'
  if ($ans -notin @('y', 'Y')) {
    Write-Host '  Cancelled.'
    exit 1
  }
}

Remove-IfExists (Join-Path $root 'ios\Pods')
Remove-IfExists (Join-Path $root 'ios\.symlinks')

if ($env:PUB_CACHE -and (Test-Path $env:PUB_CACHE)) {
  Remove-IfExists $env:PUB_CACHE
} elseif ($env:LOCALAPPDATA -and (Test-Path (Join-Path $env:LOCALAPPDATA 'Pub\Cache'))) {
  Remove-IfExists (Join-Path $env:LOCALAPPDATA 'Pub\Cache')
} elseif ($env:APPDATA -and (Test-Path (Join-Path $env:APPDATA 'Pub\Cache'))) {
  Remove-IfExists (Join-Path $env:APPDATA 'Pub\Cache')
}

Write-Host ''
Write-Host 'Deep clean completed.'



