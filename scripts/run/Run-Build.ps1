# PowerShellスクリプト
$ErrorActionPreference = "Stop"

# ヘルパー関数を読み込む
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$helperPath = Join-Path (Split-Path -Parent $scriptPath) "helpers\helpers.ps1"
. $helperPath

Write-Host "AWS CI/CD Demo - Build Execution Script" -ForegroundColor Cyan
Import-EnvironmentVariables

# コマンド実行
Start-Build
Write-Host "Build completed. Artifact: $ENV:LATEST_BUILD_ARTIFACT" -ForegroundColor Green
