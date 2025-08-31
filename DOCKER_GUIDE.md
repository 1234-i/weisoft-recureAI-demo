# Docker部署指南

## 🐳 在Ubuntu 22.04上构建Docker镜像

### 前置要求

1. **安装Docker**:
```bash
# 更新包索引
sudo apt update

# 安装Docker
sudo apt install docker.io -y

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将用户添加到docker组（可选，避免每次使用sudo）
sudo usermod -aG docker $USER
# 注销并重新登录以使组更改生效
```

2. **安装Docker Buildx**（用于跨平台构建）:
```bash
# Docker Buildx通常已包含在新版本的Docker中
# 如果没有，可以手动安装
docker buildx version

# 创建并使用新的builder实例
docker buildx create --name mybuilder --use
docker buildx inspect --bootstrap
```

### 构建方法

#### 方法1：使用构建脚本（推荐）

```bash
# 给脚本执行权限
chmod +x docker-build.sh

# 构建镜像（使用默认参数）
./docker-build.sh

# 或指定版本和名称
./docker-build.sh v2.0.0 my-ai-recruitment
```

#### 方法2：手动构建

```bash
# 基本构建命令
docker buildx build \
  --platform linux/amd64 \
  -t registry.cn-hangzhou.aliyuncs.com/weisoft/ai-recruitment-demo:v1.0.0 \
  --build-arg name=app \
  --build-arg proxy=taobao \
  --push \
  .
```

### 构建参数说明

- `--platform linux/amd64`: 指定目标平台为AMD64架构
- `--build-arg proxy=taobao`: 使用淘宝镜像源加速构建
- `--build-arg name=app`: 应用名称参数
- `--push`: 构建完成后推送到镜像仓库

### 本地运行

如果只想本地构建和运行（不推送到仓库）：

```bash
# 本地构建
docker buildx build \
  --platform linux/amd64 \
  -t ai-recruitment-demo:latest \
  --build-arg name=app \
  --build-arg proxy=taobao \
  --load \
  .

# 本地运行
docker run -d -p 8080:80 ai-recruitment-demo:latest
```

### 镜像特性

#### 多阶段构建
- **构建阶段**: 使用Node.js 18 Alpine镜像进行应用构建
- **运行阶段**: 使用Nginx Alpine镜像提供静态文件服务

#### 跨平台支持
- 支持 `linux/amd64` 架构
- 可扩展支持 `linux/arm64` 等其他架构

#### 网络优化
- 使用淘宝npm镜像源加速依赖安装
- 支持pnpm包管理器
- Nginx配置了Gzip压缩和静态资源缓存

#### CORS解决方案
- Nginx配置了API代理，解决跨域问题
- 自动处理预检请求
- 支持所有必要的CORS头

### 部署配置

#### 环境变量（可选）
```bash
# 如果需要自定义配置，可以通过环境变量传递
docker run -d -p 8080:80 \
  -e NODE_ENV=production \
  ai-recruitment-demo:latest
```

#### 数据卷挂载（可选）
```bash
# 如果需要自定义nginx配置
docker run -d -p 8080:80 \
  -v /path/to/custom/nginx.conf:/etc/nginx/nginx.conf:ro \
  ai-recruitment-demo:latest
```

### 故障排除

#### 构建失败
1. **网络问题**: 确保可以访问npm镜像源
2. **权限问题**: 确保用户有Docker权限
3. **磁盘空间**: 确保有足够的磁盘空间

#### 运行问题
1. **端口冲突**: 更改映射端口 `-p 8081:80`
2. **API调用失败**: 检查网络连接和CORS配置

#### 查看日志
```bash
# 查看容器日志
docker logs <container_id>

# 实时查看日志
docker logs -f <container_id>
```

### 生产部署建议

1. **使用Docker Compose**:
```yaml
version: '3.8'
services:
  ai-recruitment:
    image: registry.cn-hangzhou.aliyuncs.com/weisoft/ai-recruitment-demo:v1.0.0
    ports:
      - "80:80"
    restart: unless-stopped
    environment:
      - NODE_ENV=production
```

2. **使用反向代理**:
   - 配置Nginx或Traefik作为反向代理
   - 添加SSL证书支持HTTPS
   - 配置负载均衡（如果需要）

3. **监控和日志**:
   - 配置日志收集（如ELK Stack）
   - 添加健康检查
   - 配置监控告警

### 镜像大小优化

当前镜像已经进行了以下优化：
- 使用Alpine Linux基础镜像
- 多阶段构建，只保留运行时必需文件
- 删除构建缓存和临时文件

最终镜像大小约为 **50MB**（不包含应用代码）。
