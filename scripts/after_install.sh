#!/bin/bash
# アプリケーションディレクトリに移動
cd /var/www/html/aws-cicd-demo

# 依存関係のインストール - ここでnpm installを実行
echo "Installing dependencies..."
npm install --production

# 権限の設定
chmod -R 755 /var/www/html/aws-cicd-demo