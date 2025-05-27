# Google Maps API本地代理服务器 - 完整使用指南

> 🚀 **最新更新 (2025年5月27日)**
> - ✅ **端口升级**: 从3001升级到3002端口
> - ✅ **包管理器切换**: 从npm切换到yarn，提升依赖管理效率
> - ✅ **智能IP检测**: 自动检测真实本地IP地址，排除VPN虚拟网络
> - ✅ **密码认证**: 完整的API密码保护机制，支持4种认证方式
> - ✅ **POST路由支持**: 所有API端点现已支持POST请求方式
> - ✅ **微信小程序兼容**: 完全兼容微信小程序wx.request调用方式
> - ✅ **全面测试**: 包含密码认证、POST端点、微信兼容性等完整测试套件

## 📋 目录
- [快速开始](#快速开始)
- [Docker部署](#docker部署)
- [详细配置](#详细配置)
- [微信小程序配置](#微信小程序配置)
- [故障排除](#故障排除)
- [API使用示例](#api使用示例)
- [生产部署](#生产部署)

## 🚀 快速开始

### 1. 安装依赖

```powershell
# 进入代理服务器目录
cd google-proxy-server

# 安装Node.js依赖
npm install
```

### 2. 配置API密钥

编辑 `server.js` 文件第16行，替换为您的Google Maps API密钥：

```javascript
const API_KEY = 'YOUR_ACTUAL_GOOGLE_MAPS_API_KEY';
```

### 3. 启动服务器

**方法一：使用启动脚本（推荐）**
```powershell
# Windows PowerShell
.\start.ps1

# 或者使用批处理文件
.\start.bat
```

**方法二：直接启动**
```powershell
npm start
```

### 4. 验证服务器

打开浏览器访问：http://localhost:3002/health

看到以下响应表示成功：
```json
{
  "status": "OK",
  "message": "Google Maps API代理服务器运行正常",
  "timestamp": "2025-05-27T...",
  "version": "1.0.0"
}
```

## 🔐 密码认证配置

### 安全说明

为了保护API免受未授权访问，本代理服务器现已实现密码认证功能。所有API端点（除健康检查等公共端点外）都需要提供正确的密码才能访问。

### 密码配置

**默认密码**: `google-maps-proxy-2024`

**通过环境变量自定义密码**:
```powershell
# 设置自定义密码
$env:API_PASSWORD = "your-custom-password"

# 启动服务器
./start.ps1
```

**Docker环境变量设置**:
```yaml
# docker-compose.yml
environment:
  - API_PASSWORD=your-custom-password
```

### 密码使用方式

支持以下四种方式提供密码：

#### 1. 查询参数方式
```bash
curl "http://localhost:3002/geocode/json?address=北京&password=google-maps-proxy-2024"
```

#### 2. 请求头方式
```bash
curl -H "X-API-Password: google-maps-proxy-2024" \
     "http://localhost:3002/geocode/json?address=北京"
```

#### 3. Bearer Token方式
```bash
curl -H "Authorization: Bearer google-maps-proxy-2024" \
     "http://localhost:3002/geocode/json?address=北京"
```

#### 4. 请求体方式（POST请求）
```bash
curl -X POST "http://localhost:3002/geocode/json" \
     -H "Content-Type: application/json" \
     -d '{"address": "北京", "password": "google-maps-proxy-2024"}'
```

### 微信小程序中的密码使用

更新您的API调用代码：

```javascript
// utils/GoogleMapsApi.js
function GoogleMapsApi() {
  this.baseUrl = 'http://192.168.1.100:3002'; // 您的服务器IP
  this.password = 'google-maps-proxy-2024';   // API密码
}

GoogleMapsApi.prototype.geocode = function(address) {
  return new Promise((resolve, reject) => {
    wx.request({
      url: `${this.baseUrl}/geocode/json`,
      data: {
        address: address,
        language: 'zh-CN',
        password: this.password  // 添加密码参数
      },
      success: (res) => {
        if (res.data.status === 'OK') {
          resolve({
            success: true,
            data: {
              latitude: res.data.results[0].geometry.location.lat,
              longitude: res.data.results[0].geometry.location.lng
            }
          });
        } else {
          reject(new Error(res.data.error_message || '地理编码失败'));
        }
      },
      fail: reject
    });
  });
};
```

### 密码认证测试

运行密码认证测试脚本：
```powershell
# 测试密码认证功能
./test-password-auth.ps1

# 使用自定义密码测试
./test-password-auth.ps1 -Password "your-custom-password"

# 测试不同服务器地址
./test-password-auth.ps1 -ServerUrl "http://192.168.1.100:3002"
```

### 无需密码的公共端点

以下端点无需密码即可访问：
- `GET /health` - 健康检查
- `GET /api-status` - API状态检查  
- `GET /` - API文档和端点列表

### 安全建议

🔒 **生产环境安全提醒**：
- 修改默认密码为复杂密码
- 使用HTTPS传输密码
- 定期更换密码
- 考虑实施IP白名单
- 监控异常访问尝试

## 🐳 Docker部署

### 快速开始（推荐）

**使用快速部署脚本：**
```powershell
.\quick-deploy.ps1
```

脚本会自动：
- 检查Docker环境
- 创建环境配置文件
- 构建Docker镜像
- 启动服务容器
- 进行健康检查

### 手动Docker部署

#### 1. 环境准备

确保已安装：
- Docker Desktop for Windows
- Docker Compose

#### 2. 配置环境变量

```powershell
# 复制环境变量模板
Copy-Item .env.example .env

# 编辑.env文件，设置您的API密钥
notepad .env
```

#### 3. 构建和启动

**开发环境：**
```powershell
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

**生产环境：**
```powershell
# 使用生产配置
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

#### 4. 使用管理脚本

我们提供了功能完整的管理脚本：

```powershell
# 启动服务
.\docker-manage.ps1 -Action start -Environment dev

# 查看状态
.\docker-manage.ps1 -Action status

# 查看日志
.\docker-manage.ps1 -Action logs

# 健康检查
.\docker-manage.ps1 -Action health

# 停止服务
.\docker-manage.ps1 -Action stop

# 清理环境
.\docker-manage.ps1 -Action clean
```

### Docker配置说明

#### 开发环境特性
- 基于Node.js 18 Alpine
- 自动重启
- 日志持久化
- 健康检查
- 资源限制

#### 生产环境特性
- 多阶段构建优化
- Nginx反向代理
- SSL/TLS支持
- 速率限制
- 安全加固
- 监控就绪

### Docker故障排除

#### 常见问题

**Q1: 容器启动失败**
```powershell
# 查看容器状态
docker-compose ps

# 查看详细日志
docker-compose logs google-proxy

# 检查资源使用
docker stats
```

**Q2: 端口冲突**
```powershell
# 查看端口占用
netstat -ano | findstr :3002

# 修改docker-compose.yml中的端口映射
ports:
  - "3003:3002"  # 改为其他端口
```

**Q3: 网络连接问题**
```powershell
# 测试容器网络
docker exec -it google-maps-proxy wget -qO- http://localhost:3002/health

# 检查防火墙设置
```

## ⚙️ 详细配置

### 服务器配置

编辑 `config.json` 文件来自定义配置：

```json
{
  "server": {
    "port": 3002,           // 服务器端口
    "timeout": 10000        // 请求超时时间(毫秒)
  },
  "google": {
    "baseUrl": "https://maps.googleapis.com/maps/api",
    "apiKey": "YOUR_API_KEY"  // 您的API密钥
  },
  "logging": {
    "enabled": true,        // 是否启用日志
    "logRequests": true,    // 记录请求日志
    "logResponses": true    // 记录响应日志
  }
}
```

### 环境变量配置（可选）

您也可以通过环境变量设置API密钥：

```powershell
# 设置环境变量
$env:GOOGLE_MAPS_API_KEY = "YOUR_API_KEY"

# 启动服务器
npm start
```

## 📱 微信小程序配置

### 1. 更新API基础URL

您的 `GoogleMapsApi.js` 已经配置为使用本地代理：

```javascript
function GoogleMapsApi(apiKey) {
  this.apiKey = apiKey || ''; // 代理服务器会自动添加API密钥
  this.baseUrl = 'http://localhost:3002'; // 使用本地代理服务器
  this.initialized = true;
}
```

### 2. 微信开发者工具设置

在微信开发者工具中：

1. 点击右上角 "详情"
2. 找到 "本地设置"
3. 勾选 "不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"

### 3. project.config.json配置

确保项目配置文件包含：

```json
{
  "setting": {
    "urlCheck": false,
    "es6": true,
    "enhance": true,
    "postcss": true,
    "minified": true
  }
}
```

## 🔧 故障排除

### 常见问题

#### Q1: 服务器启动失败
```
错误: listen EADDRINUSE :::3002
```

**解决方案：**
```powershell
# 查看占用端口3002的进程
netstat -ano | findstr :3002

# 终止占用进程（替换PID）
taskkill /PID <进程ID> /F

# 或者修改server.js中的端口号
const PORT = 3002; // 改为其他端口
```

#### Q2: API请求失败
```
❌ Google API请求失败: REQUEST_TIMEOUT
```

**解决方案：**
1. 检查网络连接
2. 验证API密钥是否有效
3. 检查API配额是否充足
4. 尝试增加超时时间

#### Q3: 微信小程序无法访问
```
网络请求失败
```

**解决方案：**
1. 确保代理服务器正在运行
2. 检查微信开发者工具的域名校验设置
3. 确认小程序中的baseUrl配置正确
4. 检查防火墙设置

#### Q4: CORS错误
```
Access-Control-Allow-Origin错误
```

**解决方案：**
服务器已配置允许所有来源，如果仍有问题：

```javascript
// 在server.js中更新CORS设置
app.use(cors({
  origin: ['http://localhost:3000', 'https://servicewechat.com'],
  credentials: true
}));
```

### 调试技巧

#### 检查服务状态
```powershell
# 访问健康检查端点
curl http://localhost:3002/health

# 查看服务器日志
docker-compose logs -f
```

## 📚 API使用示例

### 在微信小程序中使用

```javascript
// pages/example/example.js
const googleMapsApi = require('../../utils/GoogleMapsApi');

Page({
  data: {
    searchResults: []
  },

  async onLoad() {
    // 测试地理编码
    try {
      const result = await googleMapsApi.geocode('北京天安门');
      if (result.success) {
        console.log('坐标:', result.data.latitude, result.data.longitude);
        this.setData({
          latitude: result.data.latitude,
          longitude: result.data.longitude
        });
      }
    } catch (error) {
      console.error('地理编码失败:', error);
      wx.showToast({
        title: '地址搜索失败',
        icon: 'none'
      });
    }
  },

  async searchAddress(address) {
    wx.showLoading({ title: '搜索中...' });
    
    try {
      const result = await googleMapsApi.autocomplete(address);
      if (result.success) {
        this.setData({
          searchResults: result.data
        });
      }
    } catch (error) {
      wx.showToast({
        title: '搜索失败',
        icon: 'none'
      });
    } finally {
      wx.hideLoading();
    }
  }
});
```

### Node.js中使用

```javascript
const axios = require('axios');

async function callGoogleMapsProxy() {
  try {
    const response = await axios.get('http://localhost:3002/geocode/json', {
      params: {
        address: '北京天安门',
        language: 'zh-CN'
      }
    });
    
    console.log('地理编码结果:', response.data);
  } catch (error) {
    console.error('请求失败:', error.message);
  }
}

callGoogleMapsProxy();
```

## 🚀 生产部署

### 安全考虑

⚠️ **重要警告**：此代理服务器仅用于开发和测试环境。

生产环境建议：

1. **使用HTTPS**
2. **限制CORS来源**
3. **添加身份验证**
4. **使用环境变量管理密钥**
5. **添加速率限制**
6. **使用负载均衡**

### 云服务器部署示例

```dockerfile
# Dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3002
CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  google-proxy:
    build: .
    ports:
      - "3002:3002"
    environment:
      - GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
      - NODE_ENV=production
    restart: unless-stopped
```

### 环境变量管理

创建 `.env` 文件：

```env
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
PORT=3002
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000
```

更新 `server.js` 使用环境变量：

```javascript
require('dotenv').config();

const API_KEY = process.env.GOOGLE_MAPS_API_KEY || 'your_default_key';
const PORT = process.env.PORT || 3002;
```

## 📊 监控和维护

### 健康检查

设置定时健康检查：

```javascript
// health-check.js
const axios = require('axios');

setInterval(async () => {
  try {
    await axios.get('http://localhost:3002/health');
    console.log('✅ 服务器健康');
  } catch (error) {
    console.error('❌ 服务器异常:', error.message);
    // 发送报警通知
  }
}, 60000); // 每分钟检查一次
```

### 日志管理

使用 `winston` 进行日志管理：

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console()
  ]
});
```

## 🆘 获取帮助

如果遇到问题：

1. **查看服务器日志** - 检查控制台输出
2. **检查健康状态** - 访问 `/health`
3. **查看文档** - 本README文件
4. **检查网络** - 确保能访问Google服务
5. **使用Docker日志** - `docker-compose logs -f`

---

**开发者**: 高级中国全栈工程师  
**版本**: v1.0.0  
**更新时间**: 2025年5月27日
