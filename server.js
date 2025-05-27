/**
 * Google Maps API 本地代理服务器
 * 用于转发微信小程序的Google Maps API请求
 * 作者：高级中国全栈工程师
 */

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const os = require('os');
const { execSync } = require('child_process');
const app = express();

// 服务器配置
const PORT = process.env.PORT || 3002;
const GOOGLE_MAPS_BASE_URL = 'https://maps.googleapis.com/maps/api';
const API_PASSWORD = process.env.API_PASSWORD || 'google-maps-proxy-2024';

// 您的Google Maps API密钥 - 请替换为您的真实密钥
const API_KEY = 'AIzaSyC9cGQ8JXj_E9Q6eTmyCAcSkxJCZSCyU-U';

// 中间件配置
app.use(cors({
  origin: '*', // 允许所有来源，生产环境建议限制具体域名
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 日志中间件 - 生产环境简化
app.use((req, res, next) => {
  if (process.env.NODE_ENV !== 'production') {
    console.log(`${new Date().toLocaleString()} - ${req.method} ${req.path}`);
  }
  next();
});

// 密码认证中间件
function validatePassword(req, res, next) {
  // 跳过公共路径的认证
  const publicPaths = ['/health', '/api-status', '/'];
  if (publicPaths.includes(req.path)) {
    return next();
  }

  // 获取密码（支持多种传递方式）
  let providedPassword = null;

  // 1. 查询参数中的密码
  if (req.query.password) {
    providedPassword = req.query.password;
  }
  // 2. 请求头中的密码
  else if (req.headers['x-api-password']) {
    providedPassword = req.headers['x-api-password'];
  }
  // 3. Authorization Bearer token
  else if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    providedPassword = req.headers.authorization.substring(7);
  }
  // 4. 请求体中的密码
  else if (req.body && req.body.password) {
    providedPassword = req.body.password;
  }

  // 验证密码
  if (!providedPassword) {
    return res.status(401).json({
      status: 'UNAUTHORIZED',
      error_message: '需要提供API密码',
      hint: '请通过以下方式之一提供密码：',
      methods: [
        '查询参数: ?password=your_password',
        '请求头: X-API-Password: your_password',
        'Bearer Token: Authorization: Bearer your_password',
        '请求体: {"password": "your_password"}'
      ],
      timestamp: new Date().toISOString()
    });
  }

  if (providedPassword !== API_PASSWORD) {
    console.log(`🚫 密码验证失败 - IP: ${req.ip}, 提供的密码: ${providedPassword.substring(0, 3)}***`);
    return res.status(403).json({
      status: 'FORBIDDEN',
      error_message: 'API密码不正确',
      timestamp: new Date().toISOString()
    });
  }

  // 密码验证成功，记录日志
  if (process.env.NODE_ENV !== 'production') {
    console.log(`✅ 密码验证成功 - IP: ${req.ip}, 路径: ${req.path}`);
  }

  next();
}

// 应用密码认证中间件到所有路由
app.use(validatePassword);

/**
 * 通用的Google API代理函数
 * @param {string} endpoint - Google API端点
 * @param {object} params - 请求参数
 * @returns {Promise} API响应
 */
async function proxyGoogleAPI(endpoint, params) {
  try {
    // 添加API密钥到参数中
    const queryParams = {
      ...params,
      key: API_KEY
    };

    const url = `${GOOGLE_MAPS_BASE_URL}${endpoint}`;

    console.log(`🌐 转发请求到: ${url}`);
    console.log(`📋 请求参数:`, queryParams);

    const response = await axios.get(url, {
      params: queryParams,
      timeout: 10000 // 10秒超时
    });

    console.log(`✅ Google API响应状态: ${response.data.status}`);
    return response.data;
  } catch (error) {
    console.error(`❌ Google API请求失败:`, error.message);

    if (error.code === 'ECONNABORTED') {
      throw new Error('REQUEST_TIMEOUT');
    } else if (error.response) {
      throw new Error(`HTTP_ERROR_${error.response.status}`);
    } else {
      throw new Error('NETWORK_ERROR');
    }
  }
}

// ============ API路由定义 ============

/**
 * 地理编码API - 地址转坐标
 * GET /geocode/json?address=地址&language=zh-CN&region=CN
 * POST /geocode/json - 支持请求体传参
 */
app.get('/geocode/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/geocode/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

app.post('/geocode/json', async (req, res) => {
  try {
    // 合并查询参数和请求体参数
    const params = { ...req.query, ...req.body };
    // 移除密码参数，避免传递给Google API
    delete params.password;
    const result = await proxyGoogleAPI('/geocode/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

/**
 * 地址自动完成API
 * GET /place/autocomplete/json?input=搜索词&language=zh-CN
 * POST /place/autocomplete/json - 支持请求体传参
 */
app.get('/place/autocomplete/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/place/autocomplete/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      predictions: []
    });
  }
});

app.post('/place/autocomplete/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/place/autocomplete/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      predictions: []
    });
  }
});

/**
 * 地点详情API
 * GET /place/details/json?place_id=地点ID&language=zh-CN
 * POST /place/details/json - 支持请求体传参
 */
app.get('/place/details/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/place/details/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      result: {}
    });
  }
});

app.post('/place/details/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/place/details/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      result: {}
    });
  }
});

/**
 * 附近搜索API
 * GET /place/nearbysearch/json?location=lat,lng&radius=半径&type=类型
 * POST /place/nearbysearch/json - 支持请求体传参
 */
app.get('/place/nearbysearch/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/place/nearbysearch/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

app.post('/place/nearbysearch/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/place/nearbysearch/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

/**
 * 文本搜索API
 * GET /place/textsearch/json?query=搜索词&language=zh-CN
 * POST /place/textsearch/json - 支持请求体传参
 */
app.get('/place/textsearch/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/place/textsearch/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

app.post('/place/textsearch/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/place/textsearch/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      results: []
    });
  }
});

/**
 * 距离矩阵API
 * GET /distancematrix/json?origins=起点&destinations=终点&mode=交通方式
 * POST /distancematrix/json - 支持请求体传参
 */
app.get('/distancematrix/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/distancematrix/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      rows: []
    });
  }
});

app.post('/distancematrix/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/distancematrix/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      rows: []
    });
  }
});

/**
 * 路线规划API
 * GET /directions/json?origin=起点&destination=终点&mode=交通方式
 * POST /directions/json - 支持请求体传参
 */
app.get('/directions/json', async (req, res) => {
  try {
    const result = await proxyGoogleAPI('/directions/json', req.query);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      routes: []
    });
  }
});

app.post('/directions/json', async (req, res) => {
  try {
    const params = { ...req.query, ...req.body };
    delete params.password;
    const result = await proxyGoogleAPI('/directions/json', params);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error_message: error.message,
      routes: []
    });
  }
});

// ============ 健康检查和测试路由 ============

/**
 * 健康检查
 */
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Google Maps API代理服务器运行正常',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

/**
 * API状态检查
 */
app.get('/api-status', async (req, res) => {
  try {
    // 简单状态检查
    res.json({
      status: 'OK',
      message: 'Google Maps API代理服务器运行正常',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      message: 'API检查失败',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

/**
 * 显示支持的API列表
 */
app.get('/', (req, res) => {
  res.json({
    name: 'Google Maps API 代理服务器',
    version: '1.0.0',
    description: '为微信小程序提供Google Maps API代理服务',
    authentication: {
      required: true,
      password: '需要提供API密码才能访问API端点',
      methods: [
        '查询参数: ?password=your_password',
        '请求头: X-API-Password: your_password',
        'Bearer Token: Authorization: Bearer your_password',
        '请求体: {"password": "your_password"}'
      ]
    },
    endpoints: [
      'GET /geocode/json - 地理编码',
      'POST /geocode/json - 地理编码（支持请求体）',
      'GET /place/autocomplete/json - 地址自动完成',
      'POST /place/autocomplete/json - 地址自动完成（支持请求体）',
      'GET /place/details/json - 地点详情',
      'POST /place/details/json - 地点详情（支持请求体）',
      'GET /place/nearbysearch/json - 附近搜索',
      'POST /place/nearbysearch/json - 附近搜索（支持请求体）',
      'GET /place/textsearch/json - 文本搜索',
      'POST /place/textsearch/json - 文本搜索（支持请求体）',
      'GET /distancematrix/json - 距离矩阵',
      'POST /distancematrix/json - 距离矩阵（支持请求体）',
      'GET /directions/json - 路线规划',
      'POST /directions/json - 路线规划（支持请求体）',
      'GET /health - 健康检查（无需密码）',
      'GET /api-status - API状态检查（无需密码）'
    ],
    usage: {
      base_url: `http://localhost:${PORT}`,
      example: `http://localhost:${PORT}/geocode/json?address=北京天安门&language=zh-CN&password=your_password`
    }
  });
});

// 错误处理中间件
app.use((error, req, res, next) => {
  console.error('服务器错误:', error);
  res.status(500).json({
    status: 'ERROR',
    error_message: '服务器内部错误',
    timestamp: new Date().toISOString()
  });
});

// 404处理
app.use((req, res) => {
  res.status(404).json({
    status: 'NOT_FOUND',
    error_message: `路径 ${req.path} 不存在`,
    available_endpoints: [
      '/geocode/json',
      '/place/autocomplete/json',
      '/place/details/json',
      '/place/nearbysearch/json',
      '/place/textsearch/json',
      '/distancematrix/json',
      '/directions/json',
      '/health',
      '/api-status'
    ]
  });
});

/**
 * 获取默认网关对应的本地IP地址
 * @returns {string|null} IP地址或null
 */
function getIPByDefaultGateway() {
  try {
    // Windows系统获取默认网关
    const result = execSync('route print 0.0.0.0', { encoding: 'utf8', timeout: 5000 });
    const lines = result.split('\n');

    for (const line of lines) {
      if (line.includes('0.0.0.0') && line.includes('0.0.0.0')) {
        const parts = line.trim().split(/\s+/);
        if (parts.length >= 4) {
          const localIP = parts[3]; // 本地IP地址
          // 验证是否为有效的局域网IP
          if (localIP && localIP.match(/^(\d{1,3}\.){3}\d{1,3}$/) &&
            (localIP.startsWith('192.168.') || localIP.startsWith('10.') ||
              (localIP.startsWith('172.') && parseInt(localIP.split('.')[1]) >= 16 && parseInt(localIP.split('.')[1]) <= 31))) {
            console.log(`🎯 通过默认网关检测到真实IP: ${localIP}`);
            return localIP;
          }
        }
      }
    }
  } catch (error) {
    console.log('⚠️  无法通过默认网关获取IP:', error.message);
  }
  return null;
}

/**
 * 获取本机真实的局域网IP地址（排除VPN虚拟网卡）
 * @returns {string} 局域网IP地址
 */
function getLocalIPAddress() {
  // 方法1: 尝试通过默认网关获取真实IP
  const gatewayIP = getIPByDefaultGateway();
  if (gatewayIP) {
    return gatewayIP;
  }

  // 方法2: 通过网络接口筛选
  const interfaces = os.networkInterfaces();

  // VPN和虚拟网卡的常见关键词
  const vpnKeywords = [
    'tap', 'tun', 'vpn', 'virtual', 'vmware', 'vbox', 'hyper-v',
    'docker', 'wsl', 'loopback', 'teredo', 'isatap', 'pptp',
    'openvpn', 'wireguard', 'nordvpn', 'expressvpn', 'clash',
    'wintun', 'utun', 'cscotun'
  ];

  // 物理网卡的常见关键词（Windows）
  const physicalKeywords = [
    'ethernet', 'wi-fi', 'wireless', 'wlan', 'lan', 'realtek',
    'intel', 'broadcom', 'qualcomm', 'atheros'
  ];

  // 优先级排序
  const physicalInterfaces = [];
  const otherInterfaces = [];

  for (const interfaceName in interfaces) {
    const networkInterface = interfaces[interfaceName];
    const lowerName = interfaceName.toLowerCase();

    // 检查是否为VPN或虚拟网卡
    const isVirtual = vpnKeywords.some(keyword => lowerName.includes(keyword));
    const isPhysical = physicalKeywords.some(keyword => lowerName.includes(keyword));

    for (const iface of networkInterface) {
      // 只处理IPv4地址，跳过内部地址
      if (iface.family === 'IPv4' && !iface.internal) {
        const ipInfo = {
          name: interfaceName,
          address: iface.address,
          isVirtual: isVirtual,
          isPhysical: isPhysical
        };

        // 判断是否为真实的局域网地址
        const ip = iface.address;
        const isPrivateIP = (
          ip.startsWith('192.168.') ||
          ip.startsWith('10.') ||
          (ip.startsWith('172.') && parseInt(ip.split('.')[1]) >= 16 && parseInt(ip.split('.')[1]) <= 31)
        );

        if (isPrivateIP) {
          if (isPhysical || !isVirtual) {
            physicalInterfaces.push(ipInfo);
          } else {
            otherInterfaces.push(ipInfo);
          }
        }
      }
    }
  }

  // 优先返回物理网卡的IP
  if (physicalInterfaces.length > 0) {
    console.log(`🌐 检测到物理网卡: ${physicalInterfaces[0].name} - ${physicalInterfaces[0].address}`);
    return physicalInterfaces[0].address;
  }

  // 如果没有物理网卡，返回其他可用的
  if (otherInterfaces.length > 0) {
    console.log(`⚠️  使用虚拟网卡: ${otherInterfaces[0].name} - ${otherInterfaces[0].address}`);
    return otherInterfaces[0].address;
  }

  console.log('⚠️  未找到可用的局域网IP，使用localhost');
  return 'localhost';
}

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  const localIP = getLocalIPAddress();

  console.log('🚀 Google Maps API代理服务器启动成功！');
  console.log(`📍 本地地址: http://localhost:${PORT}`);
  console.log(`🌐 局域网地址: http://${localIP}:${PORT}`);
  console.log(`🔍 健康检查: http://${localIP}:${PORT}/health`);
  console.log(`📱 微信小程序配置地址: ${localIP}:${PORT}`);
  console.log('');
  console.log('📋 可用的API端点:');
  console.log(`   • 地理编码: http://${localIP}:${PORT}/geocode/json`);
  console.log(`   • 逆地理编码: http://${localIP}:${PORT}/geocode/json`);
  console.log(`   • 地点搜索: http://${localIP}:${PORT}/place/textsearch/json`);
  console.log(`   • 地点详情: http://${localIP}:${PORT}/place/details/json`);
  console.log(`   • 路线规划: http://${localIP}:${PORT}/directions/json`);
});

// 优雅关闭
process.on('SIGINT', () => {
  console.log('\n🛑 正在关闭服务器...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 正在关闭服务器...');
  process.exit(0);
});
