#!/usr/bin/env bash
# EC2インスタンスのステータスを確認するスクリプト

# ヘルパー関数を読み込む
INFRASTRUCTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$INFRASTRUCTURE_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# EC2インスタンスIDが設定されているか確認
if [ -z "$EC2_INSTANCE_ID" ]; then
    echo -e "\e[33mEC2インスタンスIDが環境変数に設定されていません。\e[0m"
    echo "以下の方法でEC2インスタンスを作成してください："
    echo "1. CloudFormationを使用： bash ./setup-ec2.sh"
    echo "2. 手動でEC2インスタンスを作成し、インスタンスIDを確認する"
    exit 1
fi

echo "EC2インスタンス情報を取得中..."

# インスタンス情報の取得
INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids $EC2_INSTANCE_ID)

if [ $? -ne 0 ]; then
    echo "EC2インスタンス情報の取得に失敗しました。インスタンスIDを確認してください: $EC2_INSTANCE_ID"
    exit 1
fi

# インスタンスステータスの取得
if command -v jq > /dev/null; then
    STATE=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].State.Name')
    PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].PublicIpAddress')
    PRIVATE_IP=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
    INSTANCE_TYPE=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].InstanceType')
    AZ=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].Placement.AvailabilityZone')
    LAUNCH_TIME=$(echo "$INSTANCE_INFO" | jq -r '.Reservations[0].Instances[0].LaunchTime')
else
    # jqがない場合は簡易表示
    echo "$INSTANCE_INFO"
    exit 0
fi

# 表示
echo "===== EC2インスタンス情報 ====="
echo "インスタンスID: $EC2_INSTANCE_ID"
echo "ステータス: $STATE"
echo "インスタンスタイプ: $INSTANCE_TYPE"
echo "アベイラビリティゾーン: $AZ"
echo "パブリックIP: $PUBLIC_IP"
echo "プライベートIP: $PRIVATE_IP"
echo "起動時間: $LAUNCH_TIME"
echo "============================="

# アプリケーションアクセス情報
if [ "$STATE" == "running" ] && [ ! -z "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "null" ]; then
    echo ""
    echo "アプリケーションアクセス情報："
    echo "アプリケーションURL: http://$PUBLIC_IP:3000"
    echo "ヘルスチェックURL: http://$PUBLIC_IP:3000/health"
    echo ""
    echo "SSHアクセス例："
    echo "ssh -i your-key.pem ubuntu@$PUBLIC_IP"
fi
