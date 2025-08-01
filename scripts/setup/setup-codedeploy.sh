#!/usr/bin/env bash
# CodeDeploy環境セットアップスクリプト
set -e

# ヘルパー関数を読み込む
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SETUP_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# CodeDeployの変数設定
export DEPLOY_GROUP="$PROJECT_NAME-deployment-group"
export SERVICE_ROLE_NAME="codedeploy-$PROJECT_NAME-service-role"
export APPLICATION_NAME="$PROJECT_NAME-app"
AWS_RESOURCES_PATH="$SETUP_DIR/aws-resources"

# IAMロールを作成する関数
create_iam_role() {
    local role_name="$1"
    
    # 既存ロールの確認
    if aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
        echo -e "\e[32mIAM role already exists: $role_name (skipping creation)\e[0m"
        return 0
    fi
    
    echo -e "\e[33mCreating IAM role: $role_name\e[0m"
    
    # ロール作成
    aws iam create-role \
        --role-name "$role_name" \
        --assume-role-policy-document file://"$AWS_RESOURCES_PATH/codedeploy/service-role-trust-policy.json" >/dev/null 2>&1

    # 必要なポリシーをアタッチ
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole >/dev/null 2>&1
        
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn arn:aws:iam::aws:policy/AutoScalingFullAccess >/dev/null 2>&1
  
    echo -e "\e[32mCreated IAM role: $role_name\e[0m"
    
    # IAMロールの伝播を待機
    echo -e "\e[33mWaiting for IAM role propagation...\e[0m"
    sleep 10
}

# CodeDeployアプリケーションを作成する関数
create_codedeploy_application() {
    local app_name="$1"
    
    # 既存アプリケーションの確認
    if aws deploy get-application --application-name "$app_name" >/dev/null 2>&1; then
        echo -e "\e[32mCodeDeploy application already exists: $app_name (skipping creation)\e[0m"
        return 0
    fi
    
    echo -e "\e[33mCreating CodeDeploy application: $app_name\e[0m"
    
    aws deploy create-application --application-name "$app_name" >/dev/null 2>&1
    echo -e "\e[32mCreated CodeDeploy application: $app_name\e[0m"
}

# デプロイグループを作成する関数
create_deployment_group() {
    local app_name="$1"
    local group_name="$2"
    local role_arn="$3"
    
    # 既存デプロイグループの確認
    if aws deploy get-deployment-group \
        --application-name "$app_name" \
        --deployment-group-name "$group_name" >/dev/null 2>&1; then
        echo -e "\e[32mDeployment group already exists: $group_name (skipping creation)\e[0m"
        return 0
    fi
    
    echo -e "\e[33mCreating deployment group: $group_name\e[0m"
    
    aws deploy create-deployment-group \
        --application-name "$app_name" \
        --deployment-group-name "$group_name" \
        --ec2-tag-filters Key="$EC2_TAG_KEY",Value="$EC2_TAG_VALUE",Type=KEY_AND_VALUE \
        --service-role-arn "$role_arn" >/dev/null 2>&1
        
    echo -e "\e[32mCreated deployment group: $group_name\e[0m"
}

# メイン処理
main() {
    echo -e "\e[33mSetting up CodeDeploy environment...\e[0m"
    echo -e "\e[33mProject: $PROJECT_NAME\e[0m"
    echo -e "\e[33mApplication Name: $APPLICATION_NAME\e[0m"
    echo -e "\e[33mDeploy Group: $DEPLOY_GROUP\e[0m"
    echo -e "\e[33mService Role: $SERVICE_ROLE_NAME\e[0m"
    echo ""
    
    # 1. IAMロールの作成
    create_iam_role "$SERVICE_ROLE_NAME"
    
    # 2. CodeDeployアプリケーションの作成
    create_codedeploy_application "$APPLICATION_NAME"
    
    # 3. デプロイグループの作成
    local role_arn="arn:aws:iam::$ACCOUNT_ID:role/$SERVICE_ROLE_NAME"
    create_deployment_group "$APPLICATION_NAME" "$DEPLOY_GROUP" "$role_arn"
    
    echo ""
    echo -e "\e[32mCodeDeploy setup completed successfully!\e[0m"
}

# スクリプト実行
main
