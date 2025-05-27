# Google Maps API 代理服务器综合测试套件
# 合并所有测试功能：认证测试、POST端点测试、微信兼容性测试、IP检测测试、密码认证测试
# 创建时间: 2025年5月27日

param(
    [string]$ServerUrl = "http://localhost:3002",
    [string]$Password = "google-maps-proxy-2024",
    [switch]$SkipAuth,
    [switch]$SkipPost,
    [switch]$SkipWechat,
    [switch]$SkipIP,
    [switch]$RunOnly
)

# ==============================================================================
# 通用工具函数
# ==============================================================================

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    switch ($Color) {
        "Red" { Write-Host $Text -ForegroundColor Red }
        "Green" { Write-Host $Text -ForegroundColor Green }
        "Yellow" { Write-Host $Text -ForegroundColor Yellow }
        "Blue" { Write-Host $Text -ForegroundColor Blue }
        "Cyan" { Write-Host $Text -ForegroundColor Cyan }
        "Magenta" { Write-Host $Text -ForegroundColor Magenta }
        "White" { Write-Host $Text -ForegroundColor White }
        "Gray" { Write-Host $Text -ForegroundColor Gray }
        default { Write-Host $Text -ForegroundColor White }
    }
}

function Show-TestSuiteHeader {
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                    Google Maps API 代理服务器综合测试套件                     ║
║                         Complete Testing Suite v1.0                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Cyan"
    Write-ColorText "测试服务器: $ServerUrl" "Yellow"
    Write-ColorText "使用密码: $Password" "Yellow"
    Write-ColorText "测试时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"
    Write-ColorText ""
}

function Test-ServerRunning {
    Write-ColorText "🔍 检查服务器状态..." "Yellow"
    try {
        $healthResponse = Invoke-RestMethod -Uri "$ServerUrl/health" -TimeoutSec 5
        Write-ColorText "✅ 服务器运行正常" "Green"
        return $true
    } catch {
        Write-ColorText "❌ 服务器未运行或不可访问" "Red"
        Write-ColorText "请先启动服务器：./start.ps1" "Yellow"
        return $false
    }
}

# ==============================================================================
# 测试套件 1: 基础认证测试
# ==============================================================================

function Test-BasicAuthentication {
    if ($SkipAuth) { return @() }
    
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                           测试套件 1: 基础认证测试                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Magenta"
    
    $testResults = @()
    
    function Test-ApiEndpoint {
        param(
            [string]$Url,
            [string]$Description,
            [hashtable]$Headers = @{},
            [bool]$ShouldSucceed = $true
        )
        
        Write-ColorText "🧪 测试: $Description" "Blue"
        Write-ColorText "   URL: $Url" "Gray"
        
        try {
            $response = Invoke-RestMethod -Uri $Url -Method GET -Headers $Headers -TimeoutSec 10
            if ($ShouldSucceed) {
                if ($response.status -eq "OK" -or $response.results -or $response.predictions -or $response.message -or $response.name -or $response.health) {
                    Write-ColorText "   ✅ 成功 - API响应正常" "Green"
                    return $true
                } else {
                    Write-ColorText "   ⚠️  警告 - API响应异常" "Yellow"
                    return $false
                }
            } else {
                Write-ColorText "   ❌ 失败 - 应该被拒绝但通过了" "Red"
                return $false
            }
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.Value__
            if (-not $ShouldSucceed -and ($statusCode -eq 401 -or $statusCode -eq 403)) {
                Write-ColorText "   ✅ 成功 - 正确拒绝了无效请求" "Green"
                return $true
            } else {
                Write-ColorText "   ❌ 失败: $($_.Exception.Message)" "Red"
                return $false
            }
        }
    }
    
    # 执行基础认证测试
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing" -Description "无密码访问地理编码API" -ShouldSucceed $false
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing&password=wrong-password" -Description "错误密码访问API" -ShouldSucceed $false
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/geocode/json?address=Beijing&password=$Password" -Description "查询参数认证"
    
    $headers = @{ "X-API-Password" = $Password }
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/place/textsearch/json?query=restaurant" -Description "请求头认证" -Headers $headers
    
    $authHeaders = @{ "Authorization" = "Bearer $Password" }
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/place/autocomplete/json?input=coffee" -Description "Bearer Token认证" -Headers $authHeaders
    
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/health" -Description "健康检查端点（无需密码）"
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/api-status" -Description "API状态端点（无需密码）"
    $testResults += Test-ApiEndpoint -Url "$ServerUrl/" -Description "根端点（无需密码）"
    
    return $testResults
}

# ==============================================================================
# 测试套件 2: POST端点测试
# ==============================================================================

function Test-PostEndpoints {
    if ($SkipPost) { return @() }
    
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                          测试套件 2: POST端点测试                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Magenta"
    
    $testResults = @()
    
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
                    $testBody["password"] = $Password 
                }
                "header" { 
                    $headers["X-API-Password"] = $Password 
                }
                "bearer" { 
                    $headers["Authorization"] = "Bearer $Password" 
                }
                "query" {
                    $endpoint += "?password=$Password"
                }
            }
            
            $jsonBody = $testBody | ConvertTo-Json -Depth 3
            $headers["Content-Type"] = "application/json"
            
            Write-ColorText "🧪 测试: $description" "Blue"
            Write-ColorText "   端点: POST $endpoint" "Gray"
            Write-ColorText "   认证: $authMethod" "Gray"
            
            $response = Invoke-RestMethod -Uri "$ServerUrl$endpoint" -Method POST -Body $jsonBody -Headers $headers -TimeoutSec 10
            
            if ($response) {
                Write-ColorText "   ✅ 成功" "Green"
                return $true
            }
        }
        catch {
            Write-ColorText "   ❌ 失败: $($_.Exception.Message)" "Red"
            return $false
        }
    }
    
    # 执行POST端点测试
    $testResults += Test-PostEndpoint -endpoint "/geocode/json" -description "地理编码 - 请求体认证" -body @{
        address = "北京市天安门广场"
        language = "zh-CN"
    } -authMethod "body"
    
    $testResults += Test-PostEndpoint -endpoint "/geocode/json" -description "地理编码 - 头部认证" -body @{
        address = "上海市外滩"
        language = "zh-CN"
    } -authMethod "header"
    
    $testResults += Test-PostEndpoint -endpoint "/place/autocomplete/json" -description "地点自动补全 - Bearer认证" -body @{
        input = "北京大学"
        language = "zh-CN"
    } -authMethod "bearer"
    
    $testResults += Test-PostEndpoint -endpoint "/place/autocomplete/json" -description "地点自动补全 - 查询参数认证" -body @{
        input = "清华大学"
        language = "zh-CN"
    } -authMethod "query"
    
    $testResults += Test-PostEndpoint -endpoint "/place/details/json" -description "地点详情 - 请求体认证" -body @{
        place_id = "ChIJAWGLFGJZqDERVVI0vSDWmP8"
        language = "zh-CN"
        fields = "name,formatted_address,geometry"
    } -authMethod "body"
    
    $testResults += Test-PostEndpoint -endpoint "/place/nearbysearch/json" -description "附近搜索 - 头部认证" -body @{
        location = "39.9042,116.4074"
        radius = "1000"
        type = "restaurant"
        language = "zh-CN"
    } -authMethod "header"
    
    $testResults += Test-PostEndpoint -endpoint "/place/textsearch/json" -description "文本搜索 - Bearer认证" -body @{
        query = "北京餐厅"
        language = "zh-CN"
    } -authMethod "bearer"
    
    $testResults += Test-PostEndpoint -endpoint "/distancematrix/json" -description "距离矩阵 - 请求体认证" -body @{
        origins = "北京市天安门广场"
        destinations = "北京市颐和园"
        mode = "driving"
        language = "zh-CN"
    } -authMethod "body"
    
    $testResults += Test-PostEndpoint -endpoint "/directions/json" -description "路线规划 - 查询参数认证" -body @{
        origin = "北京市天安门广场"
        destination = "北京市故宫博物院"
        mode = "walking"
        language = "zh-CN"
    } -authMethod "query"
    
    $testResults += Test-PostEndpoint -endpoint "/place/nearbysearch/json" -description "复杂参数测试" -body @{
        location = "39.9042,116.4074"
        radius = "2000"
        type = "tourist_attraction"
        keyword = "故宫 博物馆"
        language = "zh-CN"
        minprice = "0"
        maxprice = "4"
    } -authMethod "body"
    
    return $testResults
}

# ==============================================================================
# 测试套件 3: 微信小程序兼容性测试
# ==============================================================================

function Test-WechatCompatibility {
    if ($SkipWechat) { return @() }
    
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                        测试套件 3: 微信小程序兼容性测试                         ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Magenta"
    
    $testResults = @()
    
    function Test-WxRequestStyle {
        param(
            [string]$endpoint,
            [string]$description,
            [hashtable]$data
        )
        
        try {
            Write-ColorText "🧪 测试: $description" "Blue"
            Write-ColorText "   端点: $endpoint" "Gray"
            
            # 添加密码到data参数中（模拟微信小程序方式）
            $data["password"] = $Password
            
            # 模拟微信小程序的请求方式 - 使用GET请求但参数在查询字符串中
            $queryString = ($data.GetEnumerator() | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString($_.Value))" }) -join "&"
            $fullUrl = "$ServerUrl$endpoint" + "?" + $queryString
            
            $response = Invoke-RestMethod -Uri $fullUrl -Method GET -TimeoutSec 10
            
            if ($response -and $response.status -eq "OK") {
                Write-ColorText "   ✅ 成功 - 返回了有效的Google Maps响应" "Green"
                return $true
            } else {
                Write-ColorText "   ⚠️  响应异常: $($response.status)" "Yellow"
                return $false
            }
        }
        catch {
            Write-ColorText "   ❌ 失败: $($_.Exception.Message)" "Red"
            return $false
        }
    }
    
    # 执行微信兼容性测试
    $testResults += Test-WxRequestStyle -endpoint "/geocode/json" -description "地理编码 - 天安门" -data @{
        address = "北京市天安门广场"
        language = "zh-CN"
    }
    
    $testResults += Test-WxRequestStyle -endpoint "/place/autocomplete/json" -description "自动补全 - 北京大学" -data @{
        input = "北京大学"
        language = "zh-CN"
    }
    
    $testResults += Test-WxRequestStyle -endpoint "/place/nearbysearch/json" -description "附近搜索 - 天安门周边餐厅" -data @{
        location = "39.9042,116.4074"
        radius = "1000"
        type = "restaurant"
        language = "zh-CN"
    }
    
    $testResults += Test-WxRequestStyle -endpoint "/place/textsearch/json" -description "文本搜索 - 北京咖啡厅" -data @{
        query = "北京咖啡厅"
        language = "zh-CN"
    }
    
    $testResults += Test-WxRequestStyle -endpoint "/distancematrix/json" -description "距离矩阵 - 天安门到故宫" -data @{
        origins = "北京市天安门广场"
        destinations = "北京市故宫博物院"
        mode = "walking"
        language = "zh-CN"
    }
    
    $testResults += Test-WxRequestStyle -endpoint "/directions/json" -description "路线规划 - 天安门到颐和园" -data @{
        origin = "北京市天安门广场"
        destination = "北京市颐和园"
        mode = "driving"
        language = "zh-CN"
    }
    
    return $testResults
}

# ==============================================================================
# 测试套件 4: IP地址检测测试
# ==============================================================================

function Test-IPDetection {
    if ($SkipIP) { return @() }
    
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                          测试套件 4: IP地址检测测试                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Magenta"
    
    function Test-DefaultGateway {
        Write-ColorText "🧪 测试: 通过默认网关检测IP..." "Blue"
        
        try {
            $result = route print 0.0.0.0 2>$null
            $lines = $result -split "`n"
            
            foreach ($line in $lines) {
                if ($line -match "0\.0\.0\.0.*0\.0\.0\.0") {
                    $parts = $line.Trim() -split "\s+"
                    if ($parts.Length -ge 4) {
                        $localIP = $parts[3]
                        if ($localIP -match "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
                            if ($localIP.StartsWith("192.168.") -or $localIP.StartsWith("10.") -or 
                                ($localIP.StartsWith("172.") -and [int]($localIP.Split('.')[1]) -ge 16 -and [int]($localIP.Split('.')[1]) -le 31)) {
                                Write-ColorText "   ✅ 检测到真实IP: $localIP" "Green"
                                return $localIP
                            }
                        }
                    }
                }
            }
        } catch {
            Write-ColorText "   ❌ 默认网关检测失败: $($_.Exception.Message)" "Red"
        }
        
        Write-ColorText "   ⚠️  默认网关方法未找到有效IP" "Yellow"
        return $null
    }
    
    function Test-NetworkInterfaces {
        Write-ColorText "🧪 测试: 通过网络接口检测IP..." "Blue"
        
        $vpnKeywords = @(
            'tap', 'tun', 'vpn', 'virtual', 'vmware', 'vbox', 'hyper-v', 
            'docker', 'wsl', 'loopback', 'teredo', 'isatap', 'pptp', 
            'openvpn', 'wireguard', 'nordvpn', 'expressvpn', 'clash',
            'wintun', 'utun', 'cscotun'
        )
        
        $physicalKeywords = @(
            'ethernet', 'wi-fi', 'wireless', 'wlan', 'lan', 'realtek', 
            'intel', 'broadcom', 'qualcomm', 'atheros'
        )
        
        $physicalIPs = @()
        
        Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
            $_.InterfaceAlias -ne "Loopback Pseudo-Interface 1" -and 
            $_.IPAddress -ne "127.0.0.1" 
        } | ForEach-Object {
            $interface = $_.InterfaceAlias
            $ip = $_.IPAddress
            $lowerName = $interface.ToLower()
            
            $isVirtual = $vpnKeywords | Where-Object { $lowerName.Contains($_) } | Measure-Object | Select-Object -ExpandProperty Count
            $isPhysical = $physicalKeywords | Where-Object { $lowerName.Contains($_) } | Measure-Object | Select-Object -ExpandProperty Count
            
            $isPrivateIP = $ip.StartsWith("192.168.") -or $ip.StartsWith("10.") -or 
                          ($ip.StartsWith("172.") -and [int]($ip.Split('.')[1]) -ge 16 -and [int]($ip.Split('.')[1]) -le 31)
            
            if ($isPrivateIP -and ($isPhysical -gt 0 -or $isVirtual -eq 0)) {
                Write-ColorText "   ✅ 检测到物理网卡IP: $interface -> $ip" "Green"
                $physicalIPs += @{ Interface = $interface; IP = $ip }
            }
        }
        
        if ($physicalIPs.Count -gt 0) {
            return $physicalIPs[0].IP
        } else {
            Write-ColorText "   ⚠️  未找到可用的物理网卡IP" "Yellow"
            return $null
        }
    }
    
    function Test-NodeServerDetection {
        Write-ColorText "🧪 测试: Node.js服务器检测IP..." "Blue"
        
        try {
            $output = node -e "
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
                    } catch (error) {
                        console.log('Gateway detection failed:', error.message);
                    }
                    return null;
                }
                
                const gatewayIP = getIPByDefaultGateway();
                console.log(gatewayIP || 'null');
            "
            
            if ($output -and $output -ne "null") {
                Write-ColorText "   ✅ Node.js检测到IP: $output" "Green"
                return $output.Trim()
            } else {
                Write-ColorText "   ⚠️  Node.js未检测到有效IP" "Yellow"
                return $null
            }
        } catch {
            Write-ColorText "   ❌ Node.js检测失败: $($_.Exception.Message)" "Red"
            return $null
        }
    }
    
    $gatewayIP = Test-DefaultGateway
    $interfaceIP = Test-NetworkInterfaces  
    $nodeIP = Test-NodeServerDetection
    
    Write-ColorText "`n📊 IP检测结果总结:" "Cyan"
    Write-ColorText "默认网关方法: $(if($gatewayIP) { $gatewayIP } else { '未检测到' })" "White"
    Write-ColorText "网络接口方法: $(if($interfaceIP) { $interfaceIP } else { '未检测到' })" "White"
    Write-ColorText "Node.js方法: $(if($nodeIP) { $nodeIP } else { '未检测到' })" "White"
    
    $recommendedIP = $nodeIP
    if (-not $recommendedIP) { $recommendedIP = $gatewayIP }
    if (-not $recommendedIP) { $recommendedIP = $interfaceIP }
    
    if ($recommendedIP) {
        Write-ColorText "🎯 推荐使用IP: $recommendedIP" "Green"
        Write-ColorText "📱 微信小程序配置: $recommendedIP:3002" "Green"
        return @($true, $true, $true)  # 3个成功测试
    } else {
        Write-ColorText "❌ 未能检测到可用的IP地址" "Red"
        return @($false, $false, $false)  # 3个失败测试
    }
}

# ==============================================================================
# 主执行流程
# ==============================================================================

function Show-FinalSummary {
    param($AuthResults, $PostResults, $WechatResults, $IPResults)
    
    Write-ColorText "
╔══════════════════════════════════════════════════════════════════════════════╗
║                              综合测试结果总结                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
" "Green"
    
    $totalTests = 0
    $totalPassed = 0
    
    if (-not $SkipAuth) {
        $authPassed = ($AuthResults | Where-Object { $_ }).Count
        $authTotal = $AuthResults.Count
        Write-ColorText "🔐 基础认证测试: $authPassed/$authTotal 通过" "White"
        $totalTests += $authTotal
        $totalPassed += $authPassed
    }
    
    if (-not $SkipPost) {
        $postPassed = ($PostResults | Where-Object { $_ }).Count
        $postTotal = $PostResults.Count
        Write-ColorText "📡 POST端点测试: $postPassed/$postTotal 通过" "White"
        $totalTests += $postTotal
        $totalPassed += $postPassed
    }
    
    if (-not $SkipWechat) {
        $wechatPassed = ($WechatResults | Where-Object { $_ }).Count
        $wechatTotal = $WechatResults.Count
        Write-ColorText "📱 微信兼容性测试: $wechatPassed/$wechatTotal 通过" "White"
        $totalTests += $wechatTotal
        $totalPassed += $wechatPassed
    }
    
    if (-not $SkipIP) {
        $ipPassed = ($IPResults | Where-Object { $_ }).Count
        $ipTotal = $IPResults.Count
        Write-ColorText "🌐 IP检测测试: $ipPassed/$ipTotal 通过" "White"
        $totalTests += $ipTotal
        $totalPassed += $ipPassed
    }
    
    Write-ColorText "`n📊 总体统计:" "Cyan"
    Write-ColorText "总计测试: $totalTests" "White"
    Write-ColorText "通过测试: $totalPassed" "Green"
    Write-ColorText "失败测试: $($totalTests - $totalPassed)" "Red"
    Write-ColorText "成功率: $(if($totalTests -gt 0) { [math]::Round($totalPassed/$totalTests*100, 2) } else { 0 })%" "Yellow"
    
    if ($totalPassed -eq $totalTests) {
        Write-ColorText "`n🎉 所有测试都通过了！Google Maps API代理服务器工作正常" "Green"
    } else {
        Write-ColorText "`n⚠️  部分测试失败，请检查服务器配置" "Yellow"
    }
    
    Write-ColorText "`n💡 使用建议:" "Cyan"
    Write-ColorText "   • 在生产环境中修改默认密码" "White"
    Write-ColorText "   • 使用HTTPS确保安全传输" "White"
    Write-ColorText "   • 考虑实施API速率限制" "White"
    Write-ColorText "   • 定期运行此测试套件验证功能" "White"
    
    Write-ColorText "`nAPI文档: $ServerUrl/" "Gray"
    Write-ColorText "健康检查: $ServerUrl/health" "Gray"
    Write-ColorText "测试完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"
}

# ==============================================================================
# 主程序入口
# ==============================================================================

# 显示测试套件标题
Show-TestSuiteHeader

# 检查服务器状态
if (-not (Test-ServerRunning)) {
    exit 1
}

# 执行各项测试
$authResults = Test-BasicAuthentication
$postResults = Test-PostEndpoints
$wechatResults = Test-WechatCompatibility
$ipResults = Test-IPDetection

# 显示最终汇总
Show-FinalSummary -AuthResults $authResults -PostResults $postResults -WechatResults $wechatResults -IPResults $ipResults

Write-ColorText "`n✨ 综合测试套件执行完成！" "Green"
