#!/bin/bash
# エラーハンドリング用共通関数

# カラー定義
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[36m"
RESET="\e[0m"

# エラーメッセージを表示して終了
error_exit() {
    echo -e "${RED}エラー: $1${RESET}" >&2
    exit 1
}

# 警告メッセージを表示
warning() {
    echo -e "${YELLOW}警告: $1${RESET}" >&2
}

# 情報メッセージを表示
info() {
    echo -e "${BLUE}情報: $1${RESET}"
}

# 成功メッセージを表示
success() {
    echo -e "${GREEN}成功: $1${RESET}"
}

# コマンド実行のラッパー
# 使用例: execute "S3バケットの作成" aws s3 mb s3://my-bucket
execute() {
    local description="$1"
    shift
    
    echo -e "${BLUE}実行: $description${RESET}"
    if "$@"; then
        success "$description が完了しました"
        return 0
    else
        local status=$?
        error_exit "$description に失敗しました (終了コード: $status)"
        return $status
    fi
}

# AWSコマンド実行の確認
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error_exit "AWS CLIがインストールされていません。インストール手順については SETUP.md を参照してください。"
    fi
    
    # AWS認証情報が設定されているか確認
    if ! aws sts get-caller-identity &> /dev/null; then
        error_exit "AWS認証情報が設定されていません。'aws configure'を実行して認証情報を設定してください。"
    fi
}

# ツールのインストール確認
check_required_tools() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            warning "$cmd が見つかりません。一部の機能が制限される可能性があります。"
        fi
    done
}

# スクリプトの実行を開始する際のメッセージ
start_script() {
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${BLUE}スクリプト実行開始: $1${RESET}"
    echo -e "${BLUE}開始時刻: $(date)${RESET}"
    echo -e "${BLUE}========================================${RESET}"
}

# スクリプトの実行を終了する際のメッセージ
end_script() {
    echo -e "${BLUE}========================================${RESET}"
    echo -e "${GREEN}スクリプト実行完了: $1${RESET}"
    echo -e "${BLUE}終了時刻: $(date)${RESET}"
    echo -e "${BLUE}========================================${RESET}"
}
