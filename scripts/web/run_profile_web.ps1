<#
.SYNOPSIS
  啟動 Flutter Web（web-server, profile）（PowerShell）

.DESCRIPTION
  profile 模式比 debug 更接近實際效能（首屏通常更快）。
  會先開啟瀏覽器，再執行 flutter run。

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

Write-Section '啟動 Flutter Web (web-server, profile)'
Write-Host "Project path: $root"
Write-Host "URL:         $url"
Write-Host ''

Write-Host '先開啟瀏覽器；若一開始顯示「無法連線」屬正常，等 Flutter 編譯完成後重整即可。'
Open-Url -Url $url
Write-Host ''
Write-Host '停止執行：請在此視窗按 Ctrl+C'
Write-Host ''

Invoke-Flutter -Args @('run', '-d', 'web-server', '--profile', '--web-port', "$Port")


