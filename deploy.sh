#!/bin/bash

# AI招聘助手演示平台 - Docker部署脚本
# 作者：上海未软人工智能公司

set -e

echo "🚀 开始部署 AI招聘助手演示平台..."

# 检查是否安装了Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

# 检查是否安装了Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 构建前端项目
echo "📦 构建前端项目..."
if command -v npm &> /dev/null; then
    npm run build
elif command -v yarn &> /dev/null; then
    yarn build
elif command -v pnpm &> /dev/null; then
    pnpm build
else
    echo "❌ 未找到npm、yarn或pnpm，请先安装Node.js包管理器"
    exit 1
fi

# 检查构建结果
if [ ! -d "dist" ]; then
    echo "❌ 构建失败，dist目录不存在"
    exit 1
fi

echo "✅ 前端项目构建完成"

# 停止现有容器（如果存在）
echo "🛑 停止现有容器..."
docker-compose down --remove-orphans || true

# 构建Docker镜像
echo "🔨 构建Docker镜像..."
docker-compose build --no-cache

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if docker-compose ps | grep -q "Up"; then
    echo "✅ 部署成功！"
    echo ""
    echo "🌐 访问地址："
    echo "   本地访问: http://localhost"
    echo "   局域网访问: http://$(hostname -I | awk '{print $1}')"
    echo ""
    echo "📊 查看日志: docker-compose logs -f"
    echo "🛑 停止服务: docker-compose down"
    echo ""
    echo "🎉 AI招聘助手演示平台已成功部署！"
else
    echo "❌ 部署失败，请检查日志："
    docker-compose logs
    exit 1
fi
