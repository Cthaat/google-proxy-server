# 全面的POST端点测试脚本
# 测试所有API端点的POST请求和不同认证方法

$baseUrl = "http://localhost:3002"
$password = "google-maps-proxy-2024"
$testResults = @()

Write-Host "=== Google Maps Proxy POST端点全面测试 ===" -ForegroundColor Green
Write-Host "测试服务器: $baseUrl" -ForegroundColor Yellow
Write-Host "使用密码: $password" -ForegroundColor Yellow
Write-Host ""

# 测试函数
function Test-PostEndpoint {
    param(
        [string]$endpoint,
        [string]$description,
        [hashtable]$body,
        [string]$authMethod = "body",
        [hashtable]$headers = @{}
    )
    
    try {
        $testBody = $body.Clone()
        
        # 根据认证方法添加密码
        switch ($authMethod) {
            "body" { 
                $testBody["password"] = $password 
            }
            "header" { 
                $headers["X-API-Password"] = $password 
            }
            "bearer" { 
                $headers["Authorization"] = "Bearer $password" 
            }
            "query" {
                $endpoint += "?password=$password"
            }
        }
        
        $jsonBody = $testBody | ConvertTo-Json -Depth 3
        $headers["Content-Type"] = "application/json"
        
        Write-Host "测试: $description" -ForegroundColor Cyan
        Write-Host "端点: POST $endpoint" -ForegroundColor Gray
        Write-Host "认证方法: $authMethod" -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Uri "$baseUrl$endpoint" -Method POST -Body $jsonBody -Headers $headers -TimeoutSec 10
        
        if ($response) {
            Write-Host "✅ 成功" -ForegroundColor Green
            $script:testResults += @{
                Endpoint = $endpoint
                Method = "POST"
                Auth = $authMethod
                Status = "成功"
                Description = $description
            }
            return $true
        }
    }
    catch {
        Write-Host "❌ 失败: $($_.Exception.Message)" -ForegroundColor Red
        $script:testResults += @{
            Endpoint = $endpoint
            Method = "POST"
            Auth = $authMethod
            Status = "失败: $($_.Exception.Message)"
            Description = $description
        }
        return $false
    }
    finally {
        Write-Host ""
    }
}

# 1. 测试地理编码 API (Geocoding)
Write-Host "=== 1. 地理编码 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/geocode/json" -description "地理编码 - 请求体认证" -body @{
    address = "北京市天安门广场"
    language = "zh-CN"
} -authMethod "body"

Test-PostEndpoint -endpoint "/geocode/json" -description "地理编码 - 头部认证" -body @{
    address = "上海市外滩"
    language = "zh-CN"
} -authMethod "header"

# 2. 测试地点自动补全 API
Write-Host "=== 2. 地点自动补全 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/place/autocomplete/json" -description "地点自动补全 - Bearer认证" -body @{
    input = "北京大学"
    language = "zh-CN"
} -authMethod "bearer"

Test-PostEndpoint -endpoint "/place/autocomplete/json" -description "地点自动补全 - 查询参数认证" -body @{
    input = "清华大学"
    language = "zh-CN"
} -authMethod "query"

# 3. 测试地点详情 API
Write-Host "=== 3. 地点详情 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/place/details/json" -description "地点详情 - 请求体认证" -body @{
    place_id = "ChIJAWGLFGJZqDERVVI0vSDWmP8"
    language = "zh-CN"
    fields = "name,formatted_address,geometry"
} -authMethod "body"

# 4. 测试附近搜索 API
Write-Host "=== 4. 附近搜索 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/place/nearbysearch/json" -description "附近搜索 - 头部认证" -body @{
    location = "39.9042,116.4074"
    radius = "1000"
    type = "restaurant"
    language = "zh-CN"
} -authMethod "header"

# 5. 测试文本搜索 API
Write-Host "=== 5. 文本搜索 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/place/textsearch/json" -description "文本搜索 - Bearer认证" -body @{
    query = "北京餐厅"
    language = "zh-CN"
} -authMethod "bearer"

# 6. 测试距离矩阵 API
Write-Host "=== 6. 距离矩阵 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/distancematrix/json" -description "距离矩阵 - 请求体认证" -body @{
    origins = "北京市天安门广场"
    destinations = "北京市颐和园"
    mode = "driving"
    language = "zh-CN"
} -authMethod "body"

# 7. 测试路线规划 API
Write-Host "=== 7. 路线规划 API 测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/directions/json" -description "路线规划 - 查询参数认证" -body @{
    origin = "北京市天安门广场"
    destination = "北京市故宫博物院"
    mode = "walking"
    language = "zh-CN"
} -authMethod "query"

# 8. 测试复杂参数 POST 请求
Write-Host "=== 8. 复杂参数测试 ===" -ForegroundColor Magenta
Test-PostEndpoint -endpoint "/place/nearbysearch/json" -description "复杂参数 - 多个类型和关键词" -body @{
    location = "39.9042,116.4074"
    radius = "2000"
    type = "tourist_attraction"
    keyword = "故宫 博物馆"
    language = "zh-CN"
    minprice = "0"
    maxprice = "4"
} -authMethod "body"

# 测试结果总结
Write-Host "=== 测试结果总结 ===" -ForegroundColor Green
Write-Host "总计测试: $($testResults.Count)" -ForegroundColor Yellow
$successCount = ($testResults | Where-Object { $_.Status -eq "成功" }).Count
$failCount = $testResults.Count - $successCount
Write-Host "成功: $successCount" -ForegroundColor Green
Write-Host "失败: $failCount" -ForegroundColor Red
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "失败的测试:" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -ne "成功" } | ForEach-Object {
        Write-Host "  - $($_.Description) ($($_.Auth)): $($_.Status)" -ForegroundColor Red
    }
} else {
    Write-Host "🎉 所有POST端点测试都通过了！" -ForegroundColor Green
}

Write-Host ""
Write-Host "测试完成时间: $(Get-Date)" -ForegroundColor Gray
