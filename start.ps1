# Google Maps API 代理服务器启动脚本 (PowerShell)
# 作者: 高级中国全栈工程师

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "    Google Maps API 代理服务器启动脚本" -ForegroundColor Cyan  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 检查Node.js环境
Write-Host "检查Node.js环境..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Node.js环境正常 - 版本: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js未安装"
    }
} catch {
    Write-Host "❌ 错误: 未安装Node.js" -ForegroundColor Red
    Write-Host "请先安装Node.js: https://nodejs.org" -ForegroundColor Yellow
    Read-Host "按任意键退出"
    exit 1
}

Write-Host ""

# 检查项目依赖
Write-Host "检查项目依赖..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 首次运行，正在安装依赖..." -ForegroundColor Blue
    yarn install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 依赖安装失败" -ForegroundColor Red
        Read-Host "按任意键退出"
        exit 1
    }
    Write-Host "✅ 依赖安装完成" -ForegroundColor Green
} else {
    Write-Host "✅ 依赖已安装" -ForegroundColor Green
}

Write-Host ""

# 显示配置信息
Write-Host "📋 服务器配置:" -ForegroundColor Cyan
Write-Host "   🔗 本地地址: http://localhost:3002" -ForegroundColor White
Write-Host "   🔍 健康检查: http://localhost:3002/health" -ForegroundColor White
Write-Host "   📊 API状态: http://localhost:3002/api-status" -ForegroundColor White
Write-Host "   📋 API列表: http://localhost:3002/" -ForegroundColor White

Write-Host ""
Write-Host "💡 使用提示:" -ForegroundColor Cyan
Write-Host "   • 使用 Ctrl+C 停止服务器" -ForegroundColor White
Write-Host "   • 服务器启动后可在微信小程序中使用" -ForegroundColor White
Write-Host "   • 确保防火墙允许端口 3001" -ForegroundColor White

Write-Host ""
Write-Host "🚀 启动Google Maps API代理服务器..." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 启动服务器
try {
    npm start
} catch {
    Write-Host ""
    Write-Host "❌ 服务器启动失败" -ForegroundColor Red
    Write-Host "请检查端口3001是否被占用" -ForegroundColor Yellow
    Read-Host "按任意键退出"
    exit 1
}
