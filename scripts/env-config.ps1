# AWS CI/CDデモ用環境変数設定ファイル

# 基本設定
$ENV:AWS_REGION = "ap-northeast-1" # 使用するAWSリージョン
$ENV:PROJECT_NAME = "aws-cicd-demo" # プロジェクト名

# 自動生成される変数
$ENV:ACCOUNT_ID = (aws sts get-caller-identity --query "Account" --output text) # AWSアカウントID

# S3バケット関連
$ENV:S3_BUCKET_NAME = "aws-cicd-demo-codebuild-bucket-$ENV:ACCOUNT_ID" # S3バケット名

# EC2関連
$ENV:EC2_TAG_KEY = "Environment" # EC2インスタンスのタグキー
$ENV:EC2_TAG_VALUE = "Development-250717" # EC2インスタンスのタグ値

# ビルド/デプロイ関連
$ENV:BUILD_ARTIFACT_PREFIX = "aws-cicd-demo-build" # ビルドアーティファクトのプレフィックス
$ENV:LATEST_BUILD_ID = "" # 最新のビルドID（実行時に更新）
$ENV:LATEST_BUILD_ARTIFACT = "" # 最新のビルドアーティファクト名（実行時に更新）

# CodeDeploy関連（Setup-CodeDeploy.ps1で上書き可能）
$ENV:DEPLOY_GROUP = "$ENV:PROJECT_NAME-group" # デプロイグループ名
$ENV:SERVICE_ROLE_NAME = "codedeploy-$ENV:PROJECT_NAME-service-role" # CodeDeployのサービスロール名

# 関数：最新のビルドIDとアーティファクト名を取得
function Update-BuildInfo {
    # 最新のビルドIDを取得
    $latestBuild = aws codebuild list-builds-for-project --project-name $ENV:PROJECT_NAME --sort-order DESCENDING --max-items 1 | ConvertFrom-Json
    if ($latestBuild.ids.Count -gt 0) {
        $ENV:LATEST_BUILD_ID = $latestBuild.ids[0]
        
        # ビルド情報からアーティファクト情報を取得
        $buildInfo = aws codebuild batch-get-builds --ids $ENV:LATEST_BUILD_ID | ConvertFrom-Json
        if ($buildInfo.builds.Count -gt 0 -and $buildInfo.builds[0].artifacts.location) {
            $location = $buildInfo.builds[0].artifacts.location
            $key = $location.Split('/')[-1]
            $ENV:LATEST_BUILD_ARTIFACT = $key
            Write-Host "Latest build ID: $ENV:LATEST_BUILD_ID"
            Write-Host "Latest artifact: $ENV:LATEST_BUILD_ARTIFACT"
        }
    }
}

# 環境変数読み込み完了メッセージ
Write-Host "AWS CI/CD Demo environment variables set"
Write-Host "Project name: $ENV:PROJECT_NAME"
Write-Host "AWS region: $ENV:AWS_REGION"
Write-Host "Account ID: $ENV:ACCOUNT_ID"
Write-Host "S3 bucket name: $ENV:S3_BUCKET_NAME"
