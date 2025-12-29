<#
.SYNOPSIS
  Flutter Web release build（PowerShell）

.DESCRIPTION
  - 只負責 `flutter build web` 產出 build/web

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1

.EXAMPLE
  # 關閉 WASM（避免需要 COOP/COEP headers；部署在一般靜態主機時比較不會踩雷）
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1 -NoWasm

.EXAMPLE
  # 產出 source maps（DevTools 警告會少很多，但檔案會變大；是否上線請自行評估）
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_web.ps1 -SourceMaps
#>

[CmdletBinding()]
param(
  # Wasm：預設關閉（部署環境若沒設定 COOP/COEP，Chrome 會對 SharedArrayBuffer 類型功能提出警告/限制）
  # 如需強制開啟可用 -Wasm；關閉用 -NoWasm
  [switch]$Wasm,
  [switch]$NoWasm,

  # Source maps：預設關閉；需要減少 DevTools 的 "Missing source maps" 類警告時可用 -SourceMaps
  [switch]$SourceMaps,
  [switch]$NoSourceMaps,

  # 預設會啟用 icon tree-shaking（減少字型檔體積）；如需關閉可用 -NoTreeShakeIcons
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

# 預設開啟 WASM
$wasmEnabled = $true

# 預設關閉 source maps
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

# CLI flags 覆寫 token/預設
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
