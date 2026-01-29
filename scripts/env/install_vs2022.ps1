<#
.SYNOPSIS
  Download and launch Visual Studio 2022 installer

.DESCRIPTION
  - Download Visual Studio 2022 installer
  - Launch installer for user to choose workloads and components
  - No automatic installation - user has full control

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_vs2022.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_vs2022.ps1 -Edition Professional

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\install_vs2022.ps1 -LaunchOnly
#>

[CmdletBinding()]
param(
  [ValidateSet("Community", "Professional", "Enterprise")]
  [string]$Edition = "Community",
  [switch]$LaunchOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Auto-elevate if not running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Requesting administrator privileges..."
  
  $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
  
  # Add original parameters
  if ($Edition -ne "Community") { $arguments += " -Edition $Edition" }
  if ($LaunchOnly) { $arguments += " -LaunchOnly" }
  
  try {
    Start-Process PowerShell -Verb RunAs -ArgumentList $arguments -Wait
    exit 0
  } catch {
    Write-Host "Failed to elevate privileges. Please run as administrator manually."
    exit 1
  }
}

function Write-Section([string]$Title) {
  Write-Host ("=" * 60)
  Write-Host " [VS 2022 Install] $Title"
  Write-Host ("=" * 60)
  Write-Host ""
}

function Get-VSInstallerInfo {
  param([string]$Edition)
  
  $editions = @{
    "Community" = @{
      Name = "Visual Studio Community 2022"
      Url = "https://aka.ms/vs/17/release/vs_community.exe"
      ProductId = "Microsoft.VisualStudio.Product.Community"
    }
    "Professional" = @{
      Name = "Visual Studio Professional 2022"
      Url = "https://aka.ms/vs/17/release/vs_professional.exe"
      ProductId = "Microsoft.VisualStudio.Product.Professional"
    }
    "Enterprise" = @{
      Name = "Visual Studio Enterprise 2022"
      Url = "https://aka.ms/vs/17/release/vs_enterprise.exe"
      ProductId = "Microsoft.VisualStudio.Product.Enterprise"
    }
  }
  
  return $editions[$Edition]
}

function Test-AdminRights {
  $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-ExistingInstallation {
  $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  
  if (-not (Test-Path $vsWhere)) {
    return $null
  }
  
  try {
    $installations = & $vsWhere -version "[17.0,18.0)" -property installationPath,displayName,installationVersion
    if ($installations) {
      return $installations
    }
  } catch {
    Write-Host "Could not query existing VS installations"
  }
  
  return $null
}

function Launch-VSInstaller {
  param([string]$InstallerPath)
  
  Write-Host "Launching Visual Studio installer..."
  Write-Host "You can now choose which workloads and components to install."
  Write-Host ""
  Write-Host "Recommended for Flutter development:"
  Write-Host "  ✓ Desktop development with C++ (for Windows apps)"
  Write-Host "  ✓ Mobile development with .NET (for cross-platform)"
  Write-Host "  ✓ Individual components:"
  Write-Host "    - Windows 10/11 SDK (latest version)"
  Write-Host "    - Git for Windows"
  Write-Host "    - CMake tools for C++"
  Write-Host ""
  
  try {
    Start-Process -FilePath $InstallerPath -Wait
    Write-Host "✓ Installer completed"
    return $true
  } catch {
    Write-Host "✗ Failed to launch installer: $_"
    return $false
  }
}

function Test-VSInstallation {
  $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  
  if (-not (Test-Path $vsWhere)) {
    Write-Host "✗ VS installer not found"
    return $false
  }
  
  try {
    $installations = & $vsWhere -version "[17.0,18.0)" -property installationPath,displayName,installationVersion
    
    if ($installations) {
      Write-Host "✓ Visual Studio 2022 installations found:"
      $installations | ForEach-Object {
        Write-Host "  - $_"
      }
      return $true
    } else {
      Write-Host "✗ No Visual Studio 2022 installations found"
      return $false
    }
  } catch {
    Write-Host "✗ Could not verify VS installation: $_"
    return $false
  }
}

# ============================================================
# Main
# ============================================================

Write-Section "Check prerequisites"

# VS installer doesn't require admin rights to download, only to install
Write-Host "✓ Ready to download Visual Studio installer"

# Check existing installation
$existing = Test-ExistingInstallation
if ($existing) {
  Write-Host "Existing Visual Studio 2022 installation found:"
  $existing | ForEach-Object {
    Write-Host "  - $_"
  }
  Write-Host "You can modify or add components using the installer."
  Write-Host ""
}

Write-Section "Prepare installation"

$vsInfo = Get-VSInstallerInfo -Edition $Edition
Write-Host "Edition: $($vsInfo.Name)"
Write-Host "Download URL: $($vsInfo.Url)"

$tempDir = Join-Path $env:TEMP "vs2022_install"
$installerPath = Join-Path $tempDir "vs_installer.exe"

if (-not (Test-Path $tempDir)) {
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

Write-Section "Download installer"

if (Test-Path $installerPath) {
  Write-Host "Using cached installer: $installerPath"
} else {
  Write-Host "Downloading Visual Studio installer..."
  Write-Host "Target: $installerPath"
  
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest -Uri $vsInfo.Url -OutFile $installerPath -UseBasicParsing
  $ProgressPreference = 'Continue'
  
  Write-Host "✓ Download complete!"
}

Write-Section "Launch installer"

$launchSuccess = Launch-VSInstaller -InstallerPath $installerPath

if (-not $launchSuccess) {
  Write-Host ""
  Write-Host "Failed to launch installer. You can run it manually:"
  Write-Host "  $installerPath"
  exit 1
}

Write-Section "Installation guidance"

Write-Host "Visual Studio installer has been launched!"
Write-Host ""
Write-Host "For Flutter development, consider installing:"
Write-Host ""
Write-Host "Workloads:"
Write-Host "  ✓ Desktop development with C++"
Write-Host "    - Required for Flutter Windows desktop apps"
Write-Host "    - Includes C++ compiler and Windows SDK"
Write-Host ""
Write-Host "  ✓ Mobile development with .NET"
Write-Host "    - Useful for cross-platform development"
Write-Host "    - Includes Android development tools"
Write-Host ""
Write-Host "Individual components (if not included above):"
Write-Host "  ✓ Git for Windows"
Write-Host "  ✓ Windows 10/11 SDK (latest version)"
Write-Host "  ✓ CMake tools for Visual Studio"
Write-Host ""
Write-Host "After installation:"
Write-Host "  1. Install Flutter SDK (run install_flutter.ps1)"
Write-Host "  2. Install Android Studio for Android development"
Write-Host "  3. Run 'flutter doctor' to verify setup"
Write-Host ""