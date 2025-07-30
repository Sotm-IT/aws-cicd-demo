#!/usr/bin/env bash
# EC2インスタンスをCloudFormationを使って作成するスクリプト
set -e

# ヘルパー関数を読み込む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$SCRIPT_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

# 環境変数を読み込む
import_environment_variables

# CloudFormationテンプレートのパス
TEMPLATE_PATH="$SCRIPT_DIR/ec2-instance-template.json"

# スタック名
STACK_NAME="${PROJECT_NAME}-ec2-stack"

# パラメータの準備
echo "EC2インスタンスの作成を開始します..."

# 必須パラメータの入力要求
echo "以下のパラメータを入力してください："
read -p "キーペア名 (SSH接続用): " KEY_NAME
read -p "VPC ID: " VPC_ID
read -p "サブネット ID: " SUBNET_ID
read -p "インスタンスタイプ [t2.micro]: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-t2.micro}

# 環境タグ値の確認と設定
read -p "環境タグ値 [$EC2_TAG_VALUE]: " CUSTOM_TAG_VALUE
EC2_TAG_VALUE=${CUSTOM_TAG_VALUE:-$EC2_TAG_VALUE}
echo "環境タグ: $EC2_TAG_KEY=$EC2_TAG_VALUE"

# CloudFormationスタックの作成
echo "CloudFormationスタックを作成中..."
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://$TEMPLATE_PATH \
  --parameters \
    ParameterKey=KeyName,ParameterValue=$KEY_NAME \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=SubnetId,ParameterValue=$SUBNET_ID \
    ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
    ParameterKey=EnvironmentTag,ParameterValue=$EC2_TAG_VALUE \
    ParameterKey=EnvironmentTagKey,ParameterValue=$EC2_TAG_KEY \
    ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME \
  --capabilities CAPABILITY_NAMED_IAM

if [ $? -eq 0 ]; then
    echo "スタック作成リクエストが成功しました。作成の進捗を確認しています..."
    
    # スタックの状態を監視
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
    
    if [ $? -eq 0 ]; then
        echo "EC2インスタンスの作成が完了しました！"
        
        # スタックの出力を取得して表示
        echo "インスタンス情報："
        aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --query "Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}" \
            --output table
            
        # env-config.shに環境変数を追加
        INSTANCE_ID=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" \
            --output text)
            
        PUBLIC_IP=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --query "Stacks[0].Outputs[?OutputKey=='PublicIp'].OutputValue" \
            --output text)
            
        echo ""
        echo "以下の情報を環境変数に追加します："
        echo "EC2_INSTANCE_ID=$INSTANCE_ID"
        echo "EC2_PUBLIC_IP=$PUBLIC_IP"
        echo "EC2_TAG_VALUE=$EC2_TAG_VALUE"
        
        # バックアップの作成
        cp ../env-config.sh ../env-config.sh.bak
        
        # 環境変数をenv-config.shに追加
        if grep -q "EC2_INSTANCE_ID" ../env-config.sh; then
            # 既存の変数を更新
            sed -i "s/export EC2_INSTANCE_ID=.*/export EC2_INSTANCE_ID=\"$INSTANCE_ID\"/" ../env-config.sh
        else
            # 新しい変数を追加
            echo -e "\n# EC2インスタンス情報\nexport EC2_INSTANCE_ID=\"$INSTANCE_ID\"" >> ../env-config.sh
        fi
        
        if grep -q "EC2_PUBLIC_IP" ../env-config.sh; then
            # 既存の変数を更新
            sed -i "s/export EC2_PUBLIC_IP=.*/export EC2_PUBLIC_IP=\"$PUBLIC_IP\"/" ../env-config.sh
        else
            # 新しい変数を追加
            echo "export EC2_PUBLIC_IP=\"$PUBLIC_IP\"" >> ../env-config.sh
        fi
        
        # EC2_TAG_VALUEを更新
        if grep -q "EC2_TAG_VALUE" ../env-config.sh; then
            # 既存の変数を更新
            sed -i "s/export EC2_TAG_VALUE=.*/export EC2_TAG_VALUE=\"$EC2_TAG_VALUE\" # EC2インスタンスのタグ値（setup-ec2.sh実行時に上書きされる場合があります）/" ../env-config.sh
        fi
        
        echo ""
        echo "環境変数ファイルを更新しました: ../env-config.sh"
        echo "設定が完了しました！"
    else
        echo "EC2インスタンスの作成に失敗しました。AWS CloudFormationコンソールで詳細を確認してください。"
    fi
else
    echo "スタック作成リクエストに失敗しました。エラーを確認してください。"
fi
