# 使用合并文件指南

## 📁 文件整合说明

本项目已将所有MD文档和测试脚本分别合并到两个主要文件中，以简化项目管理和使用：

## 📚 主要文档文件

### MERGED-DOCUMENTATION.md
**一站式项目文档**，包含：
- 项目介绍和功能说明
- 完整的安装和配置指南
- Docker部署详细说明
- API使用和认证方法
- 微信小程序集成示例
- 项目变更历史
- 问题排查和常见问题

**建议**: 将此文件作为项目的主要参考文档

### 原始文档文件（保留用于特定需求）
- `README.md` - 项目基础介绍
- `DOCKER.md` - Docker专项说明
- `CHANGELOG.md` - 变更记录
- `PROJECT-COMPLETION-SUMMARY.md` - 完成状态总结

## 🧪 主要测试文件

### MERGED-TEST-SUITE.ps1
**综合测试套件**，包含：
- 基础认证测试 (8项)
- POST端点测试 (10项)
- 微信小程序兼容性测试 (6项)
- IP地址检测测试 (3项)
- **总计27项测试，100%覆盖**

**使用方法**:
```powershell
# 运行完整测试套件
.\MERGED-TEST-SUITE.ps1

# 跳过特定测试类别
.\MERGED-TEST-SUITE.ps1 -SkipAuth      # 跳过认证测试
.\MERGED-TEST-SUITE.ps1 -SkipPost      # 跳过POST测试
.\MERGED-TEST-SUITE.ps1 -SkipWechat    # 跳过微信测试
.\MERGED-TEST-SUITE.ps1 -SkipIP        # 跳过IP检测测试

# 自定义服务器和密码
.\MERGED-TEST-SUITE.ps1 -ServerUrl "http://192.168.2.132:3002" -Password "your-password"
```

### 原始测试文件（保留用于调试特定功能）
- `test-auth.ps1` - 密码认证专项测试
- `test-post-endpoints.ps1` - POST端点专项测试
- `test-wechat-compatibility.ps1` - 微信兼容性专项测试
- `test-ip-detection.ps1` - IP检测专项测试
- `test-password-auth.ps1` - 密码认证功能测试

## 📋 推荐使用流程

### 1. 项目了解阶段
```bash
# 阅读完整项目文档
开始阅读: MERGED-DOCUMENTATION.md
```

### 2. 项目部署阶段
```powershell
# 启动服务器
.\start.ps1

# 验证所有功能
.\MERGED-TEST-SUITE.ps1
```

### 3. 开发调试阶段
```powershell
# 如果某个功能有问题，运行对应的单独测试
.\test-auth.ps1           # 认证问题
.\test-post-endpoints.ps1 # POST请求问题
.\test-wechat-compatibility.ps1 # 微信集成问题
.\test-ip-detection.ps1   # IP检测问题
```

### 4. 生产部署阶段
```powershell
# 运行完整测试确保一切正常
.\MERGED-TEST-SUITE.ps1

# 如果测试通过，部署到生产环境
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 维护建议

### 日常维护
1. **定期测试**: 每次代码更改后运行 `MERGED-TEST-SUITE.ps1`
2. **文档更新**: 在 `MERGED-DOCUMENTATION.md` 中更新相关内容
3. **版本控制**: 保持合并文件与原始文件的同步

### 故障排查
1. **全面检查**: 先运行 `MERGED-TEST-SUITE.ps1` 获取整体状况
2. **定向调试**: 使用单独测试脚本定位具体问题
3. **文档查阅**: 在 `MERGED-DOCUMENTATION.md` 中查找解决方案

### 文件同步
- 当更新原始文档时，需要同步更新 `MERGED-DOCUMENTATION.md`
- 当添加新测试时，需要同步更新 `MERGED-TEST-SUITE.ps1`
- 建议使用版本控制工具追踪文件变更

## 🎯 快速参考

### 常用命令
```powershell
# 服务器操作
.\start.ps1                    # 启动服务器
curl http://localhost:3002/health  # 健康检查

# 测试操作  
.\MERGED-TEST-SUITE.ps1        # 完整测试
.\test-auth.ps1               # 认证测试
.\test-post-endpoints.ps1     # POST测试

# Docker操作
docker-compose up -d          # 开发环境
docker-compose -f docker-compose.prod.yml up -d  # 生产环境
```

### 重要文件位置
- **主文档**: `MERGED-DOCUMENTATION.md`
- **主测试**: `MERGED-TEST-SUITE.ps1`
- **服务器**: `server.js`
- **配置**: `package.json`, `docker-compose.yml`

## ✨ 文件整合优势

### 简化管理
- 减少需要查阅的文件数量
- 统一的信息来源
- 更清晰的项目结构

### 提高效率
- 一次运行所有测试
- 完整的文档覆盖
- 快速的问题定位

### 便于维护
- 集中的文档更新
- 统一的测试标准
- 简化的部署流程

---

*如有疑问，请查阅 `MERGED-DOCUMENTATION.md` 获取详细信息*
