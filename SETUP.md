# AWS CI/CDデモ - 環境セットアップ手順

## 1. AWS CLIのインストールと設定

Ubuntu環境にAWS CLIをインストールする方法：

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

## 2. AWS認証情報の設定

AWS CLIの設定（アクセスキーとシークレットアクセスキーを設定）：

```bash
aws configure
```

入力を求められたら、以下の情報を入力します：
- AWS Access Key ID
- AWS Secret Access Key
- Default region name（例：ap-northeast-1）
- Default output format（json推奨）

## 3. Node.jsのインストール

Ubuntu環境でNode.jsをインストールする方法：

```bash
# NodeSourceリポジトリの追加（Node.js LTSの場合）
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Node.jsのインストール
sudo apt install -y nodejs

# バージョン確認
node --version
npm --version
```

> 注: 特定のバージョンが必要な場合は、`setup_lts.x`の代わりに`setup_16.x`などを使用できます。

## 4. jqのインストール（JSON処理用）

jqはJSONデータを処理するための便利なコマンドラインツールです。Ubuntuでは以下のようにインストールします：

```bash
sudo apt install -y jq
```

## 5. 必要なNPMパッケージのインストール

プロジェクトディレクトリに移動し、依存パッケージをインストールします：

```bash
cd /path/to/aws-cicd-demo
npm install
```

## 6. スクリプト実行権限の付与

```bash
# すべてのシェルスクリプトに実行権限を付与
find /path/to/aws-cicd-demo -name "*.sh" -exec chmod +x {} \;
```

## 7. PM2のインストール（本番環境用）

PM2は本番環境でNode.jsアプリケーションを実行するためのプロセスマネージャーです：

```bash
# PM2をグローバルにインストール
sudo npm install -g pm2

# 起動時に自動起動するように設定（オプション）
pm2 startup
```
