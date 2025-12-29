<#
.SYNOPSIS
  Update Flutter / Dart dependencies (PowerShell)

.DESCRIPTION
  - Show available updates: flutter pub outdated (failure won't stop)
  - Update dependencies: flutter pub upgrade [--major-versions]
  - Re-fetch: flutter pub get

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\update_deps.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\update_deps.ps1 -Major

.EXAMPLE
  # Legacy token (compatible with old .bat): --major
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\update_deps.ps1 --major
#>

[CmdletBinding()]
param(
  [switch]$Major,
  # Legacy style (compatible with old .bat): --major
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$LegacyArgs
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

if ($LegacyArgs -and ($LegacyArgs | Where-Object { $_ -ieq '--major' } | Select-Object -First 1)) {
  $Major = $true
}

Write-Section 'Update dependencies'
Write-Host "Project path: $root"
Write-Host ''

Write-Host '[1/3] Check available updates (display only): flutter pub outdated'
Invoke-Flutter -Args @('pub', 'outdated') -IgnoreExitCode
if ($LASTEXITCODE -ne 0) {
  Write-Host '[WARN] flutter pub outdated failed (may be offline/proxy/certificate issue), will continue trying to update.'
}
Write-Host ''

$upgrade = @('pub', 'upgrade')
if ($Major) { $upgrade += '--major-versions' }

Write-Host "[2/3] Update dependencies: flutter $($upgrade -join ' ')"
Invoke-Flutter -Args $upgrade
Write-Host ''

Write-Host '[3/3] Re-fetch dependencies: flutter pub get'
Invoke-Flutter -Args @('pub', 'get')
Write-Host ''

Write-Host 'Dependencies updated!'
Write-Host '- Possible changed files: pubspec.yaml / pubspec.lock'
Write-Host '- Recommended: run flutter test or build to verify compatibility'



