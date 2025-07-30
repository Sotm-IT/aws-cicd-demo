#!/usr/bin/env bash
# 厳格モードを有効化
set -e

echo "Preparing deployment directory..."

# デプロイディレクトリの作成
mkdir -p /var/www/html/aws-cicd-demo || {
    echo "Failed to create deployment directory"
    exit 1
}

# 既存のアプリケーションファイルをバックアップ（オプション）
if [ -f /var/www/html/aws-cicd-demo/app.js ]; then
    echo "Backing up existing application..."
    backup_dir="/var/www/html/aws-cicd-demo-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp -r /var/www/html/aws-cicd-demo/* "$backup_dir/" 2>/dev/null || true
    echo "Backup created at $backup_dir"
fi

echo "Before-install script completed successfully"
