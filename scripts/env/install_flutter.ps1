<#
.SYNOPSIS
Fast Flutter SDK installation with progress bar

.DESCRIPTION
Downloads official Flutter SDK package with Dart SDK included

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_flutter.ps1

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_flutter.ps1 -InstallPath "D:\dev\flutter"
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\flutter",
    [switch]$SkipDoctor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section([string]$Title) {
    Write-Host "`n$("=" * 60)" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "$("=" * 60)`n" -ForegroundColor Cyan
}

# ============================================================
# Main
# ============================================================

Write-Host "`nFlutter Quick Installation Script" -ForegroundColor Cyan
Write-Host "==================================`n" -ForegroundColor Cyan

# Check existing installation
$existing = Get-Command flutter -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Detected existing Flutter: $($existing.Source)" -ForegroundColor Green
    $response = Read-Host "Continue installation? (y/N)"
    if ($response -notmatch "^[yY]") {
        exit 0
    }
}

Write-Section "Downloading Flutter SDK"

# Get latest version info
Write-Host "Fetching latest version info..." -ForegroundColor Yellow
$releases = Invoke-RestMethod -Uri "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$stable = $releases.releases | Where-Object { $_.hash -eq $releases.current_release.stable } | Select-Object -First 1
$version = $stable.version
$url = $releases.base_url + "/" + $stable.archive

Write-Host "Latest stable: $version" -ForegroundColor Green
Write-Host "Package size: ~1GB (includes Dart SDK)" -ForegroundColor Gray

# Download
$zipPath = Join-Path $env:TEMP "flutter_sdk.zip"

# Check if already downloaded
if (Test-Path $zipPath) {
    $response = Read-Host "`nFound cached download. Use it? (Y/n)"
    if ($response -match "^[nN]") {
        Remove-Item $zipPath -Force
    }
}

if (-not (Test-Path $zipPath)) {
    Write-Host "`nDownloading Flutter SDK..." -ForegroundColor Yellow
    Write-Host "Source: $url" -ForegroundColor Gray
    Write-Host "This will take a few minutes...`n" -ForegroundColor Gray
    
    # Use BITS for download (with progress bar)
    try {
        Import-Module BitsTransfer
        Start-BitsTransfer -Source $url -Destination $zipPath -Description "Downloading Flutter SDK" -DisplayName "Flutter SDK"
        Write-Host "`nDownload complete" -ForegroundColor Green
    } catch {
        # Fallback to Invoke-WebRequest with progress
        Write-Host "Using fallback download method..." -ForegroundColor Yellow
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $zipPath)
        
        Write-Host "Download complete" -ForegroundColor Green
    }
} else {
    Write-Host "Using cached download" -ForegroundColor Green
}

# Extract
Write-Section "Extracting Flutter SDK"

$parentDir = Split-Path $InstallPath -Parent
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

if (Test-Path $InstallPath) {
    $response = Read-Host "Target directory exists, delete and reinstall? (y/N)"
    if ($response -match "^[yY]") {
        Write-Host "Removing old installation..." -ForegroundColor Yellow
        Remove-Item $InstallPath -Recurse -Force
    } else {
        Write-Host "Installation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Extracting to: $InstallPath" -ForegroundColor Yellow

# Try 7z first (fastest)
$7z = Get-Command 7z -ErrorAction SilentlyContinue
if (-not $7z) {
    # Try to install 7z with winget
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "7-Zip not found, installing with winget..." -ForegroundColor Yellow
        winget install --id 7zip.7zip --exact --silent --accept-source-agreements --accept-package-agreements 2>$null
        
        # Refresh PATH and check common install locations
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Check common 7z locations
        $7zPaths = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe",
            "$env:ProgramFiles\7-Zip\7z.exe",
            "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
        )
        
        foreach ($path in $7zPaths) {
            if (Test-Path $path) {
                $7z = $path
                Write-Host "Found 7-Zip at: $path" -ForegroundColor Green
                break
            }
        }
        
        if (-not $7z) {
            $7z = Get-Command 7z -ErrorAction SilentlyContinue
        }
    }
}

if ($7z) {
    Write-Host "Using 7-Zip for fast extraction (30-60 seconds)...`n" -ForegroundColor Green
    $7zPath = if ($7z -is [string]) { $7z } else { $7z.Source }
    & $7zPath x $zipPath -o"$parentDir" -y | Out-Null
    Write-Host "Extraction complete" -ForegroundColor Green
} else {
    # Fallback to .NET
    Write-Host "Using built-in extraction (2-3 minutes)...`n" -ForegroundColor Gray
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $parentDir, $true)
        Write-Host "Extraction complete" -ForegroundColor Green
    } catch {
        # Final fallback to Expand-Archive
        Write-Host "Using fallback extraction method..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $parentDir -Force
        Write-Host "Extraction complete" -ForegroundColor Green
    }
}

# Setup PATH
Write-Section "Setting up environment variables"

$flutterBin = Join-Path $InstallPath "bin"
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($currentPath -notlike "*$flutterBin*") {
    $newPath = if ($currentPath) { "$currentPath;$flutterBin" } else { $flutterBin }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")
    Write-Host "PATH updated" -ForegroundColor Green
} else {
    Write-Host "PATH already contains Flutter" -ForegroundColor Green
}

# Verify
Write-Section "Verifying installation"

$flutterExe = Join-Path $flutterBin "flutter.bat"
Write-Host "Testing Flutter installation...`n" -ForegroundColor Yellow

try {
    & $flutterExe --version
    Write-Host "`nFlutter is ready!" -ForegroundColor Green
} catch {
    Write-Host "Warning: Flutter command not available yet, please restart terminal" -ForegroundColor Yellow
}

# Ask about cleanup
$response = Read-Host "`nDelete downloaded zip file to save space? (Y/n)"
if ($response -notmatch "^[nN]") {
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned up temporary files" -ForegroundColor Green
}

# Run flutter doctor
if (-not $SkipDoctor) {
    Write-Section "Running Flutter Doctor"
    flutter doctor
}

Write-Section "Installation Complete"
Write-Host "Flutter $version installed to: $InstallPath" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Restart terminal (for PATH to take effect)" -ForegroundColor White
Write-Host "  2. Run 'flutter doctor' to check dependencies" -ForegroundColor White
Write-Host "  3. Install Android Studio (for Android development)" -ForegroundColor White
Write-Host "`nTo update Flutter later, run:" -ForegroundColor Cyan
Write-Host "  flutter upgrade" -ForegroundColor White
Write-Host ""
