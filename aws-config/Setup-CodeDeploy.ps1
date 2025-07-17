# PowerShell スクリプト実行ポリシーの設定が必要な場合があります
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# エラー時に停止
$ErrorActionPreference = "Stop"

# アカウントIDを取得
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$REGION = aws configure get region
$APP_NAME = "aws-cicd-demo"
$DEPLOY_GROUP = "aws-cicd-demo-group"
$SERVICE_ROLE_NAME = "codedeploy-aws-cicd-demo-service-role"

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
        --assume-role-policy-document file://aws-config/codedeploy/service-role-trust-policy.json

    # AWSCodeDeployRoleポリシーをアタッチ
    aws iam attach-role-policy `
        --role-name $SERVICE_ROLE_NAME `
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
  
    Write-Host "ロール $SERVICE_ROLE_NAME を作成しました" -ForegroundColor Green
  
    # ロールが利用可能になるまで少し待機
    Write-Host "IAMロール伝播のため15秒待機..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
}

Write-Host "CodeDeployアプリケーションを作成中..." -ForegroundColor Yellow

# アプリケーションが存在するか確認
try {
    $null = aws deploy get-application --application-name $APP_NAME 2>$null
    Write-Host "アプリケーション $APP_NAME は既に存在します" -ForegroundColor Green
}
catch {
    # アプリケーションの作成
    aws deploy create-application `
        --application-name $APP_NAME
  
    Write-Host "アプリケーション $APP_NAME を作成しました" -ForegroundColor Green
}

Write-Host "デプロイグループを作成中..." -ForegroundColor Yellow

# デプロイグループが存在するか確認
try {
    $null = aws deploy get-deployment-group `
        --application-name $APP_NAME `
        --deployment-group-name $DEPLOY_GROUP 2>$null
    Write-Host "デプロイグループ $DEPLOY_GROUP は既に存在します" -ForegroundColor Green
}
catch {
    # EC2インスタンスタグの設定 - 環境に合わせて変更してください
    $EC2_TAG_KEY = "Environment"
    $EC2_TAG_VALUE = "Development-250717"
  
    # デプロイグループの作成
    aws deploy create-deployment-group `
        --application-name $APP_NAME `
        --deployment-group-name $DEPLOY_GROUP `
        --ec2-tag-filters Key=$EC2_TAG_KEY,Value=$EC2_TAG_VALUE,Type=KEY_AND_VALUE `
        --service-role-arn arn:aws:iam::$ACCOUNT_ID`:role/$SERVICE_ROLE_NAME
  
    Write-Host "デプロイグループ $DEPLOY_GROUP を作成しました" -ForegroundColor Green
}

Write-Host "CodeDeployのセットアップが完了しました" -ForegroundColor Green