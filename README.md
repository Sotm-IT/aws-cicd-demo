# AWS CI/CD Demo

このリポジトリは、AWS上でCI/CDパイプラインのデモを行うためのシンプルなNode.jsアプリケーションです。

## 概要
Expressを使ったWebアプリケーションで、ルートパス(`/`)にアクセスすると「Hello from AWS CI/CD Demo!」と表示されます。

## 必要条件
- Node.js 16以上
- npm
- AWS CLI
- AWS アカウント
- PowerShell (AWS設定スクリプト実行用)
- PM2（本番環境での実行用）

## セットアップ方法
1. 依存パッケージのインストール
   ```powershell
   npm install
   ```
2. アプリケーションの起動
   ```powershell
   node app.js
   ```
3. ブラウザで `http://localhost:3000` にアクセス

## EC2セットアップ（デプロイ先の準備）
1. EC2インスタンスに `Environment:Development` タグを付与（各自で設定した値）

2. EC2にSSH接続し、以下のセットアップを実行
   ```bash
   # Node.jsインストール
   curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
   sudo yum install -y nodejs

   # CodeDeployエージェントのインストール
   sudo yum install -y ruby wget
   wget https://aws-codedeploy-ap-northeast-1.s3.amazonaws.com/latest/install
   chmod +x ./install
   sudo ./install auto

   # PM2のインストール
   sudo npm install -g pm2
   ```

## AWS環境セットアップ
1. AWS CLI認証情報の設定
   ```powershell
   aws configure
   ```

2. CodeBuild環境のセットアップ
   ```powershell
   ./aws-config/Setup-CodeBuild.ps1
   ```

3. CodeDeploy環境のセットアップ
   ```powershell
   ./aws-config/Setup-CodeDeploy.ps1
   ```

## CI/CD パイプライン
このアプリケーションは以下のCI/CDフローで自動デプロイされます：

1. **CodeBuild**: `buildspec.yml`に基づきビルド・テスト実行
2. **CodeDeploy**: `appspec.yml`に基づき、デプロイグループ内のEC2インスタンスにデプロイ
3. **デプロイプロセス**: 
   - EC2インスタンスで依存パッケージのインストール 
   - PM2を使用してアプリケーションを起動

---
ご自由にご利用ください。
