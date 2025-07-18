# AWS CI/CDデモ用ヘルパー関数

# 環境変数を読み込む
function Import-EnvironmentVariables {
    # 環境変数設定ファイルを読み込む
    $envConfigPath = Join-Path (Split-Path -Parent $PSScriptRoot) "env-config.ps1"
    if (Test-Path $envConfigPath) {
        . $envConfigPath
        return $true
    } else {
        Write-Error "環境変数設定ファイルが見つかりません: $envConfigPath"
        return $false
    }
}

# ビルドを実行して結果を待機する
function Start-Build {
    Import-EnvironmentVariables

    Write-Host "Starting build..."
    $buildResult = aws codebuild start-build --project-name $ENV:PROJECT_NAME | ConvertFrom-Json
    $buildId = $buildResult.build.id
    
    Write-Host "Build ID: $buildId"
    Write-Host "Checking build status..."
    
    do {
        Start-Sleep -Seconds 10
        $status = aws codebuild batch-get-builds --ids $buildId | ConvertFrom-Json
        $buildStatus = $status.builds[0].buildStatus
        $phase = $status.builds[0].currentPhase
        Write-Host "Current phase: $phase - Status: $buildStatus"
    } while ($buildStatus -eq "IN_PROGRESS")
    
    if ($buildStatus -eq "SUCCEEDED") {
        Write-Host "Build succeeded!"
        # 最新のビルド情報を更新
        Update-BuildInfo
        return $true
    } else {
        Write-Host "Build failed. Status: $buildStatus"
        return $false
    }
}

# デプロイを実行して結果を待機する
function Start-Deployment {
    Import-EnvironmentVariables
    
    # 最新のビルド情報が設定されているか確認
    if ([string]::IsNullOrEmpty($ENV:LATEST_BUILD_ARTIFACT)) {
        Update-BuildInfo
        if ([string]::IsNullOrEmpty($ENV:LATEST_BUILD_ARTIFACT)) {
            Write-Error "デプロイするビルドアーティファクトが見つかりません"
            return $false
        }
    }
    
    Write-Host "Starting deployment..."
    $deployResult = aws deploy create-deployment `
        --application-name $ENV:PROJECT_NAME `
        --deployment-group-name "$ENV:PROJECT_NAME-group" `
        --s3-location bucket=$ENV:S3_BUCKET_NAME,key=$ENV:LATEST_BUILD_ARTIFACT,bundleType=zip | ConvertFrom-Json
    
    $deploymentId = $deployResult.deploymentId
    Write-Host "Deployment ID: $deploymentId"
    Write-Host "Checking deployment status..."
    
    do {
        Start-Sleep -Seconds 10
        $status = aws deploy get-deployment --deployment-id $deploymentId | ConvertFrom-Json
        $deployStatus = $status.deploymentInfo.status
        Write-Host "Deployment status: $deployStatus"
    } while ($deployStatus -eq "InProgress" -or $deployStatus -eq "Created" -or $deployStatus -eq "Queued")
    
    if ($deployStatus -eq "Succeeded") {
        Write-Host "Deployment succeeded!"
        return $true
    } else {
        Write-Host "Deployment failed. Status: $deployStatus"
        return $false
    }
}

# EC2インスタンスの情報を取得
function Get-EC2InstanceInfo {
    Import-EnvironmentVariables
    
    $instances = aws ec2 describe-instances --filters "Name=tag:$ENV:EC2_TAG_KEY,Values=$ENV:EC2_TAG_VALUE" --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]" --output json | ConvertFrom-Json
    
    Write-Host "デプロイ対象のEC2インスタンス:"
    foreach ($instance in $instances) {
        Write-Host "ID: $($instance[0]), IP: $($instance[1]), State: $($instance[2])"
    }
    
    return $instances
}
