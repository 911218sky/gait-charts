<#
.SYNOPSIS
  Manually trigger GitHub Actions build workflow.

.DESCRIPTION
  This script:
  1. Pulls the latest code from remote
  2. Cleans old build artifacts
  3. Triggers the GitHub Actions workflow manually
  4. Rebuilds and replaces the latest GitHub Release assets (default), or triggers build-only

.PARAMETER ReleaseTag
  Optional release tag (e.g., v1.0.10). If not provided, this script will try to use the latest tag (v*).

.PARAMETER BuildOnly
  If set, trigger workflow without publishing a GitHub Release.

.EXAMPLE
  # Rebuild and replace assets in the latest GitHub Release (auto-detect latest v* tag)
  powershell -File scripts\github\trigger_build.ps1

.EXAMPLE
  # Rebuild and replace assets for a specific release tag
  powershell -File scripts\github\trigger_build.ps1 -ReleaseTag v1.0.10

.EXAMPLE
  # Build only (no release)
  powershell -File scripts\github\trigger_build.ps1 -BuildOnly
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ReleaseTag = "",

    [Parameter(Mandatory = $false)]
    [switch]$BuildOnly,

    [Parameter(Mandatory = $false)]
    [switch]$WebOnly,

    [Parameter(Mandatory = $false)]
    [switch]$AndroidOnly,

    [Parameter(Mandatory = $false)]
    [switch]$WindowsOnly
)

$ErrorActionPreference = "Stop"

# Load common helpers
. "$PSScriptRoot\..\_lib\common.ps1"

$ProgressPreference = "SilentlyContinue"

function Resolve-RepoActionsUrl {
    try {
        $origin = (git remote get-url origin 2>$null)
        if (-not $origin) { return "https://github.com/<owner>/<repo>/actions/workflows/build.yml" }

        # Support: https://github.com/owner/repo(.git)
        if ($origin -match "^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$") {
            return "https://github.com/$($Matches.owner)/$($Matches.repo)/actions/workflows/build.yml"
        }

        # Support: git@github.com:owner/repo(.git)
        if ($origin -match "^git@github\.com:(?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$") {
            return "https://github.com/$($Matches.owner)/$($Matches.repo)/actions/workflows/build.yml"
        }
    } catch {
        # ignore
    }

    return "https://github.com/<owner>/<repo>/actions/workflows/build.yml"
}

function Resolve-GhExePath {
    $cmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $candidates = @(
        (Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "GitHub CLI\gh.exe")
    ) | Where-Object { $_ -and (Test-Path $_) }

    $first = @($candidates) | Select-Object -First 1
    if ($first) { return $first }
    return $null
}

function Install-GitHubCli {
    Write-Host "[INFO] Installing GitHub CLI (gh)..." -ForegroundColor Cyan

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        # Non-interactive installation
        & $winget.Source install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements | Out-Host
        return
    }

    throw "[ERROR] winget is not available. Please install GitHub CLI manually, or install winget (App Installer) first."
}

function Ensure-GitHubCli {
    $gh = Resolve-GhExePath
    if ($gh) { return $gh }

    Install-GitHubCli

    $gh = Resolve-GhExePath
    if ($gh) { return $gh }

    throw "[ERROR] GitHub CLI installation finished but gh.exe is still not found."
}

function Invoke-GhChecked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GhExe,
        [Parameter(Mandatory = $true)]
        [string[]]$Args,
        [string]$OnFailHint = ""
    )

    & $GhExe @Args
    $code = $LASTEXITCODE
    if ($code -ne 0) {
        if ($OnFailHint) {
            throw "[ERROR] gh failed (exit=$code). $OnFailHint"
        }
        throw "[ERROR] gh failed (exit=$code)."
    }
}

$root = Get-ProjectRoot
Set-Location $root

Write-Section "Trigger GitHub Actions Build"

# Step 1: Update to latest version
Write-Host "[INFO] Pulling latest code from remote..." -ForegroundColor Cyan
try {
    git fetch origin --tags
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $currentBranch" -ForegroundColor Gray
    
    git pull origin $currentBranch
    Write-Host "[OK] Code updated successfully!" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Failed to pull latest code: $_" -ForegroundColor Yellow
    Write-Host "[WARN] Continuing anyway..." -ForegroundColor Yellow
}

Write-Host ""

# Step 1.5: Determine latest tag (for replacing latest release assets)
if (-not $BuildOnly -and (-not $ReleaseTag)) {
    try {
        $latestTag = (git tag --list "v*" --sort=-v:refname | Select-Object -First 1)
        if ($latestTag) {
            $ReleaseTag = $latestTag.Trim()
            Write-Host "[INFO] Using latest tag: $ReleaseTag" -ForegroundColor Gray
        }
    } catch {
        # ignore; will fallback below
    }
}

if (-not $BuildOnly -and (-not $ReleaseTag)) {
    Write-Host "[WARN] No release tag found. Falling back to build-only." -ForegroundColor Yellow
    $BuildOnly = $true
}

# Step 2: Clean old build artifacts
Write-Section "Cleaning Old Build Artifacts"

$buildDirs = @(
    "build",
    "build_tools\out"
)

foreach ($dir in $buildDirs) {
    $fullPath = Join-Path $root $dir
    if (Test-Path $fullPath) {
        Write-Host "[INFO] Removing: $dir" -ForegroundColor Yellow
        Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "[OK] Build artifacts cleaned!" -ForegroundColor Green
Write-Host ""

# Step 3: Check if GitHub CLI is installed
Write-Section "Triggering GitHub Actions Workflow"

$actionsUrl = Resolve-RepoActionsUrl

$gh = $null
try {
    $gh = Ensure-GitHubCli
} catch {
    Write-Host "[ERROR] Failed to install/locate GitHub CLI (gh): $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Manually trigger the workflow from GitHub:" -ForegroundColor Cyan
    Write-Host "  $actionsUrl" -ForegroundColor Gray
    exit 1
}

# Step 4: Trigger the workflow
try {
    Write-Host "[INFO] Triggering workflow..." -ForegroundColor Cyan

    # Build selection is only meaningful for build-only dispatch (no release).
    # If ReleaseTag is provided, we always build all targets to replace release assets consistently.
    $fields = @()
    if ($BuildOnly) {
        if ($WebOnly -or $AndroidOnly -or $WindowsOnly) {
            $fields += "--field"
            $fields += "buildWeb=$($WebOnly.ToString().ToLowerInvariant())"
            $fields += "--field"
            $fields += "buildAndroid=$($AndroidOnly.ToString().ToLowerInvariant())"
            $fields += "--field"
            $fields += "buildWindows=$($WindowsOnly.ToString().ToLowerInvariant())"
            $fields += "--field"
            $fields += "buildLinux=false"
            $fields += "--field"
            $fields += "buildMacos=false"
        }
    }
    
    if ($BuildOnly) {
        Write-Host "Build only (no release)" -ForegroundColor Gray
        if ($fields.Count -gt 0) {
            Invoke-GhChecked -GhExe $gh -Args (@("workflow", "run", "build.yml") + $fields) -OnFailHint "If you recently changed workflow inputs, commit & push `.github/workflows/build.yml` to GitHub first."
        } else {
            Invoke-GhChecked -GhExe $gh -Args @("workflow", "run", "build.yml")
        }
    } else {
        Write-Host "Release tag (replace assets): $ReleaseTag" -ForegroundColor Gray
        Invoke-GhChecked -GhExe $gh -Args @("workflow", "run", "build.yml", "--field", "releaseTag=$ReleaseTag")
    }
    
    Write-Host ""
    Write-Host "[OK] Workflow triggered successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "[INFO] View workflow progress:" -ForegroundColor Cyan
    Write-Host "   gh run list --workflow=build.yml" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   Or visit: $actionsUrl" -ForegroundColor Gray
    
    # Wait a moment and show recent runs
    Start-Sleep -Seconds 2
    Write-Host ""
    Write-Host "Recent workflow runs:" -ForegroundColor Cyan
    Invoke-GhChecked -GhExe $gh -Args @("run", "list", "--workflow=build.yml", "--limit", "5")
    
} catch {
    Write-Host "[ERROR] Failed to trigger workflow: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. You are authenticated with GitHub CLI (run: gh auth login)" -ForegroundColor Gray
    Write-Host "  2. You have permission to trigger workflows on this repository" -ForegroundColor Gray
    Write-Host "  3. If using workflow inputs, commit & push `.github/workflows/build.yml` first" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "[OK] Done!" -ForegroundColor Green

