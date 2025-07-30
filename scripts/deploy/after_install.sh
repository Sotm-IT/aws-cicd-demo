#!/bin/bash
# 厳格モードを有効化
set -e

# アプリケーションディレクトリに移動
cd /var/www/html/aws-cicd-demo || {
    echo "Failed to navigate to application directory"
    exit 1
}

# 依存関係のインストール
echo "Installing dependencies..."
npm install --production || {
    echo "Failed to install dependencies"
    exit 1
}

# 権限の設定
echo "Setting permissions..."
chmod -R 755 /var/www/html/aws-cicd-demo || {
    echo "Failed to set permissions"
    exit 1
}

echo "After-install script completed successfully"
