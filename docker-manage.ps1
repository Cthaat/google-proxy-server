#!/usr/bin/env pwsh
# Docker管理脚本

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean", "build", "health")]
    [string]$Action,
    
    [ValidateSet("dev", "prod")]
    [string]$Environment = "dev"
)

$ComposeFile = if ($Environment -eq "prod") { "docker-compose.prod.yml" } else { "docker-compose.yml" }

function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Write-ColorText "`n🐳 Google Maps API代理服务器 - Docker管理" "Green"
    Write-ColorText "============================================" "Green"
    Write-ColorText "环境: $Environment | 配置文件: $ComposeFile" "Blue"
    Write-ColorText ""
}

function Test-DockerAvailable {
    try {
        docker --version | Out-Null
        docker-compose --version | Out-Null
        return $true
    } catch {
        Write-ColorText "❌ Docker或Docker Compose不可用" "Red"
        return $false
    }
}

function Start-Service {
    Write-ColorText "🚀 启动服务..." "Blue"
    
    if (-not (Test-Path $ComposeFile)) {
        Write-ColorText "❌ 找不到配置文件: $ComposeFile" "Red"
        return
    }
    
    # 检查.env文件
    if (-not (Test-Path ".env")) {
        Write-ColorText "⚠️  创建.env文件..." "Yellow"
        Copy-Item ".env.example" ".env" -ErrorAction SilentlyContinue
        Write-ColorText "请编辑.env文件设置API密钥" "Yellow"
    }
    
    docker-compose -f $ComposeFile up -d
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 服务启动成功" "Green"
        Start-Sleep -Seconds 5
        Test-ServiceHealth
    } else {
        Write-ColorText "❌ 服务启动失败" "Red"
    }
}

function Stop-Service {
    Write-ColorText "🛑 停止服务..." "Blue"
    docker-compose -f $ComposeFile down
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 服务已停止" "Green"
    } else {
        Write-ColorText "❌ 停止服务失败" "Red"
    }
}

function Restart-Service {
    Write-ColorText "🔄 重启服务..." "Blue"
    docker-compose -f $ComposeFile restart
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 服务重启成功" "Green"
        Start-Sleep -Seconds 5
        Test-ServiceHealth
    } else {
        Write-ColorText "❌ 重启服务失败" "Red"
    }
}

function Show-Logs {
    Write-ColorText "📋 查看日志..." "Blue"
    docker-compose -f $ComposeFile logs -f --tail=100
}

function Show-Status {
    Write-ColorText "📊 服务状态..." "Blue"
    docker-compose -f $ComposeFile ps
    
    Write-ColorText "`n📈 系统资源使用:" "Blue"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

function Clean-Environment {
    Write-ColorText "🧹 清理Docker环境..." "Blue"
    
    $answer = Read-Host "确定要清理所有相关Docker资源吗? (y/N)"
    if ($answer -eq "y" -or $answer -eq "Y") {
        # 停止并删除容器
        docker-compose -f $ComposeFile down -v --remove-orphans
        
        # 删除镜像
        $images = docker images --filter "reference=*google*proxy*" -q
        if ($images) {
            docker rmi $images -f
        }
        
        # 清理未使用的资源
        docker system prune -f
        
        Write-ColorText "✅ 清理完成" "Green"
    } else {
        Write-ColorText "取消清理" "Yellow"
    }
}

function Build-Image {
    Write-ColorText "🔨 构建镜像..." "Blue"
    docker-compose -f $ComposeFile build --no-cache
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ 镜像构建成功" "Green"
    } else {
        Write-ColorText "❌ 镜像构建失败" "Red"
    }
}

function Test-ServiceHealth {
    Write-ColorText "🔍 检查服务健康状态..." "Blue"
    
    $maxAttempts = 10
    $attempt = 0
    
    do {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:3001/health" -TimeoutSec 5
            if ($response.status -eq "OK") {
                Write-ColorText "✅ 服务健康检查通过" "Green"
                Write-ColorText "   状态: $($response.status)" "White"
                Write-ColorText "   消息: $($response.message)" "White"
                Write-ColorText "   版本: $($response.version)" "White"
                return
            }
        } catch {
            $attempt++
            if ($attempt -lt $maxAttempts) {
                Write-ColorText "⏳ 等待服务就绪... ($attempt/$maxAttempts)" "Yellow"
                Start-Sleep -Seconds 3
            }
        }
    } while ($attempt -lt $maxAttempts)
    
    Write-ColorText "❌ 服务健康检查失败" "Red"
    Write-ColorText "请检查日志: .\docker-manage.ps1 -Action logs" "Yellow"
}

# 主程序
Show-Header

if (-not (Test-DockerAvailable)) {
    exit 1
}

switch ($Action) {
    "start" { Start-Service }
    "stop" { Stop-Service }
    "restart" { Restart-Service }
    "logs" { Show-Logs }
    "status" { Show-Status }
    "clean" { Clean-Environment }
    "build" { Build-Image }
    "health" { Test-ServiceHealth }
}

Write-ColorText "`n📚 可用命令:" "Blue"
Write-ColorText "  .\docker-manage.ps1 -Action start [-Environment dev|prod]" "White"
Write-ColorText "  .\docker-manage.ps1 -Action stop" "White"
Write-ColorText "  .\docker-manage.ps1 -Action restart" "White"
Write-ColorText "  .\docker-manage.ps1 -Action logs" "White"
Write-ColorText "  .\docker-manage.ps1 -Action status" "White"
Write-ColorText "  .\docker-manage.ps1 -Action build" "White"
Write-ColorText "  .\docker-manage.ps1 -Action health" "White"
Write-ColorText "  .\docker-manage.ps1 -Action clean" "White"
