# Google Maps API代理服务器 Docker镜像
# 基于Node.js 20 Alpine版本，最新安全更新
FROM node:20-alpine

# 安全更新
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

# 设置工作目录
WORKDIR /app

# 创建非root用户提高安全性
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 安装dumb-init和yarn用于处理信号和包管理
RUN apk add --no-cache dumb-init yarn

# 复制package文件并安装依赖
COPY package*.json yarn.lock* ./
RUN yarn install --production --frozen-lockfile && yarn cache clean

# 复制源代码
COPY --chown=nextjs:nodejs . .

# 创建日志目录
RUN mkdir -p /app/logs && chown nextjs:nodejs /app/logs

# 切换到非root用户
USER nextjs

# 暴露端口
EXPOSE 3001

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { \
    process.exit(res.statusCode === 200 ? 0 : 1) \
  }).on('error', () => process.exit(1))"

# 使用dumb-init启动应用
ENTRYPOINT ["dumb-init", "--"]
CMD ["yarn", "start"]
