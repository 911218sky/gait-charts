<#
.SYNOPSIS
  清理 Flutter 專案環境（PowerShell）

.DESCRIPTION
  預設做「安全的本機清理」：
  - flutter clean
  - 移除：build / .dart_tool / .packages / pubspec.lock / android\.gradle（若存在）

  若加上 -Deep，會做「重度清理」（⚠️ 會刪全域 Pub cache，套件會被重新下載）：
  - 移除：%LOCALAPPDATA%\Pub\Cache（或 %APPDATA%\Pub\Cache）
  - iOS Pods/.symlinks（若存在）

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
  Write-Host '  - (skip) 如需刪除全域 Pub cache / iOS Pods，請加 -Deep'
  Write-Host ''
  Write-Host 'Clean completed.'
  exit 0
}

if (-not $Force) {
  Write-Host '  ⚠️ Deep clean 會刪除全域 Pub cache（套件會重新下載）。'
  $ans = Read-Host '  仍要繼續嗎？(y/N)'
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


