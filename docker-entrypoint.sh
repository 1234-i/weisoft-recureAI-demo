#!/bin/sh

# AI招聘助手演示平台 - Docker启动脚本

set -e

echo "🚀 启动 AI招聘助手演示平台..."

# 检查nginx配置
echo "🔧 检查nginx配置..."
nginx -t

# 创建必要的目录
mkdir -p /var/log/nginx

# 输出系统信息
echo "📊 系统信息："
echo "   时间: $(date)"
echo "   时区: $(cat /etc/timezone)"
echo "   Nginx版本: $(nginx -v 2>&1)"

# 输出环境变量
echo "🌍 环境变量："
echo "   NODE_ENV: ${NODE_ENV:-development}"

# 启动nginx
echo "✅ 启动nginx服务..."
exec "$@"
