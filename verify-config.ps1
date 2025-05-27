#!/usr/bin/env pwsh
# 完整的端口和yarn配置验证脚本

param(
    [switch]$Docker,
    [switch]$Local
)

function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Write-ColorText "`n🔧 Google Maps Proxy - 配置验证" "Green"
    Write-ColorText "======================================" "Green"
    Write-ColorText "端口: 3002 | 包管理器: Yarn" "Blue"
    Write-ColorText ""
}

function Test-YarnInstallation {
    Write-ColorText "📦 检查Yarn安装..." "Yellow"
    
    try {
        $yarnVersion = yarn --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColorText "✅ Yarn已安装 - 版本: $yarnVersion" "Green"
            return $true
        }
    } catch {
        Write-ColorText "❌ Yarn未安装" "Red"
        Write-ColorText "正在安装Yarn..." "Yellow"
        npm install -g yarn
        return $LASTEXITCODE -eq 0
    }
}

function Test-Dependencies {
    Write-ColorText "`n📋 检查项目依赖..." "Yellow"
    
    if (-not (Test-Path "yarn.lock")) {
        Write-ColorText "⚠️  yarn.lock不存在，正在生成..." "Yellow"
        yarn install
    }
    
    if (-not (Test-Path "node_modules")) {
        Write-ColorText "📦 安装依赖..." "Blue"
        yarn install
    }
    
    Write-ColorText "✅ 依赖检查完成" "Green"
}

function Test-LocalServer {
    Write-ColorText "`n🧪 测试本地服务器..." "Yellow"
    
    # 启动服务器
    $serverProcess = Start-Process -FilePath "node" -ArgumentList "server.js" -PassThru -WindowStyle Hidden
    
    Start-Sleep 3
    
    try {
        # 测试健康检查
        $response = Invoke-WebRequest -Uri "http://localhost:3002/health" -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-ColorText "✅ 本地服务器启动成功" "Green"
            Write-ColorText "📍 地址: http://localhost:3002" "White"
            
            # 检查是否正确检测到真实IP
            Write-ColorText "🔍 检查IP检测功能..." "Blue"
            $serverOutput = node -e "
                const os = require('os');
                const { execSync } = require('child_process');
                
                function getIPByDefaultGateway() {
                    try {
                        const result = execSync('route print 0.0.0.0', { encoding: 'utf8', timeout: 5000 });
                        const lines = result.split('\n');
                        
                        for (const line of lines) {
                            if (line.includes('0.0.0.0') && line.includes('0.0.0.0')) {
                                const parts = line.trim().split(/\s+/);
                                if (parts.length >= 4) {
                                    const localIP = parts[3];
                                    if (localIP && localIP.match(/^(\d{1,3}\.){3}\d{1,3}$/)) {
                                        if (localIP.startsWith('192.168.') || localIP.startsWith('10.') || 
                                            (localIP.startsWith('172.') && parseInt(localIP.split('.')[1]) >= 16 && parseInt(localIP.split('.')[1]) <= 31)) {
                                            return localIP;
                                        }
                                    }
                                }
                            }
                        }
                    } catch (error) {}
                    return null;
                }
                
                const realIP = getIPByDefaultGateway();
                console.log(realIP || 'localhost');
            "
            
            if ($serverOutput -and $serverOutput -ne "localhost") {
                Write-ColorText "✅ IP检测功能正常，检测到真实IP: $serverOutput" "Green"
                Write-ColorText "🌐 局域网地址: http://$serverOutput`:3002" "White"
            } else {
                Write-ColorText "⚠️  IP检测功能使用localhost" "Yellow"
            }
            
            # 获取健康检查响应
            $content = $response.Content | ConvertFrom-Json
            Write-ColorText "🌐 健康检查响应正常" "Green"
        }
    } catch {
        Write-ColorText "❌ 本地服务器测试失败: $($_.Exception.Message)" "Red"
    } finally {
        # 停止服务器
        if ($serverProcess -and !$serverProcess.HasExited) {
            Stop-Process -Id $serverProcess.Id -Force
        }
    }
}

function Test-DockerConfiguration {
    Write-ColorText "`n🐳 测试Docker配置..." "Yellow"
    
    # 检查Docker可用性
    try {
        docker --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorText "❌ Docker不可用" "Red"
            return
        }
    } catch {
        Write-ColorText "❌ Docker不可用" "Red"
        return
    }
    
    # 构建测试镜像
    Write-ColorText "🔨 构建测试镜像..." "Blue"
    docker build -t google-proxy-test:latest . 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorText "✅ Docker镜像构建成功" "Green"
        
        # 测试容器运行
        Write-ColorText "🏃 测试容器运行..." "Blue"
        $containerId = docker run -d -p 3003:3002 --name test-proxy google-proxy-test:latest
        
        Start-Sleep 5
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3003/health" -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-ColorText "✅ Docker容器运行成功" "Green"
                Write-ColorText "📍 测试地址: http://localhost:3003" "White"
            }
        } catch {
            Write-ColorText "❌ Docker容器测试失败" "Red"
        } finally {
            # 清理测试容器
            docker stop test-proxy 2>$null | Out-Null
            docker rm test-proxy 2>$null | Out-Null
        }
    } else {
        Write-ColorText "❌ Docker镜像构建失败" "Red"
    }
}

function Show-Summary {
    Write-ColorText "`n📋 配置摘要:" "Cyan"
    Write-ColorText "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "Cyan"
    Write-ColorText "🔗 本地地址: http://localhost:3002" "White"
    Write-ColorText "🔍 健康检查: http://localhost:3002/health" "White"
    Write-ColorText "📊 API状态: http://localhost:3002/api-status" "White"
    Write-ColorText "📋 API列表: http://localhost:3002/" "White"
    Write-ColorText ""
    Write-ColorText "🚀 启动命令:" "Yellow"
    Write-ColorText "   本地运行: yarn start" "White"
    Write-ColorText "   Docker运行: docker-compose up -d" "White"
    Write-ColorText "   Docker构建: yarn run docker:build" "White"
    Write-ColorText ""
    Write-ColorText "📱 微信小程序配置:" "Yellow"
    Write-ColorText "   将局域网IP和端口3002配置到小程序中" "White"
}

# 主执行流程
Show-Header

# 检查Yarn
if (-not (Test-YarnInstallation)) {
    Write-ColorText "❌ Yarn安装失败，退出" "Red"
    exit 1
}

# 检查依赖
Test-Dependencies

# 根据参数运行测试
if ($Local -or (-not $Docker -and -not $Local)) {
    Test-LocalServer
}

if ($Docker -or (-not $Docker -and -not $Local)) {
    Test-DockerConfiguration
}

Show-Summary

Write-ColorText "`n✨ 验证完成!" "Green"
