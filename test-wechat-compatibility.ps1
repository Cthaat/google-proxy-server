# 微信小程序兼容性测试脚本
# 测试POST请求方式是否与微信小程序wx.request兼容

$baseUrl = "http://localhost:3002"
$password = "google-maps-proxy-2024"

Write-Host "=== 微信小程序兼容性测试 ===" -ForegroundColor Green
Write-Host "测试服务器: $baseUrl" -ForegroundColor Yellow
Write-Host ""

# 模拟微信小程序的wx.request请求方式
function Test-WxRequestStyle {
    param(
        [string]$endpoint,
        [string]$description,
        [hashtable]$data
    )
    
    try {
        Write-Host "测试: $description" -ForegroundColor Cyan
        Write-Host "端点: $endpoint" -ForegroundColor Gray
        
        # 添加密码到data参数中（模拟微信小程序方式）
        $data["password"] = $password
        
        # 模拟微信小程序的请求方式 - 使用GET请求但参数在查询字符串中
        $queryString = ($data.GetEnumerator() | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString($_.Value))" }) -join "&"
        $fullUrl = "$baseUrl$endpoint" + "?" + $queryString
        
        Write-Host "请求URL: $fullUrl" -ForegroundColor Gray
        
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -TimeoutSec 10
        
        if ($response -and $response.status -eq "OK") {
            Write-Host "✅ 成功 - 返回了有效的Google Maps响应" -ForegroundColor Green
            return $true
        } else {
            Write-Host "⚠️  响应异常: $($response.status)" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "❌ 失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Write-Host ""
    }
}

# 测试微信小程序常用的API调用场景

# 1. 地理编码 - 地址转坐标
Write-Host "=== 1. 地理编码测试（地址转坐标）===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/geocode/json" -description "地理编码 - 天安门" -data @{
    address = "北京市天安门广场"
    language = "zh-CN"
}

# 2. 地点自动补全 - 搜索建议
Write-Host "=== 2. 地点自动补全测试 ===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/place/autocomplete/json" -description "自动补全 - 北京大学" -data @{
    input = "北京大学"
    language = "zh-CN"
}

# 3. 附近搜索 - 周边POI
Write-Host "=== 3. 附近搜索测试 ===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/place/nearbysearch/json" -description "附近搜索 - 天安门周边餐厅" -data @{
    location = "39.9042,116.4074"
    radius = "1000"
    type = "restaurant"
    language = "zh-CN"
}

# 4. 文本搜索 - 关键词搜索
Write-Host "=== 4. 文本搜索测试 ===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/place/textsearch/json" -description "文本搜索 - 北京咖啡厅" -data @{
    query = "北京咖啡厅"
    language = "zh-CN"
}

# 5. 距离矩阵 - 距离计算
Write-Host "=== 5. 距离矩阵测试 ===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/distancematrix/json" -description "距离矩阵 - 天安门到故宫" -data @{
    origins = "北京市天安门广场"
    destinations = "北京市故宫博物院"
    mode = "walking"
    language = "zh-CN"
}

# 6. 路线规划 - 导航路线
Write-Host "=== 6. 路线规划测试 ===" -ForegroundColor Magenta
Test-WxRequestStyle -endpoint "/directions/json" -description "路线规划 - 天安门到颐和园" -data @{
    origin = "北京市天安门广场"
    destination = "北京市颐和园"
    mode = "driving"
    language = "zh-CN"
}

Write-Host "=== 微信小程序代码示例 ===" -ForegroundColor Green
Write-Host ""
Write-Host "基于以上测试，您的微信小程序可以使用以下代码：" -ForegroundColor Yellow
Write-Host ""

$exampleCode = @"
// utils/GoogleMapsApi.js - 更新版本
function GoogleMapsApi() {
  this.baseUrl = 'http://192.168.2.132:3002'; // 使用真实IP地址
  this.password = 'google-maps-proxy-2024';   // API密码
}

GoogleMapsApi.prototype.geocode = function(address) {
  return new Promise((resolve, reject) => {
    wx.request({
      url: this.baseUrl + '/geocode/json',
      data: {
        address: address,
        language: 'zh-CN',
        password: this.password  // 密码认证
      },
      method: 'GET', // 使用GET方法，参数自动加入查询字符串
      success: (res) => {
        if (res.data && res.data.status === 'OK') {
          resolve({
            success: true,
            data: {
              latitude: res.data.results[0].geometry.location.lat,
              longitude: res.data.results[0].geometry.location.lng,
              address: res.data.results[0].formatted_address
            }
          });
        } else {
          reject(new Error(res.data?.error_message || '地理编码失败'));
        }
      },
      fail: (error) => {
        reject(new Error('网络请求失败: ' + error.errMsg));
      }
    });
  });
};

GoogleMapsApi.prototype.autocomplete = function(input) {
  return new Promise((resolve, reject) => {
    wx.request({
      url: this.baseUrl + '/place/autocomplete/json',
      data: {
        input: input,
        language: 'zh-CN',
        password: this.password
      },
      method: 'GET',
      success: (res) => {
        if (res.data && res.data.status === 'OK') {
          resolve({
            success: true,
            data: res.data.predictions.map(prediction => ({
              description: prediction.description,
              place_id: prediction.place_id
            }))
          });
        } else {
          reject(new Error(res.data?.error_message || '自动补全失败'));
        }
      },
      fail: reject
    });
  });
};

// 导出实例
module.exports = new GoogleMapsApi();
"@

Write-Host $exampleCode -ForegroundColor Cyan
Write-Host ""
Write-Host "=== 重要提醒 ===" -ForegroundColor Red
Write-Host "1. 将baseUrl中的IP地址替换为您的实际服务器IP" -ForegroundColor Yellow
Write-Host "2. 确保微信开发者工具关闭了域名校验" -ForegroundColor Yellow
Write-Host "3. 在生产环境中使用HTTPS和自定义密码" -ForegroundColor Yellow
Write-Host ""
Write-Host "测试完成时间: $(Get-Date)" -ForegroundColor Gray
