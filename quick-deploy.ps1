#!/usr/bin/env pwsh
# 快速部署脚本

Write-Host "🚀 Google Maps API代理服务器 - 快速部署" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

# 检查必要文件
$requiredFiles = @("docker-compose.yml", "Dockerfile", ".env.example")
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "❌ 缺少必要文件: $file" -ForegroundColor Red
        exit 1
    }
}

# 环境选择
Write-Host "`n📋 请选择部署环境:" -ForegroundColor Blue
Write-Host "1. 开发环境 (推荐新手)" -ForegroundColor White
Write-Host "2. 生产环境 (包含Nginx)" -ForegroundColor White
$envChoice = Read-Host "请输入选择 (1-2)"

$environment = switch ($envChoice) {
    "1" { "dev" }
    "2" { "prod" }
    default { "dev" }
}

Write-Host "选择的环境: $environment" -ForegroundColor Green

# 配置API密钥
if (-not (Test-Path ".env")) {
    Write-Host "`n🔑 配置API密钥..." -ForegroundColor Blue
    Copy-Item ".env.example" ".env"
    
    $apiKey = Read-Host "请输入您的Google Maps API密钥"
    if ($apiKey) {
        (Get-Content ".env") -replace "your_google_maps_api_key_here", $apiKey | Set-Content ".env"
        Write-Host "✅ API密钥已设置" -ForegroundColor Green
    } else {
        Write-Host "⚠️  您可以稍后编辑.env文件设置API密钥" -ForegroundColor Yellow
    }
}

# 启动服务
Write-Host "`n🚀 启动服务..." -ForegroundColor Blue
& .\docker-manage.ps1 -Action build -Environment $environment
& .\docker-manage.ps1 -Action start -Environment $environment

Write-Host "`n🎉 部署完成!" -ForegroundColor Green
Write-Host "访问地址:" -ForegroundColor Blue
if ($environment -eq "prod") {
    Write-Host "  HTTP: http://localhost" -ForegroundColor White
    Write-Host "  HTTPS: https://localhost (需要SSL证书)" -ForegroundColor White
} else {
    Write-Host "  服务: http://localhost:3002" -ForegroundColor White
}
Write-Host "  健康检查: http://localhost:3002/health" -ForegroundColor White
