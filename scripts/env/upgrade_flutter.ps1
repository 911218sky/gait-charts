<#
.SYNOPSIS
  Upgrade Flutter SDK and auto-update pubspec.yaml SDK constraint (PowerShell)

.DESCRIPTION
  - Upgrade Flutter SDK to latest version
  - Detect new Dart SDK version
  - Update pubspec.yaml environment.sdk constraint
  - Re-fetch dependencies

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\upgrade_flutter.ps1

.EXAMPLE
  # Skip Flutter upgrade, only update pubspec.yaml SDK constraint
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\upgrade_flutter.ps1 -SkipFlutterUpgrade

.EXAMPLE
  # Specify SDK constraint format (default uses caret ^)
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\env\upgrade_flutter.ps1 -SdkConstraint ">=3.10.0 <4.0.0"
#>

[CmdletBinding()]
param(
  [switch]$SkipFlutterUpgrade,
  [string]$SdkConstraint
)

. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

function Get-DartSdkVersion {
  <#
  .SYNOPSIS
    Get current Dart SDK version from dart --version (e.g. 3.10.4)
  #>
  $dartOutput = & dart --version 2>&1 | Out-String
  
  # Extract version from "Dart SDK version: 3.10.4 (stable) ..."
  if ($dartOutput -match "Dart SDK version:\s*(\d+\.\d+\.\d+)") {
    return $Matches[1]
  }
  
  throw "[ERROR] Cannot get Dart SDK version from 'dart --version'"
}

function Update-PubspecSdk {
  <#
  .SYNOPSIS
    Update pubspec.yaml environment.sdk constraint (only the one under environment:)
  #>
  param(
    [string]$PubspecPath,
    [string]$NewConstraint
  )
  
  if (-not (Test-Path $PubspecPath)) {
    throw "[ERROR] pubspec.yaml not found: $PubspecPath"
  }
  
  $lines = Get-Content $PubspecPath -Encoding UTF8
  $newLines = @()
  $inEnvironment = $false
  $updated = $false
  
  foreach ($line in $lines) {
    # Detect environment: block
    if ($line -match "^environment:\s*$") {
      $inEnvironment = $true
      $newLines += $line
      continue
    }
    
    # If in environment block and found sdk: line
    if ($inEnvironment -and $line -match "^(\s+sdk:\s*).*$") {
      $indent = $Matches[1]
      $newLines += "${indent}${NewConstraint}"
      $updated = $true
      $inEnvironment = $false
      continue
    }
    
    # Exit environment block if we hit another top-level key
    if ($inEnvironment -and $line -match "^\S") {
      $inEnvironment = $false
    }
    
    $newLines += $line
  }
  
  if ($updated) {
    $newLines | Set-Content $PubspecPath -Encoding UTF8
    return $true
  }
  
  Write-Host "[WARN] Cannot find environment.sdk constraint, please check pubspec.yaml manually"
  return $false
}

function Get-CurrentSdkConstraint {
  <#
  .SYNOPSIS
    Get current SDK constraint from pubspec.yaml
  #>
  param([string]$PubspecPath)
  
  $lines = Get-Content $PubspecPath -Encoding UTF8
  $inEnvironment = $false
  
  foreach ($line in $lines) {
    if ($line -match "^environment:\s*$") {
      $inEnvironment = $true
      continue
    }
    
    if ($inEnvironment -and $line -match "^\s+sdk:\s*(.+)$") {
      return $Matches[1].Trim()
    }
    
    if ($inEnvironment -and $line -match "^\S") {
      break
    }
  }
  
  return "unknown"
}

# ============================================================
# Main
# ============================================================

Write-Section "Upgrade Flutter SDK"

Write-Host "Project path: $root"
Write-Host ""

# Step 1: Get version before upgrade
Write-Host "[1/5] Get current version..."
$beforeVersion = Get-DartSdkVersion
Write-Host "Current Dart SDK: $beforeVersion"
Write-Host ""

# Step 2: Upgrade Flutter
if (-not $SkipFlutterUpgrade) {
  Write-Host "[2/5] Upgrade Flutter SDK: flutter upgrade"
  Invoke-Flutter -Args @('upgrade')
  Write-Host ""
} else {
  Write-Host "[2/5] Skip Flutter upgrade (-SkipFlutterUpgrade)"
  Write-Host ""
}

# Step 3: Get version after upgrade
Write-Host "[3/5] Get new version..."
$afterVersion = Get-DartSdkVersion
Write-Host "New Dart SDK: $afterVersion"
Write-Host ""

# Step 4: Update pubspec.yaml
Write-Host "[4/5] Update pubspec.yaml SDK constraint..."

$pubspecPath = Join-Path $root "pubspec.yaml"

# Determine new constraint format
if ($SdkConstraint) {
  $newConstraint = $SdkConstraint
} else {
  # Default: use caret syntax with major.minor.0
  $versionParts = $afterVersion -split '\.'
  $newConstraint = "^$($versionParts[0]).$($versionParts[1]).0"
}

# Read old constraint
$oldConstraint = Get-CurrentSdkConstraint -PubspecPath $pubspecPath

Write-Host "Old constraint: $oldConstraint"
Write-Host "New constraint: $newConstraint"

if ($oldConstraint -eq $newConstraint) {
  Write-Host "SDK constraint is already up-to-date, no changes needed"
} else {
  $updated = Update-PubspecSdk -PubspecPath $pubspecPath -NewConstraint $newConstraint
  if ($updated) {
    Write-Host "pubspec.yaml updated!"
  }
}
Write-Host ""

# Step 5: Re-fetch dependencies
Write-Host "[5/5] Re-fetch dependencies: flutter pub get"
Invoke-Flutter -Args @('pub', 'get')
Write-Host ""

# Done
Write-Section "Upgrade Complete"

Write-Host "Flutter/Dart version: $afterVersion"
Write-Host "SDK constraint: $newConstraint"
Write-Host ""

if ($beforeVersion -ne $afterVersion) {
  Write-Host "Version upgraded from $beforeVersion to $afterVersion"
} else {
  Write-Host "Flutter is already at the latest version"
}

Write-Host ""
Write-Host "Recommended next steps:"
Write-Host "  1. Run 'flutter pub outdated' to check dependency updates"
Write-Host "  2. Run 'flutter test' to verify tests pass"
Write-Host "  3. Run 'flutter build' to verify build works"
Write-Host ""
