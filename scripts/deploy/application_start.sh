#!/bin/bash
# アプリケーションディレクトリに移動
cd /var/www/html/aws-cicd-demo

# 既存アプリケーションの停止（存在する場合）
pm2 stop aws-demo 2>/dev/null || true
pm2 delete aws-demo 2>/dev/null || true

# 新しいアプリケーションの起動
echo "Starting application..."
pm2 start app.js --name aws-demo

# PM2の起動スクリプトを保存（再起動時に自動起動するため）
pm2 save

echo "Application started successfully!"
echo "Health check: http://localhost:3000/health"
