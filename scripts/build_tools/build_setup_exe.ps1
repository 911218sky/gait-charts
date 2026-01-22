<#
.SYNOPSIS
  Generate Windows setup.exe installer (Inno Setup)

.DESCRIPTION
  This is the most common "double-click to install" Windows installer (setup.exe).
  Process:
  - First, run Flutter Windows release build (reusing parameters from build_win.ps1)
  - Then, use Inno Setup Compiler (ISCC.exe) to package the build output into setup.exe

  Requirements:
  - Windows needs Inno Setup 6 installed (includes ISCC.exe)
    - After installation, typically located at: C:\Program Files (x86)\Inno Setup 6\ISCC.exe

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_setup_exe.ps1
.EXAMPLE
  # Already built Windows previously (to speed up):
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\build_tools\build_setup_exe.ps1 -SkipWindowsBuild
#>

[CmdletBinding()]
param(
  [switch]$SkipWindowsBuild,
  # If ISCC.exe is not detected, attempt to auto-install Inno Setup 6 via winget
  [switch]$InstallInnoSetup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\..\_lib\common.ps1"

function Resolve-Iscc {
  $candidates = @()

  $cmd = Get-Command ISCC.exe -ErrorAction SilentlyContinue
  if ($cmd) { $candidates += $cmd.Source }

  $candidates += @(
    "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
  )

  foreach ($p in $candidates) {
    if ($p -and (Test-Path $p)) { return $p }
  }
  return $null
}

function Ensure-InnoSetupInstalled {
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $iscc = Resolve-Iscc
  if ($iscc) { return $iscc }

  if (-not $InstallInnoSetup) { return $null }

  $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
  if (-not $winget) {
    Write-Host '[ERROR] ISCC.exe not found, and winget is not available on this machine.'
    Write-Host 'Please install Inno Setup 6 manually, or install winget (App Installer) and rerun with -InstallInnoSetup.'
    return $null
  }

  Write-Host 'Inno Setup not found. Installing via winget...'
  Write-Host '- Command: winget install --id JRSoftware.InnoSetup --source winget --accept-source-agreements --accept-package-agreements'
  Write-Host ''

  & $winget.Source install --id JRSoftware.InnoSetup --source winget --accept-source-agreements --accept-package-agreements | Out-Host
  if ($LASTEXITCODE -ne 0) {
    Write-Host ('[ERROR] winget install failed (exit=' + $LASTEXITCODE + ').')
    return $null
  }

  Write-Host ''
  return (Resolve-Iscc)
}

$root = Get-ProjectRoot
Set-Location $root

Write-Section 'Windows Installer (setup.exe) - Inno Setup'
Write-Host "Project path: $root"
Write-Host ''

# Initialize first (StrictMode will error if undeclared variable is read directly)
$iscc = Resolve-Iscc

if (-not $SkipWindowsBuild) {
  & (Join-Path $PSScriptRoot 'build_win.ps1')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  Write-Host ''
}

$releaseDir = Join-Path $root 'build\windows\x64\runner\Release'
if (-not (Test-Path $releaseDir)) {
  throw ('[ERROR] Windows release output not found: ' + $releaseDir + '. Please run scripts\build_tools\build_win.ps1 first.')
}

$mainExe = Get-ChildItem $releaseDir -Filter *.exe -File |
  Where-Object { $_.Name -notmatch 'flutter_tester' } |
  Select-Object -First 1

if (-not $mainExe) {
  throw ('[ERROR] No .exe found under: ' + $releaseDir)
}

# Version: extract x.y.z from pubspec (ignore +build)
$pubspec = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
$verLine = ($pubspec -split "`r?`n") | Where-Object { $_ -match '^\s*version:\s*' } | Select-Object -First 1
$appVersion = '1.0.0'
if ($verLine -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)') { $appVersion = $Matches[1] }

$appName = 'Gait Charts'
$publisher = 'NYCU'
$iconIco = Join-Path $root 'windows\runner\resources\app_icon.ico'
if (-not (Test-Path $iconIco)) { $iconIco = $null }

$outDir = Join-Path $root 'build_tools\out\installer'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$issPath = Join-Path $outDir 'gait_charts_setup.iss'
$setupBaseName = "GaitCharts_Setup_${appVersion}"

$iconLine = ""
if ($iconIco) { $iconLine = "SetupIconFile=$iconIco`r`n" }

# Inno Setup's Traditional Chinese language file may not be selected during installation
# (or installation method differs causing it to not exist). If not found, fallback to English
# to avoid compilation interruption.
$langSection = @"
[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
"@

if ($iscc) {
  $innoRoot = Split-Path -Parent $iscc
  $langCandidates = @(
    (Join-Path $innoRoot 'Languages\ChineseTraditional.isl'),
    (Join-Path $innoRoot 'Languages\Unofficial\ChineseTraditional.isl'),
    (Join-Path $innoRoot 'Languages\Languages\ChineseTraditional.isl')
  )
  $zhIsl = $langCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if ($zhIsl) {
    $langSection = @"
[Languages]
Name: "zh_TW"; MessagesFile: "$zhIsl"
"@
  }
}

# NOTE: Use pure ASCII (avoid cmd / Windows PowerShell 5.1 encoding issues)
$iss = @"
; Auto-generated by scripts/build_tools/build_setup_exe.ps1
; Do not edit manually unless you know what you're doing.

[Setup]
AppName=$appName
AppVersion=$appVersion
AppPublisher=$publisher
DefaultDirName={autopf}\$appName
DefaultGroupName=$appName
OutputDir=$outDir
OutputBaseFilename=$setupBaseName
Compression=lzma2
SolidCompression=yes
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\$($mainExe.Name)
$iconLine

$langSection

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "$releaseDir\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\$appName"; Filename: "{app}\$($mainExe.Name)"
Name: "{autodesktop}\$appName"; Filename: "{app}\$($mainExe.Name)"; Tasks: desktopicon

[Run]
Filename: "{app}\$($mainExe.Name)"; Description: "Launch $appName"; Flags: nowait postinstall skipifsilent
"@

# Windows PowerShell 5.1 does not support -Encoding utf8BOM; use .NET to explicitly write UTF-8 BOM
# to avoid cmd/PS encoding issues
[System.IO.File]::WriteAllText(
  $issPath,
  $iss,
  (New-Object System.Text.UTF8Encoding($true))
)

$iscc = Ensure-InnoSetupInstalled -ProjectRoot $root
if (-not $iscc) {
  Write-Host '[ERROR] Inno Setup Compiler (ISCC.exe) not found.'
  Write-Host 'Please install Inno Setup 6 and run this script again.'
  Write-Host '- Typical path: C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe'
  Write-Host '- Or add ISCC.exe to PATH'
  Write-Host '- Or: winget install --id JRSoftware.InnoSetup --source winget --accept-source-agreements --accept-package-agreements'
  exit 1
}

Write-Host 'Creating setup.exe (Inno Setup)...'
Write-Host ("- ISCC: " + $iscc)
Write-Host ("- Script: " + $issPath)
Write-Host ''

& $iscc $issPath | Out-Host
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Installer build succeeded!'
Write-Host "- Output folder: build_tools\\out\\installer\\"


