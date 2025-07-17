# PowerShell スクリプト実行ポリシーの設定が必要な場合があります
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# エラー時に停止
$ErrorActionPreference = "Stop"

# アカウントIDを取得
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$REGION = aws configure get region
$BUCKET_NAME = "aws-cicd-demo-codebuild-bucket-$ACCOUNT_ID"
$PROJECT_NAME = "aws-cicd-demo-build"
$SERVICE_ROLE_NAME = "codebuild-aws-cicd-demo-service-role"

# アカウントIDを設定ファイルに置換 (Windows用に修正)
$projectJson = Get-Content -Path aws-config/codebuild/create-project.json -Raw
$projectJson = $projectJson.Replace("<ACCOUNT_ID>", $ACCOUNT_ID)
$projectJson | Set-Content -Path aws-config/codebuild/create-project.json

Write-Host "S3バケットを作成中..." -ForegroundColor Yellow

# バケットが存在するか確認
try {
    $null = aws s3api head-bucket --bucket $BUCKET_NAME 2>$null
    Write-Host "バケット $BUCKET_NAME は既に存在します" -ForegroundColor Green
}
catch {
    aws s3api create-bucket `
        --bucket $BUCKET_NAME `
        --create-bucket-configuration file://aws-config/codebuild/create-bucket.json
    Write-Host "バケット $BUCKET_NAME を作成しました" -ForegroundColor Green
}

Write-Host "IAMロールを作成中..." -ForegroundColor Yellow

# ロールが存在するか確認
try {
    $null = aws iam get-role --role-name $SERVICE_ROLE_NAME 2>$null
    Write-Host "ロール $SERVICE_ROLE_NAME は既に存在します" -ForegroundColor Green
}
catch {
    # ロールの作成
    aws iam create-role `
        --role-name $SERVICE_ROLE_NAME `
        --assume-role-policy-document file://aws-config/codebuild/service-role-trust-policy.json

    # ポリシーのアタッチ
    aws iam put-role-policy `
        --role-name $SERVICE_ROLE_NAME `
        --policy-name codebuild-aws-cicd-demo-policy `
        --policy-document file://aws-config/codebuild/service-role-policy.json
  
    Write-Host "ロール $SERVICE_ROLE_NAME を作成しました" -ForegroundColor Green
  
    # ロールが利用可能になるまで少し待機
    Write-Host "IAMロール伝播のため15秒待機..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}

Write-Host "CodeBuildプロジェクトを作成中..." -ForegroundColor Yellow

# プロジェクトが存在するか確認
try {
    $projects = aws codebuild batch-get-projects --names $PROJECT_NAME | ConvertFrom-Json
    if ($projects.projects.Count -gt 0) {
        Write-Host "プロジェクト $PROJECT_NAME は既に存在します" -ForegroundColor Green
  
        # プロジェクトの更新
        aws codebuild update-project `
            --cli-input-json file://aws-config/codebuild/create-project.json
  
        Write-Host "プロジェクト $PROJECT_NAME を更新しました" -ForegroundColor Green
    }
    else {
        throw "Project not found"
    }
}
catch {
    # プロジェクトの作成
    aws codebuild create-project `
        --cli-input-json file://aws-config/codebuild/create-project.json
  
    Write-Host "プロジェクト $PROJECT_NAME を作成しました" -ForegroundColor Green
}

Write-Host "CodeBuildのセットアップが完了しました" -ForegroundColor Green