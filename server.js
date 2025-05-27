/**
 * Google Maps API 本地代理服务器
 * 用于转发微信小程序的Google Maps API请求
 * 作者：高级中国全栈工程师
 */

const express = require('express');
const cors = require('cors');
const axios = require('axios');
const app = express();

// 服务器配置
const PORT = 3001;
const GOOGLE_MAPS_BASE_URL = 'https://maps.googleapis.com/maps/api';

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

/**
 * 地址自动完成API
 * GET /place/autocomplete/json?input=搜索词&language=zh-CN
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

/**
 * 地点详情API
 * GET /place/details/json?place_id=地点ID&language=zh-CN
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

/**
 * 附近搜索API
 * GET /place/nearbysearch/json?location=lat,lng&radius=半径&type=类型
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

/**
 * 文本搜索API
 * GET /place/textsearch/json?query=搜索词&language=zh-CN
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

/**
 * 距离矩阵API
 * GET /distancematrix/json?origins=起点&destinations=终点&mode=交通方式
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

/**
 * 路线规划API
 * GET /directions/json?origin=起点&destination=终点&mode=交通方式
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
    endpoints: [
      'GET /geocode/json - 地理编码',
      'GET /place/autocomplete/json - 地址自动完成',
      'GET /place/details/json - 地点详情',
      'GET /place/nearbysearch/json - 附近搜索',
      'GET /place/textsearch/json - 文本搜索',
      'GET /distancematrix/json - 距离矩阵',
      'GET /directions/json - 路线规划',
      'GET /health - 健康检查',
      'GET /api-status - API状态检查'
    ],
    usage: {
      base_url: `http://localhost:${PORT}`,
      example: `http://localhost:${PORT}/geocode/json?address=北京天安门&language=zh-CN`
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

// 启动服务器
app.listen(PORT, () => {
  console.log('🚀 Google Maps API代理服务器启动成功！');
  console.log(`📍 服务地址: http://localhost:${PORT}`);
  console.log(`🔍 健康检查: http://localhost:${PORT}/health`);
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
