<#
.SYNOPSIS
  Automatic version bump and git tag push script.

.DESCRIPTION
  This script automates the release process:
  1. Auto-detects latest version from git tags (if no version provided).
  2. Lets user choose which part to increment (major/minor/patch).
  3. Updates version and msix_version in pubspec.yaml.
  4. Commits the changes.
  5. Pushes to main.
  6. Creates a git tag.
  7. Pushes the tag to remote.

.PARAMETER Version
  Version string (e.g., 1.0.15). If not provided, will auto-increment from latest tag.

.EXAMPLE
  powershell -File scripts\github\release.ps1              # Auto-increment, ask which part
  powershell -File scripts\github\release.ps1 1.0.15       # Use specific version
#>

param(
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Load common helpers
. "$PSScriptRoot\..\_lib\common.ps1"

$root = Get-ProjectRoot
Set-Location $root

# Function to get latest version tag
function Get-LatestVersion {
    $tags = git tag --sort=-version:refname 2>$null | Where-Object { $_ -match '^v?\d+\.\d+\.\d+$' }
    if ($tags) {
        $latest = ($tags | Select-Object -First 1) -replace '^v', ''
        return $latest
    }
    return $null
}

# Function to increment version
function Get-IncrementedVersion {
    param(
        [string]$CurrentVersion,
        [ValidateSet('major', 'minor', 'patch')]
        [string]$Part
    )
    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    switch ($Part) {
        'major' { $major++; $minor = 0; $patch = 0 }
        'minor' { $minor++; $patch = 0 }
        'patch' { $patch++ }
    }
    return "$major.$minor.$patch"
}

# If no version provided, auto-increment
if (-not $Version) {
    $latestVersion = Get-LatestVersion
    
    if (-not $latestVersion) {
        Write-Host "No existing version tags found. Starting from 1.0.0" -ForegroundColor Yellow
        $Version = "1.0.0"
    } else {
        Write-Host ""
        Write-Host "Latest version: v$latestVersion" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Which part to increment?" -ForegroundColor Yellow
        Write-Host "  [1] Patch  $latestVersion -> $(Get-IncrementedVersion $latestVersion 'patch')  (bug fixes)" -ForegroundColor Gray
        Write-Host "  [2] Minor  $latestVersion -> $(Get-IncrementedVersion $latestVersion 'minor')  (new features)" -ForegroundColor Gray
        Write-Host "  [3] Major  $latestVersion -> $(Get-IncrementedVersion $latestVersion 'major')  (breaking changes)" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host "Enter choice (1/2/3)"
        
        $Version = switch ($choice) {
            '1' { Get-IncrementedVersion $latestVersion 'patch' }
            '2' { Get-IncrementedVersion $latestVersion 'minor' }
            '3' { Get-IncrementedVersion $latestVersion 'major' }
            default {
                Write-Host "Invalid choice. Defaulting to patch." -ForegroundColor Yellow
                Get-IncrementedVersion $latestVersion 'patch'
            }
        }
    }
    
    Write-Host ""
    Write-Host "New version: v$Version" -ForegroundColor Green
    $confirm = Read-Host "Continue? (Y/n)"
    if ($confirm -eq 'n') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

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

Write-Host "New Version: $cleanVersion"
Write-Host ""

# Update pubspec.yaml
Write-Host "Updating pubspec.yaml..."
$newPubspec = $pubspecContent -replace "(version:\s*)[^\r\n]+", "`${1}$cleanVersion"

[System.IO.File]::WriteAllText($pubspecPath, $newPubspec, (New-Object System.Text.UTF8Encoding($false)))

# Get current branch
$currentBranch = git branch --show-current
Write-Host "Current branch: $currentBranch"
Write-Host ""

# Git operations
Write-Host "Staging changes..."
git add pubspec.yaml

Write-Host "Committing..."
git commit -m "docs: release version $cleanVersion"

Write-Host "Pushing to $currentBranch..."
git push origin $currentBranch

$tagName = "v$cleanVersion"
Write-Host "Creating tag $tagName..."
git tag $tagName

Write-Host "Pushing tag $tagName..."
git push origin $tagName

Write-Host ""
Write-Host "Successfully released $tagName on branch '$currentBranch'!" -ForegroundColor Green
Write-Host "Check GitHub Actions for build progress."
