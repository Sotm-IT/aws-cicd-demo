# AWS CI/CD デモ

このリポジトリは、AWS上でCI/CDパイプラインのデモを行うためのシンプルなNode.jsアプリケーションです。このREADMEに沿って手順を実行すれば、完全なCI/CDパイプラインを構築できます。

![アーキテクチャ](Architecture.drawio.svg)

## 1. 概要

Expressを使ったWebアプリケーションで、ルートパス(`/`)にアクセスすると「Hello from AWS CI/CD Demo!」と表示されます。このアプリケーションをAWS CI/CDパイプラインを使って自動ビルド・デプロイします。

### システム構成

- **アプリケーション**: Node.js/Expressサーバー
- **CI/CDパイプライン**: AWS CodeBuild + AWS CodeDeploy
- **デプロイ先**: EC2インスタンス（Ubuntu）

## 2. 必要条件

### 開発環境
- Node.js 16以上
- npm
- AWS CLI (バージョン2推奨)
- AWS アカウント（適切な権限設定済み）
- Ubuntu環境
- jq (JSONパース用、オプション)

### デプロイ環境（EC2）
- Ubuntu Server 22.04 LTS
- Node.js 16以上
- PM2（アプリケーション管理用）
- AWS CodeDeploy Agent

## 3. 環境セットアップ

### AWS CLI のインストール（開発環境）

```bash
# 必要なパッケージのインストール
sudo apt update
sudo apt install -y unzip curl

# AWS CLI v2のダウンロードとインストール
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# バージョン確認
aws --version
```

### AWS 認証情報の設定

```bash
aws configure
# アクセスキー、シークレットキー、リージョン等を入力
```

### プロジェクトの準備

```bash
# 依存パッケージのインストール
npm install

# スクリプトに実行権限を付与
chmod +x scripts/env-config.sh scripts/helpers/helpers.sh scripts/run/*.sh scripts/setup/*.sh scripts/deploy/*.sh scripts/infrastructure/*.sh
```

## 4. デプロイ環境の準備（EC2）

本プロジェクトでは、EC2インスタンスをコードで管理するためのCloudFormationテンプレートとスクリプトを提供しています：

```bash
# EC2インスタンスの作成
npm run ec2:create

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/infrastructure/setup-ec2.sh
```

スクリプト実行時に以下の情報を入力します：
- キーペア名（SSHアクセス用）
- VPC ID
- サブネット ID
- インスタンスタイプ（デフォルト: t2.micro）
- 環境タグ値（デフォルト: Development）

このスクリプトは以下を自動的に実行します：
- UbuntuベースのEC2インスタンスの作成
- セキュリティグループの設定（SSH、HTTP、アプリケーションポート）
- 必要なIAMロールとインスタンスプロファイルの作成
- Node.js、AWS CLI、CodeDeployエージェント、PM2のインストール
- アプリケーション用のディレクトリ構造の作成

## 5. CI/CDパイプラインのセットアップ

### CodeBuild 環境のセットアップ

```bash
npm run setup:build

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/setup/setup-codebuild.sh
```

このスクリプトは以下を行います：
- S3バケット作成（ビルドアーティファクト保存用）
- IAMロール作成（CodeBuild実行権限用）
- CodeBuildプロジェクト作成

### CodeDeploy 環境のセットアップ

```bash
npm run setup:deploy

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/setup/setup-codedeploy.sh
```

このスクリプトは以下を行います：
- IAMロール作成（CodeDeploy実行権限用）
- CodeDeployアプリケーション作成
- デプロイグループ作成（EC2インスタンスの指定）

## 6. ビルドとデプロイの実行

### ビルドの実行

```bash
npm run deploy:build

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/run/run-build.sh
```

ビルドが成功すると、以下の処理が実行されます：
- `buildspec.yml`に基づいてビルド・テスト実行
- 必要なファイルがZIPアーカイブとしてS3バケットに保存

### デプロイの実行

```bash
npm run deploy:apply

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/run/run-deploy.sh
```

デプロイが成功すると、以下の処理が実行されます：
- `appspec.yml`に基づき、EC2インスタンスに配置
- スクリプトによる依存関係のインストール
- PM2を使ってNode.jsアプリを起動

## 7. アプリケーションの確認

デプロイが成功すると、EC2インスタンス上でExpressアプリケーションが起動します：

1. EC2インスタンスのパブリックIPを確認
   ```bash
   source ./scripts/env-config.sh
   echo $EC2_PUBLIC_IP
   ```

2. ブラウザで `http://<EC2インスタンスのIP>:3000` にアクセス
3. 「Hello from AWS CI/CD Demo!」というメッセージが表示されれば成功

## 8. GitHub Actions CI/CD（新機能）

このプロジェクトは、AWS CodeBuildに加えて**GitHub Actions**による CI/CD パイプラインもサポートしています。

### 特徴
- **自動トリガー**: `main` や `develop` ブランチへのプッシュで自動実行
- **並列処理**: ビルド、アップロード、デプロイを段階的に実行
- **環境保護**: Production環境での承認フロー
- **ヘルスチェック**: デプロイ後の自動検証

### セットアップ手順

1. **GitHub Secretsの設定**
   ```
   Settings > Secrets and variables > Actions で以下を追加:
   - AWS_ACCESS_KEY_ID: あなたのAWSアクセスキーID
   - AWS_SECRET_ACCESS_KEY: あなたのAWSシークレットアクセスキー
   ```

2. **ワークフローの実行**
   - 自動実行: `main` ブランチにプッシュ
   - 手動実行: GitHub の Actions タブから「Run workflow」

3. **詳細な設定ガイド**
   - [GitHub Actions Setup Guide](.github/GITHUB_ACTIONS_SETUP.md) を参照

### パイプライン比較

```bash
# GitHub Actions vs AWS CodeBuild の比較を実行
bash ./scripts/comparison/compare-pipelines.sh
```

## 9. 環境設定

このプロジェクトでは、AWS認証情報やリソース名などの環境変数を一元管理しています。

### 設定ファイル

環境変数は `scripts/env-config.sh` で管理されます。主な変数：

- `AWS_REGION` - 使用するAWSリージョン
- `PROJECT_NAME` - プロジェクト名
- `EC2_TAG_KEY` - EC2インスタンスのタグキー
- `EC2_TAG_VALUE` - EC2インスタンスのタグ値
- `EC2_INSTANCE_ID` - EC2インスタンスID（自動設定）
- `EC2_PUBLIC_IP` - EC2インスタンスのパブリックIP（自動設定）

## 9. トラブルシューティング

1. **ビルドに失敗する場合**
   - AWS管理コンソールのCodeBuildプロジェクトでログを確認
   - `buildspec.yml`の設定を確認

2. **デプロイに失敗する場合**
   - AWS管理コンソールのCodeDeployデプロイグループでログを確認
   - EC2インスタンスにCodeDeployエージェントがインストール・実行されているか確認
   - EC2インスタンスに正しいタグ（Environment:タグ値）が設定されているか確認

3. **アプリケーションが起動しない場合**
   - EC2インスタンスにSSH接続し、PM2のステータスを確認: `pm2 status`

4. **環境変数関連のエラー**
   - スクリプトが正しい場所から実行されているか確認
   - AWS認証情報が正しく設定されているか確認: `aws sts get-caller-identity`

## 10. リソースのクリーンアップ

プロジェクトが不要になった場合は、以下のコマンドで作成したAWSリソースを削除できます：

```bash
# EC2インスタンスの削除
npm run ec2:delete

# WSL環境で実行する場合は以下のコマンドを直接使用してください
bash ./scripts/infrastructure/delete-ec2.sh
```

## ファイル構成

```
aws-cicd-demo/
├── app.js                # メインアプリケーションファイル
├── package.json          # プロジェクト定義・依存関係
├── buildspec.yml         # AWS CodeBuild設定
├── appspec.yml           # AWS CodeDeploy設定
├── scripts/
│   ├── env-config.sh     # 環境変数設定
│   ├── helpers/          # ヘルパースクリプト
│   ├── run/              # 実行スクリプト
│   ├── setup/            # セットアップスクリプト
│   ├── deploy/           # デプロイスクリプト
│   └── infrastructure/   # インフラストラクチャ管理スクリプト
```

AWS CI/CDパイプラインを使ったデモアプリケーションをお楽しみください。
