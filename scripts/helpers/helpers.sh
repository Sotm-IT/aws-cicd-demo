#!/usr/bin/env bash
# AWS CI/CDデモ用ヘルパー関数

# エラーハンドリングのインポート
HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERROR_HANDLING_PATH="$HELPERS_DIR/error-handling.sh"

if [ -f "$ERROR_HANDLING_PATH" ]; then
    source "$ERROR_HANDLING_PATH"
else
    echo "エラーハンドリングスクリプトが見つかりません: $ERROR_HANDLING_PATH" >&2
fi

# 環境変数を読み込む
import_environment_variables() {
    # 環境変数設定ファイルを読み込む
    local env_config_path="$(dirname "$HELPERS_DIR")/env-config.sh"
    
    if [ -f "$env_config_path" ]; then
        source "$env_config_path"
        echo -e "\e[32mAWS CI/CD Demo environment variables set\e[0m"
        echo -e "\e[33mProject name: $PROJECT_NAME\e[0m"
        echo -e "\e[33mAWS region: $AWS_REGION\e[0m"
        echo -e "\e[33mAccount ID: $ACCOUNT_ID\e[0m"
        echo -e "\e[33mS3 bucket name: $S3_BUCKET_NAME\e[0m"
        echo -e "\e[33mEC2タグ: $EC2_TAG_KEY=$EC2_TAG_VALUE\e[0m"
        return 0
    else
        echo -e "\e[31m環境変数設定ファイルが見つかりません: $env_config_path\e[0m" >&2
        return 1
    fi
}

# 環境設定ファイルのパスを取得する共通関数
get_env_config_path() {
    echo "$(dirname "$HELPERS_DIR")/env-config.sh"
}

# 最新のビルド情報を更新する関数
update_build_info() {
    local env_config_path="$(get_env_config_path)"
    
    # S3バケット名の確認
    if [ -z "$S3_BUCKET_NAME" ]; then
        echo "S3_BUCKET_NAME environment variable is not set"
        return 1
    fi
    
    # S3バケット内の最新のビルドアーティファクトを取得
    local latest_artifact
    latest_artifact=$(aws s3api list-objects-v2 \
        --bucket "$S3_BUCKET_NAME" \
        --query 'sort_by(Contents, &LastModified)[-1].Key' \
        --output text 2>/dev/null)
    
    local list_exit_code=$?
    
    # S3操作のエラーハンドリング
    if [ $list_exit_code -ne 0 ]; then
        echo "Error accessing S3 bucket: $S3_BUCKET_NAME"
        echo "Please check S3 permissions and bucket existence"
        return 1
    fi
    
    if [ "$latest_artifact" != "None" ] && [ -n "$latest_artifact" ]; then
        # 環境変数ファイルにLATEST_BUILD_ARTIFACTを追加または更新
        if grep -q "^export LATEST_BUILD_ARTIFACT=" "$env_config_path" 2>/dev/null; then
            sed -i "s|^export LATEST_BUILD_ARTIFACT=.*|export LATEST_BUILD_ARTIFACT=\"$latest_artifact\"|" "$env_config_path"
        else
            echo "export LATEST_BUILD_ARTIFACT=\"$latest_artifact\"" >> "$env_config_path"
        fi
        
        export LATEST_BUILD_ARTIFACT="$latest_artifact"
        echo "Latest build artifact updated: $LATEST_BUILD_ARTIFACT"
    else
        echo "No build artifacts found in S3 bucket: $S3_BUCKET_NAME"
        return 1
    fi
}

# ビルドを実行して結果を待機する
start_build() {
    echo "Starting CodeBuild..."
    
    # 環境変数の確認
    if [ -z "$PROJECT_NAME" ]; then
        echo "PROJECT_NAME environment variable is not set"
        return 1
    fi
    
    # setup-codebuild.shで作成したプロジェクト名を使用
    local codebuild_project_name="${PROJECT_NAME}-build"
    
    # プロジェクトの存在確認
    if ! aws codebuild batch-get-projects --names "$codebuild_project_name" >/dev/null 2>&1; then
        echo "CodeBuild project does not exist: $codebuild_project_name"
        echo "Please run setup-codebuild.sh first"
        return 1
    fi
    
    local build_id
    build_id=$(aws codebuild start-build \
        --project-name "$codebuild_project_name" \
        --query 'build.id' \
        --output text)
    
    if [ $? -ne 0 ] || [ -z "$build_id" ]; then
        echo "Failed to start build for project: $codebuild_project_name"
        echo "Please check CodeBuild permissions and project configuration"
        return 1
    fi
    
    echo "Build started with ID: $build_id"
    echo "Waiting for build to complete..."
    
    # ビルドの完了を待機（polling方式）
    local retry_count=0
    local max_retries=60  # 最大10分間待機
    
    while [ $retry_count -lt $max_retries ]; do
        local build_status
        build_status=$(aws codebuild batch-get-builds \
            --ids "$build_id" \
            --query 'builds[0].buildStatus' \
            --output text 2>/dev/null)
        
        case "$build_status" in
            "SUCCEEDED")
                echo ""
                echo "Build completed successfully"
                update_build_info
                return 0
                ;;
            "FAILED"|"FAULT"|"STOPPED"|"TIMED_OUT")
                echo ""
                echo "Build failed with status: $build_status"
                echo "Check CloudWatch logs for details: /aws/codebuild/$codebuild_project_name"
                return 1
                ;;
            "IN_PROGRESS")
                echo -n "."
                sleep 10
                retry_count=$((retry_count + 1))
                ;;
            *)
                echo -n "?"
                sleep 10
                retry_count=$((retry_count + 1))
                ;;
        esac
    done
    
    echo ""
    echo "Build timed out after $((max_retries * 10)) seconds"
    return 1
}

# デプロイを実行して結果を待機する
start_deployment() {
    echo "Starting CodeDeploy deployment..."
    
    # 環境変数の確認
    if [ -z "$PROJECT_NAME" ]; then
        echo "PROJECT_NAME environment variable is not set"
        return 1
    fi
    
    if [ -z "$S3_BUCKET_NAME" ]; then
        echo "S3_BUCKET_NAME environment variable is not set"
        return 1
    fi
    
    # setup-codedeploy.shで作成したアプリケーション名とデプロイメントグループ名を使用
    local application_name="${PROJECT_NAME}-app"
    local deployment_group_name="${PROJECT_NAME}-deployment-group"
    
    # CodeDeployアプリケーションの存在確認
    if ! aws deploy get-application --application-name "$application_name" >/dev/null 2>&1; then
        echo "CodeDeploy application does not exist: $application_name"
        echo "Please run setup-codedeploy.sh first"
        return 1
    fi
    
    # 最新のビルドアーティファクトを確認
    if [ -z "$LATEST_BUILD_ARTIFACT" ]; then
        echo "No build artifact found. Please run build first."
        echo "Attempting to update build info..."
        if ! update_build_info; then
            return 1
        fi
    fi
    
    # S3にアーティファクトが存在するか確認
    if ! aws s3api head-object --bucket "$S3_BUCKET_NAME" --key "$LATEST_BUILD_ARTIFACT" >/dev/null 2>&1; then
        echo "Build artifact not found in S3: s3://$S3_BUCKET_NAME/$LATEST_BUILD_ARTIFACT"
        return 1
    fi
    
    local deployment_id
    deployment_id=$(aws deploy create-deployment \
        --application-name "$application_name" \
        --deployment-group-name "$deployment_group_name" \
        --s3-location bucket="$S3_BUCKET_NAME",key="$LATEST_BUILD_ARTIFACT",bundleType=zip \
        --query 'deploymentId' \
        --output text)
    
    if [ $? -ne 0 ] || [ -z "$deployment_id" ]; then
        echo "Failed to start deployment for application: $application_name"
        echo "Please check CodeDeploy permissions and configuration"
        return 1
    fi
    
    echo "Deployment started with ID: $deployment_id"
    echo "Waiting for deployment to complete..."
    
    # デプロイメントの完了を待機
    aws deploy wait deployment-successful --deployment-id "$deployment_id"
    
    if [ $? -eq 0 ]; then
        echo "Deployment completed successfully"
        return 0
    else
        echo "Deployment failed or timed out"
        echo "Check AWS Console for deployment details: $deployment_id"
        return 1
    fi
}

# EC2インスタンスの情報を取得
get_ec2_instance_info() {
    import_environment_variables
    
    local instances
    instances=$(aws ec2 describe-instances \
        --filters "Name=tag:$EC2_TAG_KEY,Values=$EC2_TAG_VALUE" \
        --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" \
        --output json)
    
    echo "デプロイ対象のEC2インスタンス:"
    
    if command -v jq > /dev/null; then
        echo "$instances" | jq -c '.[][]' | while read -r instance; do
            id=$(echo "$instance" | jq -r '.[0]')
            ip=$(echo "$instance" | jq -r '.[1]')
            state=$(echo "$instance" | jq -r '.[2]')
            echo "ID: $id, IP: $ip, State: $state"
        done
    else
        # jqがない場合は簡易表示
        echo "$instances"
    fi
    
    echo "$instances"
}
