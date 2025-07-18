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

## AWS CI/CD パイプラインの手順

このアプリケーションのAWS CI/CDパイプラインは、以下のステップで構築および実行されます。

### ステップ1：AWS環境のセットアップ
1. AWS CLI認証情報の設定
   ```powershell
   aws configure
   # アクセスキー、シークレットキー、リージョン等を入力
   ```

2. CodeBuild環境のセットアップ
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup\Setup-CodeBuild.ps1
   ```
   このスクリプトは以下を行います：
   - S3バケット作成（ビルドアーティファクト保存用）
   - IAMロール作成（CodeBuild実行権限用）
   - CodeBuildプロジェクト作成

3. CodeDeploy環境のセットアップ
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\setup\Setup-CodeDeploy.ps1
   ```
   このスクリプトは以下を行います：
   - IAMロール作成（CodeDeploy実行権限用）
   - CodeDeployアプリケーション作成
   - デプロイグループ作成（EC2インスタンスの指定）

### ステップ2：ビルドの実行

CodeBuildでソースコードをビルドして、アーティファクト（デプロイ可能なパッケージ）を作成します：

```powershell
# 簡易コマンド（環境変数を使用）
.\scripts\run\Run-Build.ps1
```

ビルドが成功すると、以下の処理が実行されます：
- `buildspec.yml`に基づいてビルド・テスト実行
- 必要なファイルがZIPアーカイブとしてS3バケットに保存

### ステップ3：デプロイの実行

ビルドアーティファクトをEC2インスタンスにデプロイします：

```powershell
# 簡易コマンド（環境変数を使用）
.\scripts\run\Run-Deploy.ps1
```

デプロイが成功すると、以下の処理が実行されます：
- `appspec.yml`に基づき、EC2インスタンスに配置
- スクリプトによる依存関係のインストール
- PM2を使ってNode.jsアプリを起動


## アプリケーションの確認

デプロイが成功すると、EC2インスタンス上でExpressアプリケーションが起動します：

1. EC2インスタンスのパブリックIPまたはドメイン名を確認
2. ブラウザで `http://<EC2インスタンスのIP>:3000` にアクセス
3. 「Hello from AWS CI/CD Demo!」というメッセージが表示されれば成功

## 環境変数の管理

このプロジェクトでは、AWS認証情報やリソース名などの環境変数を一元管理しています。これにより、アカウントIDやビルドアーティファクト名を手動で入力する必要がなくなります。

### 環境変数の設定ファイル

環境変数は `scripts/env-config.ps1` で管理され、以下の変数が定義されています：

- `$ENV:AWS_REGION` - 使用するAWSリージョン
- `$ENV:PROJECT_NAME` - プロジェクト名
- `$ENV:ACCOUNT_ID` - AWSアカウントID（自動取得）
- `$ENV:S3_BUCKET_NAME` - S3バケット名
- `$ENV:EC2_TAG_KEY` - EC2インスタンスのタグキー
- `$ENV:EC2_TAG_VALUE` - EC2インスタンスのタグ値
- `$ENV:LATEST_BUILD_ID` - 最新のビルドID
- `$ENV:LATEST_BUILD_ARTIFACT` - 最新のビルドアーティファクト名

環境変数ファイルは、各セットアップ手順の実行前に必要に応じて編集してください。特に、`$ENV:EC2_TAG_KEY`と`$ENV:EC2_TAG_VALUE`はEC2インスタンスのタグに合わせて変更してください。

## トラブルシューティング

1. **ビルドに失敗する場合**
   - AWS管理コンソールのCodeBuildプロジェクトでログを確認
   - `buildspec.yml`の設定を確認
   - 権限不足の場合はIAMロールに必要な権限を追加

2. **デプロイに失敗する場合**
   - AWS管理コンソールのCodeDeployデプロイグループでログを確認
   - EC2インスタンスにCodeDeployエージェントがインストール・実行されているか確認
   - EC2インスタンスに正しいタグ（Environment:Development）が設定されているか確認

3. **アプリケーションが起動しない場合**
   - EC2インスタンスにSSH接続し、アプリケーションログを確認
   - PM2のステータスを確認: `pm2 status`
   - Node.jsの依存関係が正しくインストールされているか確認

4. **環境変数関連のエラー**
   - スクリプトが正しい場所から実行されているか確認
   - `scripts/env-config.ps1`ファイルが存在するか確認
   - AWS認証情報が正しく設定されているか確認: `aws configure`

---
AWS CI/CDパイプラインを使ったデモアプリケーションをお楽しみください。
