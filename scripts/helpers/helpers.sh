#!/bin/bash
# AWS CI/CDデモ用ヘルパー関数

# 環境変数を読み込む
import_environment_variables() {
    # 環境変数設定ファイルを読み込む
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local env_config_path="$(dirname "$script_dir")/env-config.sh"
    
    if [ -f "$env_config_path" ]; then
        source "$env_config_path"
        return 0
    else
        echo "環境変数設定ファイルが見つかりません: $env_config_path" >&2
        return 1
    fi
}

# ビルドを実行して結果を待機する
start_build() {
    import_environment_variables

    echo "Starting build..."
    local build_result
    build_result=$(aws codebuild start-build --project-name $PROJECT_NAME)
    
    # jqコマンドが利用可能かチェック
    local build_id
    if command -v jq > /dev/null; then
        build_id=$(echo "$build_result" | jq -r '.build.id')
    else
        # jqがない場合、簡易的な方法で取得を試みる
        build_id=$(echo "$build_result" | grep -oP '"id":\s*"\K[^"]+' | head -1)
    fi
    
    echo "Build ID: $build_id"
    echo "Checking build status..."
    
    local status
    local build_status="IN_PROGRESS"
    local phase
    
    while [ "$build_status" == "IN_PROGRESS" ]; do
        sleep 10
        status=$(aws codebuild batch-get-builds --ids "$build_id")
        
        if command -v jq > /dev/null; then
            build_status=$(echo "$status" | jq -r '.builds[0].buildStatus')
            phase=$(echo "$status" | jq -r '.builds[0].currentPhase')
        else
            build_status=$(echo "$status" | grep -oP '"buildStatus":\s*"\K[^"]+' | head -1)
            phase=$(echo "$status" | grep -oP '"currentPhase":\s*"\K[^"]+' | head -1)
        fi
        
        echo "Current phase: $phase - Status: $build_status"
    done
    
    if [ "$build_status" == "SUCCEEDED" ]; then
        echo "Build succeeded!"
        # 最新のビルド情報を更新
        update_build_info
        return 0
    else
        echo "Build failed. Status: $build_status"
        return 1
    fi
}

# デプロイを実行して結果を待機する
start_deployment() {
    import_environment_variables
    
    # 最新のビルド情報が設定されているか確認
    if [ -z "$LATEST_BUILD_ARTIFACT" ]; then
        update_build_info
        if [ -z "$LATEST_BUILD_ARTIFACT" ]; then
            echo "デプロイするビルドアーティファクトが見つかりません" >&2
            return 1
        fi
    fi
    
    echo "Starting deployment..."
    local deploy_result
    deploy_result=$(aws deploy create-deployment \
        --application-name "$PROJECT_NAME" \
        --deployment-group-name "$PROJECT_NAME-group" \
        --s3-location bucket="$S3_BUCKET_NAME",key="$LATEST_BUILD_ARTIFACT",bundleType=zip)
    
    # デプロイメントIDを取得
    local deployment_id
    if command -v jq > /dev/null; then
        deployment_id=$(echo "$deploy_result" | jq -r '.deploymentId')
    else
        deployment_id=$(echo "$deploy_result" | grep -oP '"deploymentId":\s*"\K[^"]+')
    fi
    
    echo "Deployment ID: $deployment_id"
    echo "Checking deployment status..."
    
    local status
    local deploy_status="InProgress"
    
    while [[ "$deploy_status" == "InProgress" || "$deploy_status" == "Created" || "$deploy_status" == "Queued" ]]; do
        sleep 10
        status=$(aws deploy get-deployment --deployment-id "$deployment_id")
        
        if command -v jq > /dev/null; then
            deploy_status=$(echo "$status" | jq -r '.deploymentInfo.status')
        else
            deploy_status=$(echo "$status" | grep -oP '"status":\s*"\K[^"]+' | head -1)
        fi
        
        echo "Deployment status: $deploy_status"
    done
    
    if [ "$deploy_status" == "Succeeded" ]; then
        echo "Deployment succeeded!"
        return 0
    else
        echo "Deployment failed. Status: $deploy_status"
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
