@echo off
echo ============================================
echo    Google Maps API 代理服务器启动脚本
echo ============================================
echo.

echo 检查Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未安装Node.js
    echo 请先安装Node.js: https://nodejs.org
    pause
    exit /b 1
)

echo ✅ Node.js环境正常

echo.
echo 检查项目依赖...
if not exist "node_modules" (
    echo 📦 首次运行，正在安装依赖...
    yarn install
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
) else (
    echo ✅ 依赖已安装
)

echo.
echo 🚀 启动Google Maps API代理服务器...
echo 📍 本地地址: http://localhost:3002
echo 💡 使用Ctrl+C停止服务器
echo.
echo ============================================
echo.

yarn start
