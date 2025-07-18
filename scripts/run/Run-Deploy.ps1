# PowerShellスクリプト
$ErrorActionPreference = "Stop"

# ヘルパー関数を読み込む
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$helperPath = Join-Path (Split-Path -Parent $scriptPath) "helpers\helpers.ps1"
. $helperPath

Write-Host "AWS CI/CD Demo - Deploy Execution Script" -ForegroundColor Cyan
Import-EnvironmentVariables

# EC2インスタンス情報の表示
Get-EC2InstanceInfo

# デプロイ実行
Start-Deployment
Write-Host "Deployment completed. Please verify the application." -ForegroundColor Green
