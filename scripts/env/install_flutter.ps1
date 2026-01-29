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
  
  # 檢查路徑是否已存在（忽略大小寫和結尾斜線）
  $normalizedNewPath = $NewPath.TrimEnd('\', '/')
  $pathExists = $currentPath -split ";" | Where-Object { 
    $_.TrimEnd('\', '/') -ieq $normalizedNewPath 
  }
  
  if ($pathExists) {
    Write-Host "PATH already contains: $NewPath (skip)"
    return $false
  }
  
  # 設定用戶環境變數
  $newPathValue = if ($currentPath) { "$currentPath;$NewPath" } else { $NewPath }
  [Environment]::SetEnvironmentVariable("PATH", $newPathValue, "User")
  
  # 立即更新當前會話的環境變數
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
  $env:PATH = "$userPath;$machinePath"
  
  Write-Host "Added to PATH: $NewPath"
  Write-Host "Current session PATH updated"
  return $true
}

function Test-EnvironmentSetup {
  param([string]$FlutterBin)
  
  Write-Host "Verifying environment setup..."
  
  # 檢查用戶 PATH
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  $hasFlutterInUserPath = $userPath -split ";" | Where-Object { $_.TrimEnd('\', '/') -ieq $FlutterBin.TrimEnd('\', '/') }
  
  Write-Host "User PATH contains Flutter: $(if ($hasFlutterInUserPath) { '✓ Yes' } else { '✗ No' })"
  
  # 檢查當前會話 PATH
  $hasFlutterInCurrentPath = $env:PATH -split ";" | Where-Object { $_.TrimEnd('\', '/') -ieq $FlutterBin.TrimEnd('\', '/') }
  Write-Host "Current session PATH contains Flutter: $(if ($hasFlutterInCurrentPath) { '✓ Yes' } else { '✗ No' })"
  
  # 檢查 Flutter 可執行檔
  $flutterExe = Join-Path $FlutterBin "flutter.bat"
  $flutterExists = Test-Path $flutterExe
  Write-Host "Flutter executable exists: $(if ($flutterExists) { '✓ Yes' } else { '✗ No' }) ($flutterExe)"
  
  return $hasFlutterInUserPath -and $hasFlutterInCurrentPath -and $flutterExists
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

# 驗證環境設定
Write-Host ""
$envSetupOk = Test-EnvironmentSetup -FlutterBin $flutterBin

if ($pathAdded) {
  Write-Host ""
  Write-Host "[IMPORTANT] PATH updated successfully!"
  Write-Host "            Current session: Environment updated"
  Write-Host "            New terminals: Will automatically have Flutter in PATH"
  Write-Host ""
  Write-Host "If Flutter commands don't work in current terminal, run:"
  Write-Host '  $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [Environment]::GetEnvironmentVariable("PATH", "Machine")'
} else {
  Write-Host "PATH was already configured correctly."
}

if (-not $envSetupOk) {
  Write-Host ""
  Write-Host "[WARNING] Environment setup verification failed. Manual check may be needed."
}
Write-Host ""

Write-Section "Verify installation"

$flutterExe = Join-Path $flutterBin "flutter.bat"

Write-Host "Flutter path: $flutterExe"
Write-Host "Testing Flutter command..."

# 測試 Flutter 命令是否可用
try {
  $flutterVersion = & $flutterExe --version 2>&1
  Write-Host "✓ Flutter command works!"
  Write-Host $flutterVersion
} catch {
  Write-Host "✗ Flutter command failed. Trying to fix PATH..."
  
  # 強制重新載入環境變數
  $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
  $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
  $env:PATH = "$userPath;$machinePath"
  
  try {
    $flutterVersion = & $flutterExe --version 2>&1
    Write-Host "✓ Flutter command works after PATH reload!"
    Write-Host $flutterVersion
  } catch {
    Write-Host "✗ Flutter command still not working. Manual intervention may be needed."
    Write-Host "Try restarting your terminal or IDE."
  }
}

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
