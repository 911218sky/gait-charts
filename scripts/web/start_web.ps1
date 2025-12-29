<#
.SYNOPSIS
  以靜態 server 預覽 build/web（使用 Node）

.DESCRIPTION
  啟動 Node 靜態 HTTP Server，指向 build\web，並自動開啟瀏覽器。
  - 支援 WASM 與常見 MIME types，自動添加必要的 Cross-Origin headers（COOP/COEP）。
  注意：你必須先跑過一次 `flutter build web --release` 才會有 build\web。

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\web\start_web.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\web\start_web.ps1 -Port 8090
#>

[CmdletBinding()]
param(
  [int]$Port = 8090
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

$webDir = Join-Path $root 'build\web'
if (-not (Test-Path $webDir)) {
  throw "[ERROR] 找不到 build\web。請先執行：scripts\build_tools\build_web.ps1（或 flutter build web --release）"
}

Write-Section 'Start static server for build\web (Node)'
Write-Host "Project path: $root"
Write-Host "Web dir:      $webDir"
Write-Host "Port:         $Port"
Write-Host ''

# 取得 Node 命令
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
  throw "[ERROR] 找不到 Node.js（node）。請先安裝 Node.js 並將 node 加入 PATH。"
}
$nodeFile = $nodeCmd.Source

# Node server 腳本路徑
$serverScript = Join-Path $PSScriptRoot 'server.js'

if (-not (Test-Path $serverScript)) {
  throw "[ERROR] 找不到 Node server 腳本：$serverScript"
}

Write-Host "Node:         $nodeFile"
Write-Host "Server:       $serverScript"
Write-Host ''

# 先開啟瀏覽器（server 會阻塞在前景）
$url = "http://127.0.0.1:$Port/"
Write-Host "Open:         $url"
Open-Url $url

# 啟動 Node 服務器
& $nodeFile $serverScript $Port $webDir