<#
.SYNOPSIS
  一鍵更新 Flutter / Dart 依賴套件（PowerShell）

.DESCRIPTION
  - 顯示可更新套件：flutter pub outdated（失敗不會中止）
  - 更新依賴：flutter pub upgrade [--major-versions]
  - 重新抓取：flutter pub get

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\update_deps.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\update_deps.ps1 -Major

.EXAMPLE
  # Legacy token（對齊舊 bat 用法）：--major
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

Write-Section '依賴更新'
Write-Host "Project path: $root"
Write-Host ''

Write-Host '[1/3] 檢查可更新的套件（僅顯示）：flutter pub outdated'
Invoke-Flutter -Args @('pub', 'outdated') -IgnoreExitCode
if ($LASTEXITCODE -ne 0) {
  Write-Host '[WARN] flutter pub outdated 失敗（可能是離線/代理/憑證問題），將繼續嘗試更新。'
}
Write-Host ''

$upgrade = @('pub', 'upgrade')
if ($Major) { $upgrade += '--major-versions' }

Write-Host "[2/3] 更新依賴：flutter $($upgrade -join ' ')"
Invoke-Flutter -Args $upgrade
Write-Host ''

Write-Host '[3/3] 重新抓取依賴：flutter pub get'
Invoke-Flutter -Args @('pub', 'get')
Write-Host ''

Write-Host '依賴更新完成！'
Write-Host '- Possible changed files: pubspec.yaml / pubspec.lock'
Write-Host '- 建議：跑一次 flutter test 或 build 確認相容性'


