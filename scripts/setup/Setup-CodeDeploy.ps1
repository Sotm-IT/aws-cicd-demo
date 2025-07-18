# PowerShellスクリプト
$ErrorActionPreference = "Stop"

# ヘルパー関数を読み込む
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$helperPath = Join-Path (Split-Path -Parent $scriptPath) "helpers\helpers.ps1"
. $helperPath

# 環境変数を読み込む
Import-EnvironmentVariables

# CodeDeployの変数設定
$ENV:DEPLOY_GROUP = "$ENV:PROJECT_NAME-group"
$ENV:SERVICE_ROLE_NAME = "codedeploy-$ENV:PROJECT_NAME-service-role"

Write-Host "Creating IAM role..." -ForegroundColor Yellow

# ロールの存在確認
try {
    $null = aws iam get-role --role-name $ENV:SERVICE_ROLE_NAME 2>$null
    Write-Host "Role $ENV:SERVICE_ROLE_NAME already exists" -ForegroundColor Green
}
catch {
    # ロール作成
    $awsResourcesPath = Join-Path $scriptPath "aws-resources"
    aws iam create-role `
        --role-name $ENV:SERVICE_ROLE_NAME `
        --assume-role-policy-document file://(Join-Path $awsResourcesPath "codedeploy\service-role-trust-policy.json")

    # ポリシーのアタッチ
    aws iam attach-role-policy `
        --role-name $ENV:SERVICE_ROLE_NAME `
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
  
    Write-Host "Created role $ENV:SERVICE_ROLE_NAME" -ForegroundColor Green
  
    # ロールが利用可能になるまで待機
    Write-Host "Waiting 15 seconds for IAM role propagation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}

Write-Host "Creating CodeDeploy application..." -ForegroundColor Yellow

# アプリケーションの存在確認
try {
    $null = aws deploy get-application --application-name $ENV:PROJECT_NAME 2>$null
    Write-Host "Application $ENV:PROJECT_NAME already exists" -ForegroundColor Green
}
catch {
    # アプリケーション作成
    aws deploy create-application `
        --application-name $ENV:PROJECT_NAME
  
    Write-Host "Created application $ENV:PROJECT_NAME" -ForegroundColor Green
}

Write-Host "Creating deployment group..." -ForegroundColor Yellow

# デプロイグループの存在確認
try {
    $null = aws deploy get-deployment-group `
        --application-name $ENV:PROJECT_NAME `
        --deployment-group-name $ENV:DEPLOY_GROUP 2>$null
    Write-Host "Deployment group $ENV:DEPLOY_GROUP already exists" -ForegroundColor Green
}
catch {
    # デプロイグループの作成
    aws deploy create-deployment-group `
        --application-name $ENV:PROJECT_NAME `
        --deployment-group-name $ENV:DEPLOY_GROUP `
        --ec2-tag-filters Key=$ENV:EC2_TAG_KEY,Value=$ENV:EC2_TAG_VALUE,Type=KEY_AND_VALUE `
        --service-role-arn arn:aws:iam::$ENV:ACCOUNT_ID:role/$ENV:SERVICE_ROLE_NAME
  
    Write-Host "Created deployment group $ENV:DEPLOY_GROUP" -ForegroundColor Green
}

Write-Host "CodeDeploy setup completed" -ForegroundColor Green
