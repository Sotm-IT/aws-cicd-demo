#!/bin/bash
# EC2インスタンスを削除するスクリプト
set -e

# ヘルパー関数を読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SCRIPT_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# スタック名
STACK_NAME="${PROJECT_NAME}-ec2-stack"

echo "EC2インスタンス（スタック名: $STACK_NAME）の削除を開始します..."

# ユーザー確認
read -p "EC2インスタンスを削除しますか？この操作は元に戻せません。 (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "操作をキャンセルしました。"
    exit 0
fi

# CloudFormationスタックの削除
echo "CloudFormationスタックを削除中..."
aws cloudformation delete-stack --stack-name $STACK_NAME

if [ $? -eq 0 ]; then
    echo "削除リクエストが成功しました。スタックの削除を待機中..."
    
    # スタックの削除を待機
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
    
    if [ $? -eq 0 ]; then
        echo "EC2インスタンスの削除が完了しました！"
        
        # env-config.shから関連環境変数を削除
        cp ../env-config.sh ../env-config.sh.bak
        
        # 環境変数を削除
        sed -i '/EC2_INSTANCE_ID/d' ../env-config.sh
        sed -i '/EC2_PUBLIC_IP/d' ../env-config.sh
        
        echo "環境変数ファイルを更新しました: ../env-config.sh"
    else
        echo "スタックの削除に問題が発生しました。AWS CloudFormationコンソールで詳細を確認してください。"
    fi
else
    echo "削除リクエストに失敗しました。エラーを確認してください。"
fi
