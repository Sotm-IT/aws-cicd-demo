# PowerShellスクリプト
$ErrorActionPreference = "Stop"

# ヘルパー関数を読み込む
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$helperPath = Join-Path (Split-Path -Parent $scriptPath) "helpers\helpers.ps1"
. $helperPath

# 環境変数を読み込む
Import-EnvironmentVariables

Write-Host "Setting up CodeBuild environment..." -ForegroundColor Yellow
Write-Host "Project name: $ENV:PROJECT_NAME" -ForegroundColor Yellow
Write-Host "Account ID: $ENV:ACCOUNT_ID" -ForegroundColor Yellow
Write-Host "Bucket name: $ENV:S3_BUCKET_NAME" -ForegroundColor Yellow

# プロジェクト設定ファイルの準備
$awsResourcesPath = Join-Path $scriptPath "aws-resources"
$projectJson = Get-Content -Path (Join-Path $awsResourcesPath "codebuild\create-project.json") -Raw
$projectJson = $projectJson.Replace("<ACCOUNT_ID>", $ENV:ACCOUNT_ID)
$projectJson | Set-Content -Path (Join-Path $awsResourcesPath "codebuild\create-project.json")

$SERVICE_ROLE_NAME = "codebuild-$ENV:PROJECT_NAME-service-role"

Write-Host "Creating S3 bucket..." -ForegroundColor Yellow

# バケットの存在確認
try {
    $null = aws s3api head-bucket --bucket $ENV:S3_BUCKET_NAME 2>$null
    Write-Host "Bucket $ENV:S3_BUCKET_NAME already exists" -ForegroundColor Green
}
catch {
    aws s3api create-bucket `
        --bucket $ENV:S3_BUCKET_NAME `
        --create-bucket-configuration file://(Join-Path $awsResourcesPath "codebuild\create-bucket.json")
    Write-Host "Created bucket $ENV:S3_BUCKET_NAME" -ForegroundColor Green
}

Write-Host "Creating IAM role..." -ForegroundColor Yellow

# ロールの存在確認
try {
    $null = aws iam get-role --role-name $SERVICE_ROLE_NAME 2>$null
    Write-Host "Role $SERVICE_ROLE_NAME already exists" -ForegroundColor Green
}
catch {
    # ロール作成
    aws iam create-role `
        --role-name $SERVICE_ROLE_NAME `
        --assume-role-policy-document file://(Join-Path $awsResourcesPath "codebuild\service-role-trust-policy.json")

    # ポリシーのアタッチ
    aws iam put-role-policy `
        --role-name $SERVICE_ROLE_NAME `
        --policy-name codebuild-$ENV:PROJECT_NAME-policy `
        --policy-document file://(Join-Path $awsResourcesPath "codebuild\service-role-policy.json")
  
    Write-Host "Created role $SERVICE_ROLE_NAME" -ForegroundColor Green
  
    # ロールが利用可能になるまで待機
    Write-Host "Waiting 15 seconds for IAM role propagation..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}

Write-Host "Creating CodeBuild project..." -ForegroundColor Yellow

# プロジェクトの存在確認
try {
    $projects = aws codebuild batch-get-projects --names $ENV:PROJECT_NAME | ConvertFrom-Json
    if ($projects.projects.Count -gt 0) {
        Write-Host "Project $ENV:PROJECT_NAME already exists" -ForegroundColor Green
  
        # プロジェクトの更新
        aws codebuild update-project `
            --cli-input-json file://(Join-Path $awsResourcesPath "codebuild\create-project.json")
  
        Write-Host "Updated project $ENV:PROJECT_NAME" -ForegroundColor Green
    }
    else {
        throw "Project not found"
    }
}
catch {
    # プロジェクト作成
    aws codebuild create-project `
        --cli-input-json file://(Join-Path $awsResourcesPath "codebuild\create-project.json")
  
    Write-Host "Created project $ENV:PROJECT_NAME" -ForegroundColor Green
}

Write-Host "CodeBuild setup completed" -ForegroundColor Green
