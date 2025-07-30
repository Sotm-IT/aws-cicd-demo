#!/usr/bin/env bash
# 厳格モードを有効化
set -e

# アプリケーションディレクトリに移動
cd /var/www/html/aws-cicd-demo || {
    echo "Failed to navigate to application directory"
    exit 1
}

# 既存アプリケーションの停止（存在する場合）
echo "Stopping existing application if running..."
pm2 stop aws-demo 2>/dev/null || true
pm2 delete aws-demo 2>/dev/null || true

# 新しいアプリケーションの起動
echo "Starting application..."
pm2 start app.js --name aws-demo || {
    echo "Failed to start application with PM2"
    exit 1
}

# PM2の起動スクリプトを保存（再起動時に自動起動するため）
echo "Saving PM2 process list..."
pm2 save || {
    echo "Warning: Failed to save PM2 process list"
}

# 起動確認
echo "Waiting for application to start..."
sleep 2
if pm2 show aws-demo | grep -q "online"; then
    echo -e "\e[32mApplication started successfully!\e[0m"
    echo "Health check: http://localhost:3000/health"
else
    echo -e "\e[31mApplication may have failed to start. Check logs with 'pm2 logs aws-demo'\e[0m"
fi
