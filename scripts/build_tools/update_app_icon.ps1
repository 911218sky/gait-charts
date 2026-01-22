<#
.SYNOPSIS
  Update App Icon (SVG -> PNG) and regenerate launcher icons (PowerShell)

.DESCRIPTION
  flutter_launcher_icons does not support SVG directly. This script treats the
  SVG as the source of truth:
  - If assets/icon/app_icon.png is missing or older than app_icon.svg, export a
    new PNG using Inkscape.
  - Then run flutter_launcher_icons to generate platform icons.

  Requirements:
  - Install Inkscape and make sure "inkscape" is available in PATH (recommended),
    or installed in the default location.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\update_app_icon.ps1

.EXAMPLE
  # If you already prepared app_icon.png manually, skip SVG export and only generate icons.
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\update_app_icon.ps1 -SkipSvgExport
#>

[CmdletBinding()]
param(
  [string]$SvgPath = "assets\icon\app_icon.svg",
  [string]$PngPath = "assets\icon\app_icon.png",
  [int]$PngSize = 1024,
  # If Inkscape is missing, install it via winget (non-interactive).
  [switch]$InstallInkscape,
  [switch]$SkipSvgExport,
  [switch]$SkipGenerateIcons
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

function Resolve-Inkscape {
  $cmd = Get-Command inkscape -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $candidates = @(
    "$env:ProgramFiles\Inkscape\bin\inkscape.exe",
    "$env:ProgramFiles\Inkscape\inkscape.exe",
    "$env:ProgramFiles(x86)\Inkscape\bin\inkscape.exe",
    "$env:ProgramFiles(x86)\Inkscape\inkscape.exe"
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

  if ($candidates) { return $candidates }
  return $null
}

function Install-InkscapeViaWinget {
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    throw "[ERROR] winget not found. Please install Inkscape manually, or export PNG yourself and rerun with -SkipSvgExport."
  }

  Write-Host "Inkscape not found. Installing via winget..."
  $args = @(
    'install',
    '--id', 'Inkscape.Inkscape',
    '--exact',
    '--source', 'winget',
    '--accept-source-agreements',
    '--accept-package-agreements',
    '--silent'
  )
  Write-Host ("- Command: winget " + ($args -join ' '))
  & $winget.Source @args
  if ($LASTEXITCODE -ne 0) {
    throw "[ERROR] winget install Inkscape failed (exit=$LASTEXITCODE)."
  }
  Write-Host "Inkscape installed."
  Write-Host ""
}

function Should-ExportSvgToPng([string]$svg, [string]$png) {
  if (-not (Test-Path $png)) { return $true }
  if (-not (Test-Path $svg)) { return $false }

  $svgTime = (Get-Item $svg).LastWriteTimeUtc
  $pngTime = (Get-Item $png).LastWriteTimeUtc
  return $svgTime -gt $pngTime
}

Write-Section "Update App Icon"
Write-Host "Project path: $root"
Write-Host "SVG: $SvgPath"
Write-Host "PNG: $PngPath"
Write-Host ""

if (-not (Test-Path $SvgPath)) {
  throw "[ERROR] SVG not found: $SvgPath"
}

if (-not $SkipSvgExport) {
  $needExport = Should-ExportSvgToPng -svg $SvgPath -png $PngPath
  if ($needExport) {
    $inkscape = Resolve-Inkscape
    if (-not $inkscape -and $InstallInkscape) {
      Install-InkscapeViaWinget
      $inkscape = Resolve-Inkscape
    }
    if (-not $inkscape) {
      $msg = @(
        "[ERROR] Need to export SVG to PNG, but Inkscape was not found.",
        "",
        "Fix options:",
        "1) Install Inkscape (or rerun with -InstallInkscape to auto-install via winget), then rerun this script; or",
        "2) Manually export $SvgPath to $PngPath (suggested: 1024x1024 PNG), then rerun with -SkipSvgExport."
      ) -join "`r`n"
      throw $msg
    }

    Write-Host "Exporting PNG via Inkscape..."
    Write-Host "- Command: $inkscape `"$SvgPath`" --export-type=png --export-filename=`"$PngPath`" -w $PngSize -h $PngSize"
    & $inkscape "$SvgPath" --export-type=png --export-filename="$PngPath" -w $PngSize -h $PngSize
    if ($LASTEXITCODE -ne 0) {
      throw "[ERROR] Inkscape export failed (exit=$LASTEXITCODE)."
    }
    Write-Host "PNG exported: $PngPath"
    Write-Host ""
  } else {
    Write-Host "PNG is up-to-date (skip SVG export)."
    Write-Host ""
  }
}

if (-not (Test-Path $PngPath)) {
  throw "[ERROR] PNG not found: $PngPath (flutter_launcher_icons requires a PNG source image)."
}

if (-not $SkipGenerateIcons) {
  Write-Host "Running flutter pub get..."
  Invoke-Flutter -Args @('pub', 'get')
  Write-Host ""

  Write-Host "Generating launcher icons (flutter_launcher_icons)..."
  Invoke-Flutter -Args @('pub', 'run', 'flutter_launcher_icons')
  Write-Host ""
  Write-Host "Launcher icons updated!"
}


