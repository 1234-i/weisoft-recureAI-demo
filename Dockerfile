# 使用预构建的方式 - 需要先在本地运行 pnpm build
FROM nginx:1.25-alpine

# 关键：安装CA根证书和必要的加密库支持
RUN apk add --no-cache ca-certificates openssl curl

# 复制本地构建的产物到nginx目录
COPY dist /usr/share/nginx/html

# 复制image目录到nginx目录（解决模态框logo显示问题）
COPY image /usr/share/nginx/html/image

# 复制nginx配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动nginx
CMD ["nginx", "-g", "daemon off;"]
