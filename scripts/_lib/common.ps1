<#
.SYNOPSIS
  Gait Charts scripts 共用工具函式（PowerShell）

.DESCRIPTION
  提供 scripts 下各分類腳本共用的工具：
  - 取得專案根目錄（由 scripts/ 反推）
  - 解析 flutter / python 命令並統一呼叫方式
  - 統一輸出格式、錯誤處理
  - 開啟瀏覽器（優先 Chrome，找不到則 Edge / 預設瀏覽器）
  - Gradle daemon stop / transforms cache 清理（修復 metadata.bin 讀取錯誤）
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
  <#
  .SYNOPSIS
    取得專案根目錄（scripts/ 的上一層）
  #>
  # 檔案位置：scripts\_lib\common.ps1
  # 專案根目錄 = common.ps1 的目錄往上兩層
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-Section([string]$Title) {
  Write-Host ("=" * 60)
  Write-Host " [Gait Charts] $Title"
  Write-Host ("=" * 60)
  Write-Host ""
}

function Resolve-FlutterCommand {
  <#
  .SYNOPSIS
    解析 Flutter 命令（在 Windows 優先 flutter.bat）
  #>
  $cmd = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  throw "[ERROR] 找不到 Flutter。請確認 Flutter SDK 已安裝並將 Flutter SDK bin 加入 PATH。"
}

function Invoke-Flutter {
  <#
  .SYNOPSIS
    呼叫 flutter（統一入口，避免 PATH/副檔名解析差異）
  #>
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args,
    [switch]$IgnoreExitCode
  )

  $flutter = Resolve-FlutterCommand
  & $flutter @Args
  $code = $LASTEXITCODE
  if (-not $IgnoreExitCode -and $code -ne 0) {
    $joined = ($Args -join " ")
    throw "[ERROR] flutter 失敗（exit=$code）：$flutter $joined"
  }
  return $code
}

function Resolve-PythonCommand {
  <#
  .SYNOPSIS
    解析 Python 命令：優先 python，其次 py -3
  #>
  $py = Get-Command python -ErrorAction SilentlyContinue
  if ($py) {
    return @{
      File = $py.Source
      PrefixArgs = @()
    }
  }

  $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
  if ($pyLauncher) {
    return @{
      File = $pyLauncher.Source
      PrefixArgs = @("-3")
    }
  }

  throw "[ERROR] 找不到 Python（python / py）。請安裝 Python，或將其加入 PATH。"
}

function Open-Url {
  <#
  .SYNOPSIS
    開啟 URL（優先 Chrome，否則 Edge，最後用預設瀏覽器）
  #>
  param([Parameter(Mandatory = $true)][string]$Url)

  $chrome = @(
    (Get-Command chrome -ErrorAction SilentlyContinue | ForEach-Object Source),
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
  ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

  if ($chrome) {
    Start-Process -FilePath $chrome -ArgumentList @($Url) | Out-Null
    return
  }

  $edge = (Get-Command msedge -ErrorAction SilentlyContinue | ForEach-Object Source)
  if ($edge) {
    Start-Process -FilePath $edge -ArgumentList @($Url) | Out-Null
    return
  }

  Start-Process -FilePath $Url | Out-Null
}

function Stop-GradleDaemon {
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $gradlew = Join-Path $ProjectRoot "android\gradlew.bat"
  if (Test-Path $gradlew) {
    Push-Location (Join-Path $ProjectRoot "android")
    try {
      & $gradlew --stop | Out-Null
    } finally {
      Pop-Location
    }
  }
}

function Get-GradleWrapperVersion {
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $prop = Join-Path $ProjectRoot "android\gradle\wrapper\gradle-wrapper.properties"
  if (-not (Test-Path $prop)) { return $null }

  $line = (Get-Content $prop | Where-Object { $_ -match "^\s*distributionUrl=" } | Select-Object -First 1)
  if (-not $line) { return $null }

  $url = ($line -split "=", 2)[1]
  if ($url -match "gradle-([0-9.]+)-(all|bin)\.zip") {
    return $Matches[1]
  }
  return $null
}

function Clear-GradleTransformsCache {
  <#
  .SYNOPSIS
    清理 Gradle transforms cache（用於修復 metadata.bin 讀取錯誤）
  #>
  param([Parameter(Mandatory = $true)][string]$ProjectRoot)

  $ver = Get-GradleWrapperVersion -ProjectRoot $ProjectRoot
  $cachesRoot = Join-Path $env:USERPROFILE ".gradle\caches"

  if ($ver) {
    $target = Join-Path $cachesRoot "$ver\transforms"
    Write-Host "[FixGradle] Detected Gradle: $ver"
    if (Test-Path $target) {
      Write-Host "[FixGradle] Deleting: $target"
      Remove-Item $target -Recurse -Force
    } else {
      Write-Host "[FixGradle] Not found (skip): $target"
    }
    return
  }

  Write-Host "[FixGradle] Could not detect Gradle version. Will try to delete all caches\*\transforms"
  if (Test-Path $cachesRoot) {
    Get-ChildItem $cachesRoot -Directory -ErrorAction SilentlyContinue |
      ForEach-Object {
        $t = Join-Path $_.FullName "transforms"
        if (Test-Path $t) {
          Write-Host "[FixGradle] Deleting: $t"
          Remove-Item $t -Recurse -Force
        }
      }
  }
}


