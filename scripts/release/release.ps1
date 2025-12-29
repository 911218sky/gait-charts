<#
.SYNOPSIS
  Automatic version bump and git tag push script.

.DESCRIPTION
  This script automates the release process:
  1. Updates version and msix_version in pubspec.yaml.
  2. Commits the changes.
  3. Pushes to main.
  4. Creates a git tag.
  5. Pushes the tag to remote.

.EXAMPLE
  powershell -File scripts\release\release.ps1 1.0.15
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Load common helpers
. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

Write-Section "Release Version $Version"

# Normalize version string (remove leading 'v' if present)
$cleanVersion = $Version
if ($cleanVersion.StartsWith("v")) {
    $cleanVersion = $cleanVersion.Substring(1)
}

# Validate version format (must be X.Y.Z)
if (-not ($cleanVersion -match "^[0-9]+\.[0-9]+\.[0-9]+$")) {
    throw "[ERROR] Invalid version format. Expected format: X.Y.Z (e.g., 1.0.15)"
}

$pubspecPath = Join-Path $root "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    throw "[ERROR] pubspec.yaml not found at $pubspecPath"
}

# Read pubspec.yaml
$pubspecContent = Get-Content $pubspecPath -Raw

# Convert version 1.0.15 to MSIX format 1.0.15.0
$newMsixVersion = "$cleanVersion.0"

Write-Host "New Version:      $cleanVersion"
Write-Host "New MSIX Version: $newMsixVersion"
Write-Host ""

# Update pubspec.yaml
Write-Host "Updating pubspec.yaml..."
$newPubspec = $pubspecContent -replace "(version:\s*)[^\r\n]+", "`${1}$cleanVersion"
$newPubspec = $newPubspec -replace "(msix_version:\s*)[^\r\n]+", "`${1}$newMsixVersion"

[System.IO.File]::WriteAllText($pubspecPath, $newPubspec, (New-Object System.Text.UTF8Encoding($false)))

# Git operations
Write-Host "Staging changes..."
git add pubspec.yaml

Write-Host "Committing..."
git commit -m "docs: release version $cleanVersion"

Write-Host "Pushing to main..."
git push origin main

$tagName = "v$cleanVersion"
Write-Host "Creating tag $tagName..."
git tag $tagName

Write-Host "Pushing tag $tagName..."
git push origin $tagName

Write-Host ""
Write-Host "Successfully released $tagName!"
Write-Host "Check GitHub Actions for build progress."
