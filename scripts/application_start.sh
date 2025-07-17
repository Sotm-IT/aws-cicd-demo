#!/bin/bash
# アプリケーションディレクトリに移動
cd /var/www/html/aws-cicd-demo

# 既存アプリケーションの停止（存在する場合）
pm2 stop aws-demo 2>/dev/null || true

# 新しいアプリケーションの起動
echo "Starting application..."
pm2 start app.js --name aws-demo