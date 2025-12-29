<#
.SYNOPSIS
  Windows release build（PowerShell）

.DESCRIPTION
  - flutter build windows --release --split-debug-info=build/symbols --obfuscate

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_win.ps1
#>

[CmdletBinding()]
param()

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

Write-Section 'Windows Release Build'
Write-Host "Project path: $root"
Write-Host ''

Write-Host 'Building Windows (release)...'
$args = @('build', 'windows', '--release', '--split-debug-info=build/symbols', '--obfuscate')
Write-Host ("- Command: flutter " + ($args -join ' '))
Write-Host ''

Invoke-Flutter -Args $args

Write-Host ''
Write-Host 'Build succeeded!'
Write-Host '- Windows build output: build\windows\'
Write-Host '- Symbols output:       build\symbols\'


