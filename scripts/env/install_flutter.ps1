<#
.SYNOPSIS
  Install Flutter SDK and set environment variables (PowerShell)

.DESCRIPTION
  - Download latest stable Flutter SDK
  - Extract to specified directory (default C:\flutter)
  - Add Flutter bin to user PATH
  - Run flutter doctor to verify installation

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_flutter.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_flutter.ps1 -InstallPath "D:\dev\flutter"

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_flutter.ps1 -SkipDoctor
#>

[CmdletBinding()]
param(
  [string]$InstallPath = "C:\flutter",
  [switch]$SkipDoctor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section([string]$Title) {
  Write-Host ("=" * 60)
  Write-Host " [Flutter Install] $Title"
  Write-Host ("=" * 60)
  Write-Host ""
}

function Get-LatestFlutterUrl {
  $releasesUrl = "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
  
  Write-Host "Fetching Flutter version info..."
  $releases = Invoke-RestMethod -Uri $releasesUrl -UseBasicParsing
  
  $stableHash = $releases.current_release.stable
  $stableRelease = $releases.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1
  
  if (-not $stableRelease) {
    throw "[ERROR] Cannot get latest stable Flutter info"
  }
  
  $version = $stableRelease.version
  $downloadUrl = $releases.base_url + "/" + $stableRelease.archive
  
  return @{
    Version = $version
    Url = $downloadUrl
    FileName = [System.IO.Path]::GetFileName($stableRelease.archive)
  }
}

function Add-ToUserPath {
  param([string]$NewPath)
  
  $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  
  if ($currentPath -split ";" | Where-Object { $_ -ieq $NewPath }) {
    Write-Host "PATH already contains: $NewPath (skip)"
    return $false
  }
  
  $newPathValue = if ($currentPath) { "$currentPath;$NewPath" } else { $NewPath }
  [Environment]::SetEnvironmentVariable("PATH", $newPathValue, "User")
  
  $env:PATH = "$env:PATH;$NewPath"
  
  Write-Host "Added to PATH: $NewPath"
  return $true
}

# ============================================================
# Main
# ============================================================

Write-Section "Check existing installation"

$existingFlutter = Get-Command flutter.bat -ErrorAction SilentlyContinue
if ($existingFlutter) {
  Write-Host "Detected existing Flutter: $($existingFlutter.Source)"
  $response = Read-Host "Continue installing new version? (y/N)"
  if ($response -notmatch "^[yY]") {
    Write-Host "Installation cancelled."
    exit 0
  }
}

Write-Section "Get Flutter version"

$flutterInfo = Get-LatestFlutterUrl
Write-Host "Latest stable: $($flutterInfo.Version)"
Write-Host "Download URL: $($flutterInfo.Url)"
Write-Host ""

Write-Section "Download Flutter SDK"

$tempDir = Join-Path $env:TEMP "flutter_install"
$zipPath = Join-Path $tempDir $flutterInfo.FileName

if (-not (Test-Path $tempDir)) {
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

if (Test-Path $zipPath) {
  Write-Host "Using cached file: $zipPath"
} else {
  Write-Host "Downloading (this may take a few minutes)..."
  Write-Host "Target: $zipPath"
  
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri $flutterInfo.Url -OutFile $zipPath -UseBasicParsing
  $ProgressPreference = 'Continue'
  
  Write-Host "Download complete!"
}
Write-Host ""

Write-Section "Extract Flutter SDK"

$parentDir = Split-Path $InstallPath -Parent
if (-not (Test-Path $parentDir)) {
  New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

if (Test-Path $InstallPath) {
  Write-Host "Target directory exists: $InstallPath"
  $response = Read-Host "Delete and reinstall? (y/N)"
  if ($response -match "^[yY]") {
    Write-Host "Removing old version..."
    Remove-Item $InstallPath -Recurse -Force
  } else {
    Write-Host "Installation cancelled."
    exit 0
  }
}

Write-Host "Extracting to: $parentDir"
Write-Host "This may take a few minutes..."

Expand-Archive -Path $zipPath -DestinationPath $parentDir -Force

Write-Host "Extraction complete!"
Write-Host ""

Write-Section "Set environment variables"

$flutterBin = Join-Path $InstallPath "bin"

if (-not (Test-Path $flutterBin)) {
  throw "[ERROR] Flutter bin directory not found: $flutterBin"
}

$pathAdded = Add-ToUserPath -NewPath $flutterBin

if ($pathAdded) {
  Write-Host ""
  Write-Host "[IMPORTANT] PATH updated. Please restart terminal for changes to take effect."
  Write-Host "            Or run this command to reload:"
  Write-Host '            $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")'
}
Write-Host ""

Write-Section "Verify installation"

$flutterExe = Join-Path $flutterBin "flutter.bat"

Write-Host "Flutter path: $flutterExe"
Write-Host ""

& $flutterExe --version

if (-not $SkipDoctor) {
  Write-Host ""
  Write-Section "Run Flutter Doctor"
  & $flutterExe doctor
}

Write-Host ""
Write-Section "Installation complete"

Write-Host "Flutter $($flutterInfo.Version) installed to: $InstallPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart terminal (for PATH to take effect)"
Write-Host "  2. Run 'flutter doctor' to check other dependencies"
Write-Host "  3. Install Android Studio for Android development"
Write-Host ""
