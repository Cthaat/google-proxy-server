#!/usr/bin/env pwsh
# Docker构建和测试脚本 - 使用Yarn版本

param(
    [ValidateSet("dev", "prod", "both")]
    [string]$Target = "dev",
    
    [switch]$NoBuild,
    [switch]$Test
)

function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Write-ColorText "`n🐳 Google Maps Proxy Server - Yarn Docker构建" "Green"
    Write-ColorText "================================================" "Green"
    Write-ColorText "目标环境: $Target" "Blue"
    Write-ColorText ""
}

function Build-DevImage {
    Write-ColorText "🔨 构建开发环境镜像 (使用Yarn)..." "Blue"
    
    docker build -t google-maps-proxy:dev-yarn `
        --build-arg NODE_ENV=development `
        -f Dockerfile .
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 开发环境镜像构建成功!" "Green"
    } else {
        Write-ColorText "❌ 开发环境镜像构建失败!" "Red"
        return $false
    }
    return $true
}

function Build-ProdImage {
    Write-ColorText "🔨 构建生产环境镜像 (使用Yarn)..." "Blue"
    
    docker build -t google-maps-proxy:prod-yarn `
        --build-arg NODE_ENV=production `
        -f Dockerfile.prod .
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 生产环境镜像构建成功!" "Green"
    } else {
        Write-ColorText "❌ 生产环境镜像构建失败!" "Red"
        return $false
    }
    return $true
}

function Test-Image {
    param($ImageName)
    
    Write-ColorText "🧪 测试镜像: $ImageName" "Yellow"
    
    # 启动容器进行测试
    $containerId = docker run -d -p 3002:3001 --name test-container $ImageName
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorText "❌ 容器启动失败" "Red"
        return $false
    }
    
    Start-Sleep 5
    
    try {
        # 测试健康检查端点
        $response = Invoke-WebRequest -Uri "http://localhost:3002/health" -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColorText "✅ 健康检查通过" "Green"
            $success = $true
        } else {
            Write-ColorText "❌ 健康检查失败: $($response.StatusCode)" "Red"
            $success = $false
        }
    } catch {
        Write-ColorText "❌ 健康检查失败: $($_.Exception.Message)" "Red"
        $success = $false
    } finally {
        # 清理测试容器
        docker stop test-container | Out-Null
        docker rm test-container | Out-Null
    }
    
    return $success
}

function Show-ImageInfo {
    Write-ColorText "`n📋 构建的镜像信息:" "Blue"
    docker images | Where-Object { $_ -like "*google-maps-proxy*yarn*" }
    
    Write-ColorText "`n🔍 镜像大小对比:" "Blue"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | Where-Object { $_ -like "*google-maps-proxy*" }
}

# 主执行流程
Show-Header

if (-not $NoBuild) {
    switch ($Target) {
        "dev" {
            $success = Build-DevImage
            if ($Test -and $success) {
                Test-Image "google-maps-proxy:dev-yarn"
            }
        }
        "prod" {
            $success = Build-ProdImage
            if ($Test -and $success) {
                Test-Image "google-maps-proxy:prod-yarn"
            }
        }
        "both" {
            $devSuccess = Build-DevImage
            $prodSuccess = Build-ProdImage
            
            if ($Test) {
                if ($devSuccess) { Test-Image "google-maps-proxy:dev-yarn" }
                if ($prodSuccess) { Test-Image "google-maps-proxy:prod-yarn" }
            }
        }
    }
}

Show-ImageInfo

Write-ColorText "`n🚀 使用方法:" "Yellow"
Write-ColorText "开发环境: docker run -p 3001:3001 google-maps-proxy:dev-yarn" "White"
Write-ColorText "生产环境: docker run -p 3001:3001 google-maps-proxy:prod-yarn" "White"
Write-ColorText "Compose启动: docker-compose up -d" "White"

Write-ColorText "`n✨ 完成!" "Green"
