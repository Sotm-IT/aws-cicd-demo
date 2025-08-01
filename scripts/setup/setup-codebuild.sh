#!/usr/bin/env bash
# CodeBuild環境セットアップスクリプト
set -e

# ヘルパー関数を読み込む
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SETUP_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# CodeBuildの変数設定
SERVICE_ROLE_NAME="codebuild-$PROJECT_NAME-service-role"
PROJECT_BUILD_NAME="$PROJECT_NAME-build"
AWS_RESOURCES_PATH="$SETUP_DIR/aws-resources"

# JSONテンプレートファイルを準備する関数
prepare_json_templates() {
    echo -e "\e[33mPreparing configuration files...\e[0m"
    
    # プロジェクト設定ファイル
    local project_json="$AWS_RESOURCES_PATH/codebuild/create-project.json"
    local project_template="$project_json.template"
    if [[ ! -f "$project_template" ]]; then
        cp "$project_json" "$project_template"
    fi
    cp "$project_template" "$project_json"
    
    # S3バケット設定ファイル
    local bucket_json="$AWS_RESOURCES_PATH/codebuild/create-bucket.json"
    local bucket_template="$bucket_json.template"
    if [[ ! -f "$bucket_template" ]]; then
        cp "$bucket_json" "$bucket_template"
    fi
    cp "$bucket_template" "$bucket_json"
    
    # サービスロールポリシーファイル
    local policy_json="$AWS_RESOURCES_PATH/codebuild/service-role-policy.json"
    local policy_template="$policy_json.template"
    if [[ ! -f "$policy_template" ]]; then
        cp "$policy_json" "$policy_template"
    fi
    cp "$policy_template" "$policy_json"
    
    # プレースホルダーを置き換え
    sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" "$project_json" "$policy_json"
    sed -i "s/<PROJECT_NAME>/$PROJECT_NAME/g" "$project_json" "$policy_json"
    sed -i "s/<AWS_REGION>/$AWS_REGION/g" "$project_json" "$bucket_json"
}

# S3バケットを作成する関数
create_s3_bucket() {
    local bucket_name="$1"
    
    # 既存バケットの確認
    if aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
        echo -e "\e[32mS3 bucket already exists: $bucket_name (skipping creation)\e[0m"
        return 0
    fi
    
    echo -e "\e[33mCreating S3 bucket: $bucket_name\e[0m"
    
    aws s3api create-bucket \
        --bucket "$bucket_name" \
        --create-bucket-configuration file://"$AWS_RESOURCES_PATH/codebuild/create-bucket.json" >/dev/null 2>&1
        
    echo -e "\e[32mCreated S3 bucket: $bucket_name\e[0m"
}

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
        --assume-role-policy-document file://"$AWS_RESOURCES_PATH/codebuild/service-role-trust-policy.json" >/dev/null 2>&1
    
    # ポリシーのアタッチ
    aws iam put-role-policy \
        --role-name "$role_name" \
        --policy-name "codebuild-$PROJECT_NAME-policy" \
        --policy-document file://"$AWS_RESOURCES_PATH/codebuild/service-role-policy.json" >/dev/null 2>&1
    
    # 追加のS3管理権限（必要に応じて）
    aws iam attach-role-policy \
        --role-name "$role_name" \
        --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess" >/dev/null 2>&1
  
    echo -e "\e[32mCreated IAM role: $role_name\e[0m"
    
    # IAMロールの伝播を待機
    echo -e "\e[33mWaiting for IAM role propagation...\e[0m"
    sleep 10
}

# CodeBuildプロジェクトを作成する関数
create_codebuild_project() {
    local project_name="$1"
    
    # 既存プロジェクトの確認
    if aws codebuild batch-get-projects --names "$project_name" >/dev/null 2>&1; then
        echo -e "\e[32mCodeBuild project already exists: $project_name (skipping creation)\e[0m"
        return 0
    fi
    
    echo -e "\e[33mCreating CodeBuild project: $project_name\e[0m"
    
    aws codebuild create-project \
        --cli-input-json file://"$AWS_RESOURCES_PATH/codebuild/create-project.json" >/dev/null 2>&1
        
    echo -e "\e[32mCreated CodeBuild project: $project_name\e[0m"
}

# メイン処理
main() {
    echo -e "\e[33mSetting up CodeBuild environment...\e[0m"
    echo -e "\e[33mProject: $PROJECT_NAME\e[0m"
    echo -e "\e[33mBuild Project: $PROJECT_BUILD_NAME\e[0m"
    echo -e "\e[33mS3 Bucket: $S3_BUCKET_NAME\e[0m"
    echo -e "\e[33mService Role: $SERVICE_ROLE_NAME\e[0m"
    echo ""
    
    # 1. 設定ファイルの準備
    prepare_json_templates
    
    # 2. S3バケットの作成
    create_s3_bucket "$S3_BUCKET_NAME"
    
    # 3. IAMロールの作成
    create_iam_role "$SERVICE_ROLE_NAME"
    
    # 4. CodeBuildプロジェクトの作成
    create_codebuild_project "$PROJECT_BUILD_NAME"
    
    echo ""
    echo -e "\e[32mCodeBuild setup completed successfully!\e[0m"
}

# スクリプト実行
main

