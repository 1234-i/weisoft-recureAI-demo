# AI招聘助手演示平台 - Docker部署指南

## 项目简介

AI招聘助手演示平台是由上海未软人工智能公司开发的智能化招聘解决方案，集成了多个AI智能体，为HR提供全方位的招聘支持。

## 功能特性

### 基础智能体
- 🎯 职业规划助手 - AI职业发展规划
- 🎭 模拟面试 - 真实面试场景模拟
- 📄 简历匹配分析 - 智能简历职位匹配
- 💼 智能职位生成 - 自动生成职位描述
- 📊 面试评估报告 - 详细面试评估
- ⚖️ 劳动合同卫士 - 合同条款审查
- 📝 会议总结助手 - 智能会议记录
- 🔄 简历优化专家 - 简历内容优化
- 💬 HR智能助手 - 全能HR助手

### 高级智能体
- ✨ 简历制作专家 - 专业简历制作
- 🔍 简历筛选专家 - 智能简历筛选
- 🎓 面试出题专家 - 专业面试题生成

## 快速部署

### 方法一：一键部署（推荐）

```bash
# 给部署脚本执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

### 方法二：手动部署

#### 1. 构建前端项目
```bash
# 使用npm
npm run build

# 或使用yarn
yarn build

# 或使用pnpm
pnpm build
```

#### 2. 使用Docker Compose部署
```bash
# 构建并启动服务
docker-compose up -d --build

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

#### 3. 使用Docker直接部署
```bash
# 构建镜像
docker build -t pcm-agents-demo .

# 运行容器
docker run -d \
  --name pcm-agents-demo \
  -p 80:80 \
  --restart unless-stopped \
  pcm-agents-demo
```

### 方法三：生产环境部署

使用完整构建的生产环境Dockerfile：

```bash
# 构建生产镜像
docker build -f Dockerfile.prod -t pcm-agents-demo:prod .

# 运行生产容器
docker run -d \
  --name pcm-agents-demo-prod \
  -p 80:80 \
  -v $(pwd)/logs:/var/log/nginx \
  --restart unless-stopped \
  pcm-agents-demo:prod
```

## 访问应用

部署成功后，可以通过以下地址访问：

- **本地访问**: http://localhost
- **局域网访问**: http://YOUR_SERVER_IP

## 管理命令

### 查看服务状态
```bash
docker-compose ps
```

### 查看日志
```bash
# 查看所有日志
docker-compose logs

# 实时查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs pcm-agents-demo
```

### 重启服务
```bash
docker-compose restart
```

### 停止服务
```bash
docker-compose down
```

### 更新部署
```bash
# 停止服务
docker-compose down

# 重新构建并启动
docker-compose up -d --build
```

## 环境要求

- Docker 20.0+
- Docker Compose 2.0+
- 2GB+ 内存
- 1GB+ 磁盘空间

## 端口配置

- **HTTP**: 80 (默认)
- **HTTPS**: 443 (可选配置)

如需修改端口，请编辑 `docker-compose.yml` 文件中的端口映射。

## 故障排除

### 1. 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep :80

# 修改docker-compose.yml中的端口映射
ports:
  - "8080:80"  # 改为8080端口
```

### 2. 构建失败
```bash
# 清理Docker缓存
docker system prune -a

# 重新构建
docker-compose build --no-cache
```

### 3. 服务无法访问
```bash
# 检查容器状态
docker-compose ps

# 检查容器日志
docker-compose logs

# 检查nginx配置
docker-compose exec pcm-agents-demo nginx -t
```

## 技术支持

如有问题，请联系：
- 公司：上海未软人工智能公司
- 技术支持：请查看项目文档或提交Issue

## 许可证

本项目仅供演示使用，版权归上海未软人工智能公司所有。
