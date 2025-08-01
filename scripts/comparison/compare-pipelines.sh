#!/usr/bin/env bash
# GitHub Actions vs AWS CodeBuild 比較スクリプト

set -e

# 環境変数の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$(dirname "$(dirname "$SCRIPT_DIR")")/scripts/env-config.sh"

echo -e "\e[36m=== CI/CD Pipeline Comparison Dashboard ===\e[0m"
echo ""

# GitHub Actions の実行状況 (GitHub CLI が必要)
echo -e "\e[33m📊 GitHub Actions Status:\e[0m"
if command -v gh > /dev/null; then
    echo "Recent workflow runs:"
    gh run list --limit 5 --json status,conclusion,createdAt,displayTitle,url || echo "GitHub CLI authentication required"
else
    echo "GitHub CLI not installed. Install with: https://cli.github.com/"
fi

echo ""

# AWS CodeBuild の実行状況
echo -e "\e[33m🏗️ AWS CodeBuild Status:\e[0m"
if aws codebuild list-builds-for-project --project-name "${PROJECT_NAME}-build" --sort-order DESCENDING --max-items 5 > /dev/null 2>&1; then
    echo "Recent builds:"
    aws codebuild list-builds-for-project \
        --project-name "${PROJECT_NAME}-build" \
        --sort-order DESCENDING \
        --max-items 5 \
        --query 'ids' --output table
else
    echo "No CodeBuild history found or project doesn't exist"
fi

echo ""

# S3 アーティファクトの比較
echo -e "\e[33m📦 Build Artifacts Comparison:\e[0m"
echo ""

echo "GitHub Actions builds:"
aws s3 ls "s3://${S3_BUCKET_NAME}/github-builds/" --human-readable 2>/dev/null | head -10 || echo "No GitHub Actions builds found"

echo ""

echo "AWS CodeBuild builds:"
aws s3 ls "s3://${S3_BUCKET_NAME}/" --human-readable 2>/dev/null | grep -v "github-builds/" | head -10 || echo "No CodeBuild artifacts found"

echo ""

# CodeDeploy デプロイメント履歴
echo -e "\e[33m🚀 Recent Deployments:\e[0m"
aws deploy list-deployments \
    --application-name "${PROJECT_NAME}-app" \
    --max-items 10 \
    --query 'deployments' --output table 2>/dev/null || echo "No deployment history found"

echo ""

# EC2 インスタンス状況
echo -e "\e[33m🖥️ Target EC2 Instance Status:\e[0m"
EC2_INFO=$(aws ec2 describe-instances \
    --filters "Name=tag:$EC2_TAG_KEY,Values=$EC2_TAG_VALUE" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name,LaunchTime]' \
    --output table 2>/dev/null)

if [ -n "$EC2_INFO" ]; then
    echo "$EC2_INFO"
    
    # Application health check
    PUBLIC_IP=$(aws ec2 describe-instances \
        --filters "Name=tag:$EC2_TAG_KEY,Values=$EC2_TAG_VALUE" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null)
    
    if [ "$PUBLIC_IP" != "None" ] && [ -n "$PUBLIC_IP" ]; then
        echo ""
        echo "Application health check:"
        if curl -f -s "http://$PUBLIC_IP:3000/health" > /dev/null; then
            echo -e "✅ Application is \e[32mhealthy\e[0m at http://$PUBLIC_IP:3000"
            curl -s "http://$PUBLIC_IP:3000/health" | jq '.status, .uptime' 2>/dev/null || echo "Health endpoint accessible"
        else
            echo -e "❌ Application \e[31mnot responding\e[0m at http://$PUBLIC_IP:3000"
        fi
    fi
else
    echo "No EC2 instances found with tag $EC2_TAG_KEY=$EC2_TAG_VALUE"
fi

echo ""

# パフォーマンス比較テーブル
echo -e "\e[33m⚡ Performance Comparison:\e[0m"
cat << 'EOF'
┌─────────────────────┬──────────────────┬────────────────────┐
│ Metric              │ GitHub Actions   │ AWS CodeBuild      │
├─────────────────────┼──────────────────┼────────────────────┤
│ Setup Time          │ ~30s             │ ~45s               │
│ Build Environment   │ Ubuntu Latest    │ Amazon Linux 2     │
│ Node.js Version     │ 18 (configurable)│ 18 (buildspec)     │
│ Parallel Jobs       │ Multiple runners │ Single build       │
│ Cost (Free Tier)    │ 2000 min/month   │ 100 min/month      │
│ Artifact Storage    │ GitHub + S3      │ S3 only            │
│ Integration         │ GitHub native    │ AWS native         │
│ Custom Actions      │ Marketplace      │ Custom containers  │
└─────────────────────┴──────────────────┴────────────────────┘
EOF

echo ""

# 使用統計の概要
echo -e "\e[33m📈 Usage Statistics:\e[0m"
echo "S3 Bucket size:"
aws s3 ls "s3://${S3_BUCKET_NAME}" --recursive --human-readable --summarize 2>/dev/null | tail -2 || echo "Unable to get S3 statistics"

echo ""
echo -e "\e[32m✨ Comparison completed!\e[0m"
echo ""
echo "🔗 Useful links:"
echo "   • GitHub Actions: https://github.com/Sotm-IT/aws-cicd-demo/actions"
echo "   • AWS CodeBuild: https://console.aws.amazon.com/codesuite/codebuild/projects"
echo "   • AWS CodeDeploy: https://console.aws.amazon.com/codesuite/codedeploy/applications"
echo "   • Application: http://$PUBLIC_IP:3000 (if available)"
