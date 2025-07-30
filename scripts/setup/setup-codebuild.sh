#!/bin/bash
# Bashスクリプト
set -e

# ヘルパー関数を読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SCRIPT_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

echo -e "\e[33mSetting up CodeBuild environment...\e[0m"
echo -e "\e[33mProject name: $PROJECT_NAME\e[0m"
echo -e "\e[33mAccount ID: $ACCOUNT_ID\e[0m"
echo -e "\e[33mBucket name: $S3_BUCKET_NAME\e[0m"

# プロジェクト設定ファイルの準備
AWS_RESOURCES_PATH="$SCRIPT_DIR/aws-resources"
PROJECT_JSON_PATH="$AWS_RESOURCES_PATH/codebuild/create-project.json"

# JSONファイルの<ACCOUNT_ID>を置き換える
sed -i "s/<ACCOUNT_ID>/$ACCOUNT_ID/g" "$PROJECT_JSON_PATH"

SERVICE_ROLE_NAME="codebuild-$PROJECT_NAME-service-role"

echo -e "\e[33mCreating S3 bucket...\e[0m"

# バケットの存在確認
if aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
    echo -e "\e[32mBucket $S3_BUCKET_NAME already exists\e[0m"
else
    aws s3api create-bucket \
        --bucket "$S3_BUCKET_NAME" \
        --create-bucket-configuration file://"$AWS_RESOURCES_PATH/codebuild/create-bucket.json"
    echo -e "\e[32mCreated bucket $S3_BUCKET_NAME\e[0m"
fi

echo -e "\e[33mCreating IAM role...\e[0m"

# ロールの存在確認
if aws iam get-role --role-name "$SERVICE_ROLE_NAME" 2>/dev/null; then
    echo -e "\e[32mRole $SERVICE_ROLE_NAME already exists\e[0m"
else
    # ロール作成
    aws iam create-role \
        --role-name "$SERVICE_ROLE_NAME" \
        --assume-role-policy-document file://"$AWS_RESOURCES_PATH/codebuild/service-role-trust-policy.json"

    # ポリシーのアタッチ
    aws iam put-role-policy \
        --role-name "$SERVICE_ROLE_NAME" \
        --policy-name "codebuild-$PROJECT_NAME-policy" \
        --policy-document file://"$AWS_RESOURCES_PATH/codebuild/service-role-policy.json"
  
    echo -e "\e[32mCreated role $SERVICE_ROLE_NAME\e[0m"
  
    # ロールが利用可能になるまで待機
    echo -e "\e[33mWaiting 15 seconds for IAM role propagation...\e[0m"
    sleep 15
fi

echo -e "\e[33mCreating CodeBuild project...\e[0m"

# プロジェクトの存在確認
if aws codebuild batch-get-projects --names "$PROJECT_NAME" | grep -q "\"name\": \"$PROJECT_NAME\""; then
    echo -e "\e[32mProject $PROJECT_NAME already exists\e[0m"
  
    # プロジェクトの更新
    aws codebuild update-project \
        --cli-input-json file://"$AWS_RESOURCES_PATH/codebuild/create-project.json"
  
    echo -e "\e[32mUpdated project $PROJECT_NAME\e[0m"
else
    # プロジェクト作成
    aws codebuild create-project \
        --cli-input-json file://"$AWS_RESOURCES_PATH/codebuild/create-project.json"
  
    echo -e "\e[32mCreated project $PROJECT_NAME\e[0m"
fi

echo -e "\e[32mCodeBuild setup completed\e[0m"
