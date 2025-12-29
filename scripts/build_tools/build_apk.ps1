<#
.SYNOPSIS
  打包 Android APK / AAB（PowerShell）

.DESCRIPTION
  預設：Release APK + split per ABI（檔案較小）。
  亦支援：Debug APK、Release 不 split、Google Play 用 AAB、
  以及 FixGradle（修復 Gradle transforms cache 的 metadata.bin 讀取錯誤）。

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1 -Mode Debug

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1 -Mode Release -SplitPerAbi:$false

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1 -Target Aab

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1 -FixGradle

.EXAMPLE
  # Legacy tokens（對齊舊 bat 用法）：release fixgradle nosplit / aab
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_apk.ps1 release fixgradle
#>

[CmdletBinding()]
param(
  [ValidateSet('Release', 'Debug')]
  [string]$Mode = 'Release',

  [ValidateSet('Apk', 'Aab')]
  [string]$Target = 'Apk',

  [bool]$SplitPerAbi = $true,

  [switch]$FixGradle,

  # Legacy style (compatible with old .bat tokens):
  #   release|debug, split|nosplit, fixgradle, aab
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$LegacyArgs
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

if ($LegacyArgs) {
  foreach ($t in $LegacyArgs) {
    if (-not $t) { continue }
    switch -Regex ($t.ToLowerInvariant()) {
      '^debug$' { $Mode = 'Debug'; continue }
      '^release$' { $Mode = 'Release'; continue }
      '^split$' { $SplitPerAbi = $true; continue }
      '^nosplit$' { $SplitPerAbi = $false; continue }
      '^fixgradle$' { $FixGradle = $true; continue }
      '^aab$' { $Target = 'Aab'; $Mode = 'Release'; $SplitPerAbi = $false; continue }
      default { }
    }
  }
}

Write-Section 'Android Build'
Write-Host "Project path: $root"
Write-Host ''

if ($FixGradle) {
  Write-Host '[FixGradle] Stop Gradle daemon + clear transforms cache'
  Stop-GradleDaemon -ProjectRoot $root
  Clear-GradleTransformsCache -ProjectRoot $root
  Write-Host ''
}

if ($Target -eq 'Aab') {
  Write-Host '[1/1] flutter build appbundle --release --no-tree-shake-icons'
  Invoke-Flutter -Args @('build', 'appbundle', '--release', '--no-tree-shake-icons')
  Write-Host ''
  Write-Host 'Build succeeded!'
  Write-Host 'Output: build\app\outputs\bundle\release\app-release.aab'
  exit 0
}

$args = @('build', 'apk', '--no-tree-shake-icons')
if ($Mode -eq 'Release') {
  $args += '--release'
  if ($SplitPerAbi) { $args += '--split-per-abi' }
} else {
  $args += '--debug'
}

Write-Host "[3/3] flutter $($args -join ' ')"
Invoke-Flutter -Args $args
Write-Host ''

Write-Host 'Build succeeded!'
Write-Host 'Output folder: build\app\outputs\flutter-apk\'
if ($Mode -eq 'Release') {
  Write-Host ("Split per ABI: " + ($(if ($SplitPerAbi) { 'enabled' } else { 'disabled' })))
}

