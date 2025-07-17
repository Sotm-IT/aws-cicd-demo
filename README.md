# AWS CI/CD Demo

このリポジトリは、AWS上でCI/CDパイプラインのデモを行うためのシンプルなNode.jsアプリケーションです。

## 概要
Expressを使ったWebアプリケーションで、ルートパス(`/`)にアクセスすると「Hello from AWS CI/CD Demo!」と表示されます。

## 必要条件
- Node.js (推奨: 最新LTSバージョン)
- npm

## セットアップ方法
1. 依存パッケージのインストール
   ```powershell
   npm install
   ```
2. アプリケーションの起動
   ```powershell
   npm start
   # または
   node app.js
   ```
3. ブラウザで `http://localhost:3000` にアクセス

## デプロイ・CI/CD
このアプリケーションはAWS CodePipelineやCodeDeployなどのCI/CDサービスと連携して自動デプロイできます。

---
ご自由にご利用ください。
