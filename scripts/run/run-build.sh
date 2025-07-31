#!/usr/bin/env bash
# Bashスクリプト
set -e

# ヘルパー関数を読み込む
RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER_PATH="$(dirname "$RUN_DIR")/helpers/helpers.sh"
source "$HELPER_PATH"

echo -e "\e[36mAWS CI/CD Demo - Build Execution Script\e[0m"
import_environment_variables

# コマンド実行
start_build
echo -e "\e[32mBuild completed. Artifact: $LATEST_BUILD_ARTIFACT\e[0m"
