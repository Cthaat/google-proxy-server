# Docker部署说明

## 📁 Docker文件结构

```
google-proxy-server/
├── Dockerfile                 # 开发环境Docker镜像
├── Dockerfile.prod           # 生产环境优化镜像
├── docker-compose.yml        # 开发环境编排
├── docker-compose.prod.yml   # 生产环境编排
├── .dockerignore             # Docker构建忽略文件
├── .env.example              # 环境变量模板
├── nginx/
│   └── nginx.conf           # Nginx反向代理配置
├── deploy-docker.ps1        # Docker部署脚本
├── docker-manage.ps1        # Docker管理脚本
└── quick-deploy.ps1         # 快速部署脚本
```

## 🚀 快速开始

### 1. 一键部署（推荐新手）

```powershell
# 运行快速部署脚本
.\quick-deploy.ps1
```

### 2. 手动部署

```powershell
# 1. 配置环境变量
Copy-Item .env.example .env
# 编辑.env文件设置API密钥

# 2. 构建并启动
docker-compose up -d

# 3. 查看状态
docker-compose ps
```

## 🛠️ 管理命令

```powershell
# 启动服务
.\docker-manage.ps1 -Action start

# 停止服务
.\docker-manage.ps1 -Action stop

# 重启服务
.\docker-manage.ps1 -Action restart

# 查看日志
.\docker-manage.ps1 -Action logs

# 查看状态
.\docker-manage.ps1 -Action status

# 健康检查
.\docker-manage.ps1 -Action health

# 构建镜像
.\docker-manage.ps1 -Action build

# 清理环境
.\docker-manage.ps1 -Action clean
```

## 🏭 生产环境部署

```powershell
# 使用生产环境配置
.\docker-manage.ps1 -Action start -Environment prod
```

生产环境特性：
- ✅ 多阶段构建优化
- ✅ Nginx反向代理
- ✅ SSL/TLS支持
- ✅ 速率限制
- ✅ 安全加固
- ✅ 资源限制
- ✅ 健康检查

## 🔧 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `GOOGLE_MAPS_API_KEY` | Google Maps API密钥 | 必需 |
| `PORT` | 服务端口 | 3001 |
| `NODE_ENV` | 运行环境 | production |
| `CORS_ORIGIN` | CORS来源 | * |
| `LOG_LEVEL` | 日志级别 | info |
| `RATE_LIMIT_WINDOW` | 速率限制窗口 | 900000 |
| `RATE_LIMIT_MAX` | 最大请求数 | 100 |

### 端口映射

- 开发环境：`3001:3001`
- 生产环境：`80:80`, `443:443`

## 📊 监控和维护

### 健康检查

```bash
# 容器内部健康检查
wget --no-verbose --tries=1 --spider http://localhost:3001/health

# 外部健康检查
curl http://localhost:3001/health
```

### 日志管理

```powershell
# 查看实时日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs google-proxy

# 查看nginx日志（生产环境）
docker-compose -f docker-compose.prod.yml logs nginx
```

### 资源监控

```powershell
# 查看容器资源使用
docker stats

# 查看容器详情
docker inspect google-maps-proxy
```

## 🔒 安全配置

### 生产环境安全特性

1. **非root用户运行**
2. **只读文件系统**
3. **安全头设置**
4. **速率限制**
5. **SSL/TLS加密**
6. **网络隔离**

### SSL证书配置

```powershell
# 创建自签名证书（测试用）
mkdir nginx\ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx\ssl\key.pem \
    -out nginx\ssl\cert.pem
```

## 🔧 故障排除

### 常见问题

1. **容器启动失败**
   ```powershell
   docker-compose logs google-proxy
   ```

2. **端口冲突**
   ```powershell
   netstat -ano | findstr :3001
   ```

3. **权限问题**
   ```powershell
   # 确保用户在docker组中
   # 重启Docker Desktop
   ```

4. **网络问题**
   ```powershell
   docker network ls
   docker network inspect google-proxy-server_google-proxy-network
   ```

### 重置环境

```powershell
# 完全重置
.\docker-manage.ps1 -Action clean
docker system prune -a --volumes
```

## 📚 更多资源

- [Docker官方文档](https://docs.docker.com/)
- [Docker Compose文档](https://docs.docker.com/compose/)
- [Google Maps API文档](https://developers.google.com/maps/documentation)

---

**提示**: 如果您是Docker新手，建议先使用开发环境熟悉流程，再考虑生产环境部署。
