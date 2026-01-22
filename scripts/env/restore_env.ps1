<#
.SYNOPSIS
  Restore/re-fetch Flutter project dependencies (PowerShell)

.DESCRIPTION
  - flutter pub get
  - (optional) flutter pub cache repair

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\restore_env.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\restore_env.ps1 -RepairCache
#>

[CmdletBinding()]
param(
  [switch]$RepairCache
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

Write-Section 'Flutter environment restore'
Write-Host "Project path: $root"
Write-Host ''

Write-Host '[1/2] flutter pub get'
Invoke-Flutter -Args @('pub', 'get')
Write-Host ''

if ($RepairCache) {
  Write-Host '[2/2] flutter pub cache repair (may take some time)'
  Invoke-Flutter -Args @('pub', 'cache', 'repair')
  Write-Host ''
} else {
  Write-Host '[2/2] (skip) flutter pub cache repair (add -RepairCache to repair Pub cache)'
  Write-Host ''
}

Write-Host 'Environment restored successfully.'



