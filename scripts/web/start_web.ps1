<#
.SYNOPSIS
  Preview build/web using static server (Node)

.DESCRIPTION
  Start Node static HTTP server pointing to build\web, auto-open browser.
  - Supports WASM and common MIME types, auto-adds necessary Cross-Origin headers (COOP/COEP).
  Note: you must run `flutter build web --release` first to have build\web.

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
  throw "[ERROR] build\web not found. Please run: scripts\build_tools\build_web.ps1 (or flutter build web --release)"
}

Write-Section 'Start static server for build\web (Node)'
Write-Host "Project path: $root"
Write-Host "Web dir:      $webDir"
Write-Host "Port:         $Port"
Write-Host ''

# Get Node command
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
  throw "[ERROR] Node.js (node) not found. Please install Node.js and add node to PATH."
}
$nodeFile = $nodeCmd.Source

# Node server script path
$serverScript = Join-Path $PSScriptRoot 'server.js'

if (-not (Test-Path $serverScript)) {
  throw "[ERROR] Node server script not found: $serverScript"
}

Write-Host "Node:         $nodeFile"
Write-Host "Server:       $serverScript"
Write-Host ''

# Open browser first (server will block in foreground)
$url = "http://127.0.0.1:$Port/"
Write-Host "Open:         $url"
Open-Url $url

# Start Node server
& $nodeFile $serverScript $Port $webDir