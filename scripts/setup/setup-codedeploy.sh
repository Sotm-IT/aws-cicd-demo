#!/usr/bin/env bash
# Bashスクリプト
set -e

# ヘルパー関数を読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SCRIPT_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# CodeDeployの変数設定
export DEPLOY_GROUP="$PROJECT_NAME-group"
export SERVICE_ROLE_NAME="codedeploy-$PROJECT_NAME-service-role"

echo -e "\e[33mCreating IAM role...\e[0m"

# ロールの存在確認
if aws iam get-role --role-name "$SERVICE_ROLE_NAME" 2>/dev/null; then
    echo -e "\e[32mRole $SERVICE_ROLE_NAME already exists\e[0m"
else
    # ロール作成
    AWS_RESOURCES_PATH="$SCRIPT_DIR/aws-resources"
    aws iam create-role \
        --role-name "$SERVICE_ROLE_NAME" \
        --assume-role-policy-document file://"$AWS_RESOURCES_PATH/codedeploy/service-role-trust-policy.json"

    # ポリシーのアタッチ
    aws iam attach-role-policy \
        --role-name "$SERVICE_ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
  
    echo -e "\e[32mCreated role $SERVICE_ROLE_NAME\e[0m"
  
    # ロールが利用可能になるまで待機
    echo -e "\e[33mWaiting 15 seconds for IAM role propagation...\e[0m"
    sleep 15
fi

echo -e "\e[33mCreating CodeDeploy application...\e[0m"

# アプリケーションの存在確認
if aws deploy get-application --application-name "$PROJECT_NAME" 2>/dev/null; then
    echo -e "\e[32mApplication $PROJECT_NAME already exists\e[0m"
else
    # アプリケーション作成
    aws deploy create-application \
        --application-name "$PROJECT_NAME"
  
    echo -e "\e[32mCreated application $PROJECT_NAME\e[0m"
fi

echo -e "\e[33mCreating deployment group...\e[0m"

# デプロイグループの存在確認
if aws deploy get-deployment-group \
    --application-name "$PROJECT_NAME" \
    --deployment-group-name "$DEPLOY_GROUP" 2>/dev/null; then
    echo -e "\e[32mDeployment group $DEPLOY_GROUP already exists\e[0m"
else
    # デプロイグループの作成
    aws deploy create-deployment-group \
        --application-name "$PROJECT_NAME" \
        --deployment-group-name "$DEPLOY_GROUP" \
        --ec2-tag-filters Key="$EC2_TAG_KEY",Value="$EC2_TAG_VALUE",Type=KEY_AND_VALUE \
        --service-role-arn "arn:aws:iam::$ACCOUNT_ID:role/$SERVICE_ROLE_NAME"
  
    echo -e "\e[32mCreated deployment group $DEPLOY_GROUP\e[0m"
fi

echo -e "\e[32mCodeDeploy setup completed\e[0m"
