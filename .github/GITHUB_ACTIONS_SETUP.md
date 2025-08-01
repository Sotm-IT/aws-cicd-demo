# GitHub Actions → AWS CodeBuild/CodeDeploy Setup Guide

このファイルは、GitHub ActionsをトリガーとしてAWS CodeBuildとCodeDeployを呼び出すCI/CDパイプラインのセットアップ手順を説明します。

## 前提条件

1. **AWSリソースが既に作成済み**であること
   - CodeBuild Project: `aws-cicd-demo-build`
   - CodeDeploy Application: `aws-cicd-demo-app`
   - Deployment Group: `aws-cicd-demo-deployment-group`
   - S3 Bucket: `aws-cicd-demo-codebuild-bucket-{ACCOUNT_ID}`
   - EC2 Instance (Environment: Development タグ付き)

2. **GitHub Repository**にプッシュされていること

## セットアップ手順

### 1. GitHub Secretsの設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下のSecretsを追加：

**手順:**
1. GitHubリポジトリページで `Settings` タブをクリック
2. 左側メニューから `Secrets and variables` > `Actions` を選択
3. `New repository secret` をクリックして以下を追加：

```
Name: AWS_ACCESS_KEY_ID
Secret: [IAMユーザーのアクセスキーID]

Name: AWS_SECRET_ACCESS_KEY  
Secret: [IAMユーザーのシークレットアクセスキー]
```

**⚠️ 重要:** これらの値は、前述のIAM権限を持つAWSユーザーのアクセスキーです。

### 2. AWS IAMユーザーの権限設定

GitHub Actions用のIAMユーザーに以下の権限が必要：

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::aws-cicd-demo-codebuild-bucket-*",
                "arn:aws:s3:::aws-cicd-demo-codebuild-bucket-*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:StartBuild",
                "codebuild:BatchGetBuilds",
                "codebuild:ListBuildsForProject"
            ],
            "Resource": "arn:aws:codebuild:*:*:project/aws-cicd-demo-build"
        },
        {
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplication",
                "codedeploy:GetDeployment",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:RegisterApplicationRevision"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

## トラブルシューティング

### 1. AWS認証エラー
- GitHub Secretsが正しく設定されているか確認
- IAMユーザーの権限を確認

### 2. S3アップロードエラー
- S3バケットが存在するか確認
- バケットの権限設定を確認

### 3. CodeDeployエラー
- CodeDeployアプリケーションとデプロイグループが存在するか確認
- EC2インスタンスに正しいタグが設定されているか確認
- CodeDeploy Agentが実行中か確認

### 4. ヘルスチェック失敗
- EC2インスタンスが実行中か確認
- セキュリティグループでポート3000が開放されているか確認
- アプリケーションが正常に起動しているか確認

## 比較: GitHub Actions vs 既存のAWS CodeBuild

| 項目 | GitHub Actions | AWS CodeBuild |
|------|----------------|---------------|
| **実行環境** | GitHub-hosted runners | AWS managed build service |
| **設定方法** | YAML workflow | buildspec.yml |
| **並列実行** | Matrix builds | Single build |
| **アーティファクト管理** | GitHub Artifacts + S3 | S3のみ |
| **コスト** | 無料枠あり | 実行時間ベース |
| **カスタマイズ性** | 高い | 中程度 |
| **統合** | GitHub ecosystem | AWS ecosystem |

## 次のステップ

1. **ブランチ保護ルール**の設定
2. **環境固有デプロイメント**の実装 (staging, production)
3. **Slack通知**の追加
4. **セキュリティスキャン**の統合
5. **パフォーマンステスト**の自動化

## 参考リンク

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS CodeDeploy User Guide](https://docs.aws.amazon.com/codedeploy/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
