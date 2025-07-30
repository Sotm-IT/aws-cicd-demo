# AWS CI/CD Demo

このリポジトリは、AWS上でCI/CDパイプラインのデモを行うためのシンプルなNode.jsアプリケーションです。

## 概要
Expressを使ったWebアプリケーションで、ルートパス(`/`)にアクセスすると「Hello from AWS CI/CD Demo!」と表示されます。

## 必要条件
- Node.js 16以上
- npm
- AWS CLI (バージョン2推奨)
- AWS アカウント
- Ubuntu環境
- PM2（本番環境での実行用）
- jq (JSONパース用、オプションですがインストールを推奨)

## セットアップ方法
1. 依存パッケージのインストール
   ```bash
   npm install
   ```
2. アプリケーションの起動
   ```bash
   node app.js
   ```
3. ブラウザで `http://localhost:3000` にアクセス

## EC2セットアップ（デプロイ先の準備）
1. EC2インスタンスに `Environment:Development` タグを付与（各自で設定した値）

2. Ubuntu EC2インスタンスにSSH接続し、以下のセットアップを実行
   ```bash
   # 必要なパッケージの更新
   sudo apt update

```bash
# Node.jsインストール
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# CodeDeployエージェントのインストール
sudo apt install -y ruby-full wget
wget https://aws-codedeploy-ap-northeast-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto   # PM2のインストール
   sudo npm install -g pm2
   ```

## AWS CI/CD パイプラインの手順

このアプリケーションのAWS CI/CDパイプラインは、以下のステップで構築および実行されます。

### ステップ1：AWS環境のセットアップ
1. AWS CLI認証情報の設定
   ```bash
   aws configure
   # アクセスキー、シークレットキー、リージョン等を入力
   ```

2. CodeBuild環境のセットアップ
   ```bash
   bash ./scripts/setup/setup-codebuild.sh
   ```
   このスクリプトは以下を行います：
   - S3バケット作成（ビルドアーティファクト保存用）
   - IAMロール作成（CodeBuild実行権限用）
   - CodeBuildプロジェクト作成

3. CodeDeploy環境のセットアップ
   ```bash
   bash ./scripts/setup/setup-codedeploy.sh
   ```
   このスクリプトは以下を行います：
   - IAMロール作成（CodeDeploy実行権限用）
   - CodeDeployアプリケーション作成
   - デプロイグループ作成（EC2インスタンスの指定）

### ステップ2：ビルドの実行

CodeBuildでソースコードをビルドして、アーティファクト（デプロイ可能なパッケージ）を作成します：

```bash
# 簡易コマンド（環境変数を使用）
bash ./scripts/run/run-build.sh
```

ビルドが成功すると、以下の処理が実行されます：
- `buildspec.yml`に基づいてビルド・テスト実行
- 必要なファイルがZIPアーカイブとしてS3バケットに保存

### ステップ3：デプロイの実行

ビルドアーティファクトをEC2インスタンスにデプロイします：

```bash
# 簡易コマンド（環境変数を使用）
bash ./scripts/run/run-deploy.sh
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

## 環境設定

このプロジェクトでは、AWS認証情報やリソース名などの環境変数を一元管理しています。これにより、アカウントIDやビルドアーティファクト名を手動で入力する必要がなくなります。

### 設定ファイル

環境変数は `scripts/env-config.sh` で管理され、以下の変数が定義されています：

- `AWS_REGION` - 使用するAWSリージョン
- `PROJECT_NAME` - プロジェクト名
- `ACCOUNT_ID` - AWSアカウントID（自動取得）
- `S3_BUCKET_NAME` - S3バケット名
- `EC2_TAG_KEY` - EC2インスタンスのタグキー
- `EC2_TAG_VALUE` - EC2インスタンスのタグ値
- `LATEST_BUILD_ID` - 最新のビルドID
- `LATEST_BUILD_ARTIFACT` - 最新のビルドアーティファクト名

設定ファイルは、各セットアップ手順の実行前に必要に応じて編集してください。特に、`EC2_TAG_KEY`と`EC2_TAG_VALUE`はEC2インスタンスのタグに合わせて変更してください。

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
   - `scripts/env-config.sh`ファイルが存在するか確認
   - AWS認証情報が正しく設定されているか確認: `aws configure`
   - スクリプトに実行権限があるか確認: `chmod +x scripts/**/*.sh`

---

## 環境セットアップ

環境セットアップの詳細な手順については、このリポジトリの `SETUP.md` を参照してください。

簡単な手順：

1. AWS CLI認証情報の設定
   ```bash
   aws configure
   ```

2. スクリプトに実行権限を付与
   ```bash
   chmod +x scripts/env-config.sh scripts/helpers/helpers.sh scripts/run/*.sh scripts/setup/*.sh scripts/deploy/*.sh
   ```

AWS CI/CDパイプラインを使ったデモアプリケーションをお楽しみください。
