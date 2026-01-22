<#
.SYNOPSIS
  Flutter Web release build (PowerShell)

.DESCRIPTION
  - Only responsible for `flutter build web` output to build/web

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1

.EXAMPLE
  # Disable WASM (avoid needing COOP/COEP headers; deployment on regular static hosts is less prone to issues)
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1 -NoWasm

.EXAMPLE
  # Generate source maps (fewer DevTools warnings, but larger files; evaluate whether to deploy)
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1 -SourceMaps
#>

[CmdletBinding()]
param(
  # WASM: disabled by default (if deployment environment doesn't set COOP/COEP, Chrome will issue warnings/restrictions for SharedArrayBuffer-type features)
  # Use -Wasm to force enable; use -NoWasm to disable
  [switch]$Wasm,
  [switch]$NoWasm,

  # Source maps: disabled by default; use -SourceMaps to reduce "Missing source maps" warnings in DevTools
  [switch]$SourceMaps,
  [switch]$NoSourceMaps,

  # By default, icon tree-shaking is enabled (reduces font file size); use -NoTreeShakeIcons to disable
  [switch]$NoTreeShakeIcons,
  # Legacy style (compatible with old .bat):
  #   scripts\build_web.bat wasm
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$LegacyArgs
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

$tokens = @()
if ($LegacyArgs) { $tokens += $LegacyArgs }

# WASM enabled by default
$wasmEnabled = $true

# Source maps disabled by default
$sourceMapsEnabled = $false

foreach ($t in $tokens) {
  if (-not $t) { continue }
  if ($t -ieq 'wasm') {
    $wasmEnabled = $true
  } elseif ($t -ieq 'nowasm') {
    $wasmEnabled = $false
  } elseif ($t -ieq 'sourcemaps') {
    $sourceMapsEnabled = $true
  } elseif ($t -ieq 'nosourcemaps') {
    $sourceMapsEnabled = $false
  }
}

# CLI flags override token/default
if ($Wasm) { $wasmEnabled = $true }
if ($NoWasm) { $wasmEnabled = $false }
if ($SourceMaps) { $sourceMapsEnabled = $true }
if ($NoSourceMaps) { $sourceMapsEnabled = $false }

$flags = @('--release', '-O4', '--no-wasm-dry-run')
if ($wasmEnabled) { $flags += '--wasm' }
if ($NoTreeShakeIcons) { $flags += '--no-tree-shake-icons' }
if ($sourceMapsEnabled) { $flags += '--source-maps' } else { $flags += '--no-source-maps' }

Write-Section 'Web Release Build'
Write-Host "Project path: $root"
Write-Host ''

Write-Host ("Building Web (release): flutter build web " + ($flags -join ' '))
Invoke-Flutter -Args (@('build', 'web') + $flags)

Write-Host ''
Write-Host 'Web build succeeded!'
Write-Host '- Web build output: build\web\'
