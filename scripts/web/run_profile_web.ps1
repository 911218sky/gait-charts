<#
.SYNOPSIS
  Start Flutter Web (web-server, profile) (PowerShell)

.DESCRIPTION
  Profile mode is closer to actual performance (first screen usually faster).
  Opens browser first, then runs flutter run.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\web\run_profile_web.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\web\run_profile_web.ps1 -Port 12067
#>

[CmdletBinding()]
param(
  [int]$Port = 12067
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

$url = "http://localhost:$Port"

Write-Section 'Start Flutter Web (web-server, profile)'
Write-Host "Project path: $root"
Write-Host "URL:         $url"
Write-Host ''

Write-Host 'Opening browser first; if it shows "cannot connect" initially, that is normal. Wait for Flutter compilation to complete, then refresh.'
Open-Url -Url $url
Write-Host ''
Write-Host 'To stop: press Ctrl+C in this window'
Write-Host ''

Invoke-Flutter -Args @('run', '-d', 'web-server', '--profile', '--web-port', "$Port")


