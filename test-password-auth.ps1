# 密码认证功能测试脚本
# 测试Google Maps API代理服务器的密码认证功能

param(
    [string]$ServerUrl = "http://localhost:3002",
    [string]$Password = "google-maps-proxy-2024"
)

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    switch ($Color) {
        "Red" { Write-Host $Text -ForegroundColor Red }
        "Green" { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Blue" { Write-Host $Text -ForegroundColor Blue }
        "Cyan" { Write-Host $Text -ForegroundColor Cyan }
        "Magenta" { Write-Host $Text -ForegroundColor Magenta }
        default { Write-Host $Text -ForegroundColor White }
    }
}

function Test-ApiEndpoint {
    param(
        [string]$Url,
        [string]$Description,
        [hashtable]$Headers = @{},
        [bool]$ShouldSucceed = $true
    )
    
    Write-ColorText "🧪 测试: $Description" "Blue"
    Write-ColorText "   URL: $Url" "White"
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method GET -Headers $Headers -TimeoutSec 10
        
        if ($ShouldSucceed) {
            if ($response.status -eq "OK" -or $response.results -or $response.predictions) {
                Write-ColorText "   ✅ 测试通过 - API响应正常" "Green"
                return $true
            } else {
                Write-ColorText "   ⚠️  API响应异常: $($response.status)" "Yellow"
                return $false
            }
        } else {
            Write-ColorText "   ❌ 测试失败 - 应该被拒绝但通过了" "Red"
            return $false
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        if (-not $ShouldSucceed -and ($statusCode -eq 401 -or $statusCode -eq 403)) {
            Write-ColorText "   ✅ 测试通过 - 正确拒绝了无效请求" "Green"
            return $true
        } else {
            Write-ColorText "   ❌ 测试失败: $($_.Exception.Message)" "Red"
            return $false
        }
    }
}

Write-ColorText "🔐 Google Maps API代理服务器密码认证测试" "Cyan"
Write-ColorText "============================================" "Cyan"

# 检查服务器是否运行
Write-ColorText "`n🔍 检查服务器状态..." "Yellow"
try {
    $healthResponse = Invoke-RestMethod -Uri "$ServerUrl/health" -TimeoutSec 5
    Write-ColorText "✅ 服务器运行正常" "Green"
} catch {
    Write-ColorText "❌ 服务器未运行或不可访问" "Red"
    Write-ColorText "请先启动服务器：./start.ps1" "Yellow"
    exit 1
}

$testResults = @()

Write-ColorText "`n📋 开始密码认证测试..." "Yellow"

# 测试1: 无密码访问API（应该失败）
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=北京" -Description "无密码访问地理编码API" -ShouldSucceed $false

# 测试2: 错误密码访问API（应该失败）
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=北京&password=wrong-password" -Description "错误密码访问API" -ShouldSucceed $false

# 测试3: 查询参数方式提供正确密码（应该成功）
$testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=北京&password=$Password" -Description "查询参数方式提供密码"

# 测试4: 请求头方式提供密码（应该成功）
$headers = @{ "X-API-Password" = $Password }
$testResults += Test-ApiEndpoint -Url "$ServerUrl/place/textsearch/json?query=restaurant" -Description "请求头方式提供密码" -Headers $headers

# 测试5: Bearer Token方式提供密码（应该成功）
$authHeaders = @{ "Authorization" = "Bearer $Password" }
$testResults += Test-ApiEndpoint -Url "$ServerUrl/place/autocomplete/json?input=coffee" -Description "Bearer Token方式提供密码" -Headers $authHeaders

# 测试6: 访问公共端点（无需密码，应该成功）
$testResults += Test-ApiEndpoint -Url "$ServerUrl/health" -Description "访问健康检查端点（无需密码）"
$testResults += Test-ApiEndpoint -Url "$ServerUrl/api-status" -Description "访问API状态端点（无需密码）"
$testResults += Test-ApiEndpoint -Url "$ServerUrl/" -Description "访问根端点（无需密码）"

# 汇总测试结果
$successCount = ($testResults | Where-Object { $_ }).Count
$totalCount = $testResults.Count

Write-ColorText "`n📊 测试结果汇总" "Cyan"
Write-ColorText "============================================" "Cyan"
Write-ColorText "总计测试: $totalCount" "White"
Write-ColorText "通过测试: $successCount" "Green"
Write-ColorText "失败测试: $($totalCount - $successCount)" "Red"

if ($successCount -eq $totalCount) {
    Write-ColorText "`n🎉 所有测试通过！密码认证功能正常工作" "Green"
    
    Write-ColorText "`n💡 使用示例:" "Cyan"
    Write-ColorText "   查询参数: curl '$ServerUrl/geocode/json?address=北京&password=$Password'" "White"
    Write-ColorText "   请求头: curl -H 'X-API-Password: $Password' '$ServerUrl/geocode/json?address=北京'" "White"
    Write-ColorText "   Bearer Token: curl -H 'Authorization: Bearer $Password' '$ServerUrl/geocode/json?address=北京'" "White"
} else {
    Write-ColorText "`n❌ 部分测试失败，请检查服务器配置" "Red"
}

Write-ColorText "`n🔒 安全提醒:" "Yellow"
Write-ColorText "   • 生产环境请修改默认密码" "White"
Write-ColorText "   • 建议使用HTTPS传输密码" "White"
Write-ColorText "   • 考虑实施速率限制" "White"
