# Token获取测试说明

## 当前配置

- **Secret ID (AK)**: `ak-BMSZyMnACKX6MPNne9zPfdFA`
- **Secret Key (SK)**: `sk-qrFpGRrDiAcu0YSUirhOVgPBT83qusb5`
- **User ID**: `76015687511834624`

## Token获取流程

### 1. AK/SK签名认证流程

根据官方文档，采用AK/SK签名认证方式获取token：

1. **构造规范请求**:
   - HttpRequestMethod: `GET`
   - ApiUri: `/auth/access-token/` (必须以/结尾)
   - Timestamp: 当前时间戳（秒）

2. **创建待签字符串**:
   - 格式: `GET@/auth/access-token/@{timestamp}`
   - 示例: `GET@/auth/access-token/@1745025808`

3. **计算签名**:
   - 使用HMAC-SHA1算法
   - 对待签字符串进行签名
   - 结果进行Base64编码

4. **发送请求**:
   - URL: `https://api.pincaimao.com/agents/v1/auth/access-token?user={userId}`
   - Headers:
     - `x-secret-id`: Secret ID
     - `x-timestamp`: 时间戳
     - `x-signature`: 计算得到的签名

### 2. 请求示例

```javascript
// 请求Headers
{
  "x-secret-id": "ak-BMSZyMnACKX6MPNne9zPfdFA",
  "x-timestamp": "1745025808",
  "x-signature": "fIIiT6gAQUzEWu0A+kOmXxQW/vY="
}

// 请求URL
https://api.pincaimao.com/agents/v1/auth/access-token?user=76015687511834624
```

### 3. 期望响应格式

根据官方文档，正确的响应格式为：

```json
{
  "code": 0,
  "data": {
    "user": "76015687511834624",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "time_expire": 1745111483
  },
  "msg": "ok"
}
```

### 4. CORS解决方案

如果遇到跨域问题，项目已配置Vite代理：

1. **代理配置**: 通过 `/api/agents` 路径代理到 `https://api.pincaimao.com`
2. **自动处理**: 开发服务器自动处理CORS跨域问题

## 测试步骤

1. 打开浏览器开发者工具
2. 访问 http://localhost:5173/
3. 查看控制台输出，观察token获取过程
4. 查看页面顶部的状态指示器
5. 尝试点击任意功能卡片测试SDK调用

## 状态指示器

- **⏳ 正在获取SDK授权...**: token获取中
- **✅ SDK授权成功，所有功能已就绪**: token获取成功
- **⚠️ 错误信息**: token获取失败，显示具体错误

## 调试信息

在浏览器控制台中可以看到：

- 尝试的API端点
- 请求和响应详情
- 最终使用的token（前20个字符）
- 错误信息（如果有）

## 注意事项

1. 确保网络连接正常
2. 检查CORS策略是否允许跨域请求
3. 验证提供的密钥是否有效
4. 如果API端点不正确，请联系聘才猫技术支持获取正确的端点

## 手动测试API

可以使用curl命令手动测试API（需要先计算签名）：

```bash
# 注意：需要先计算正确的签名
curl -X GET 'https://api.pincaimao.com/agents/v1/auth/access-token?user=76015687511834624' \
  -H 'x-secret-id: ak-BMSZyMnACKX6MPNne9zPfdFA' \
  -H 'x-timestamp: 1745025808' \
  -H 'x-signature: fIIiT6gAQUzEWu0A+kOmXxQW/vY='
```

## 签名计算示例

```javascript
// 待签字符串
const stringToSign = "GET@/auth/access-token/@1745025808"

// 使用HMAC-SHA1 + Base64计算签名
const signature = hmacSha1Base64(secretKey, stringToSign)
```

---

如果需要更新token获取逻辑，请修改 `src/App.vue` 中的 `getSDKToken` 函数。
