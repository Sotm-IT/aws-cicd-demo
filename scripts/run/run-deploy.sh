#!/usr/bin/env bash
# Bashスクリプト
set -e

# ヘルパー関数を読み込む
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$RUN_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

echo -e "\e[36mAWS CI/CD Demo - Deploy Execution Script\e[0m"
import_environment_variables

# EC2インスタンス情報の表示
get_ec2_instance_info

# デプロイ実行
start_deployment
echo -e "\e[32mDeployment completed. Please verify the application.\e[0m"
