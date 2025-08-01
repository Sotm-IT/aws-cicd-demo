#!/usr/bin/env bash
# AWS CI/CDデモ用環境変数設定ファイル
# 最終更新: 2025-07-30

# 基本設定
export AWS_REGION="ap-northeast-1" # 使用するAWSリージョン
export PROJECT_NAME="aws-cicd-demo" # プロジェクト名

# 自動生成される変数
export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null || echo "取得失敗") # AWSアカウントID

# S3バケット関連
export S3_BUCKET_NAME="aws-cicd-demo-codebuild-bucket-$ACCOUNT_ID" # S3バケット名

# EC2関連
export EC2_TAG_KEY="Environment" # EC2インスタンスのタグキー
export EC2_TAG_VALUE="Development" # EC2インスタンスのタグ値（setup-ec2.sh実行時に上書きされる場合があります）
# EC2_INSTANCE_IDとEC2_PUBLIC_IPは、setup-ec2.shスクリプト実行時に自動設定されます

# ビルド/デプロイ関連
export LATEST_BUILD_ID="" # 最新のビルドID（実行時に更新）
export LATEST_BUILD_ARTIFACT="aws-cicd-demo-build"

# CodeDeploy関連
export DEPLOY_GROUP="$PROJECT_NAME-group" # デプロイグループ名
export SERVICE_ROLE_NAME="codedeploy-$PROJECT_NAME-service-role" # CodeDeployのサービスロール名

# 環境変数読み込み完了メッセージ
echo -e "\e[32mAWS CI/CD Demo environment variables set\e[0m"
echo "Project name: $PROJECT_NAME"
echo "AWS region: $AWS_REGION"
echo "Account ID: $ACCOUNT_ID"
echo "S3 bucket name: $S3_BUCKET_NAME"
echo "EC2タグ: $EC2_TAG_KEY=$EC2_TAG_VALUE"

# EC2インスタンスIDが設定されている場合
if [ ! -z "${EC2_INSTANCE_ID:-}" ]; then
    echo -e "\e[36mEC2インスタンスID: $EC2_INSTANCE_ID\e[0m"
    if [ ! -z "${EC2_PUBLIC_IP:-}" ]; then
        echo -e "EC2パブリックIP: $EC2_PUBLIC_IP"
    fi
fi
