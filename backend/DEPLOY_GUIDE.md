# 宝塔面板部署指南

## 一、环境变量配置

在宝塔面板中为后端服务设置以下环境变量：

### 必填变量

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `DEEPSEEK_API_KEY` | DeepSeek API Key | `sk-xxxxxxxxxxxxxxxx` |

### 可选变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `LLM_BASE_URL` | API 基础地址 | `https://api.deepseek.com` |
| `LLM_MODEL` | 模型名称 | `deepseek-chat` |
| `PORT` | 后端端口 | `3030` |

### 宝塔面板设置方法

1. 进入 **网站** → 选择你的站点 → **设置**
2. 找到 **环境变量** 或 **配置文件**
3. 添加环境变量：
   ```
   DEEPSEEK_API_KEY=sk-你的实际key
   LLM_BASE_URL=https://api.deepseek.com
   LLM_MODEL=deepseek-chat
   ```

---

## 二、文件部署

### 后端部署

1. 将 `backend` 文件夹上传到服务器
2. 安装依赖：
   ```bash
   cd /www/wwwroot/your-site/backend
   npm install
   npm run build
   ```
3. 使用 PM2 启动：
   ```bash
   pm2 start dist/server.js --name time-persona-backend
   ```

### 前端部署

1. 将 `backend-api-guide.html` 上传到网站根目录
2. 或者将 `web` 文件夹构建后部署：
   ```bash
   cd /www/wwwroot/your-site/web
   npm install
   npm run build
   ```
3. 将 `dist` 文件夹内容放到网站根目录

---

## 三、Nginx 反向代理配置

在宝塔面板的 Nginx 配置中添加：

```nginx
# 后端 API 代理
location /api/ {
    proxy_pass http://127.0.0.1:3030;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_cache_bypass $http_upgrade;
}

# 健康检查
location /health {
    proxy_pass http://127.0.0.1:3030;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
}
```

---

## 四、验证部署

### 1. 检查后端健康状态

访问：`https://你的域名/health`

应该返回：
```json
{
  "ok": true,
  "runtime": {...},
  "timestamp": "..."
}
```

### 2. 检查环境变量

访问：`https://你的域名/api/debug/env`

应该返回：
```json
{
  "hasApiKey": true,
  "apiKeyPreview": "sk-xxxxx...xxxx",
  "baseUrl": "https://api.deepseek.com",
  "model": "deepseek-chat"
}
```

### 3. 测试 LLM 接口

使用 `backend-api-guide.html` 页面的对话框测试，或用 curl：

```bash
curl -X POST https://你的域名/api/llm/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "system", "content": "你是助手"},
      {"role": "user", "content": "你好"}
    ]
  }'
```

---

## 五、常见问题

### Q: 提示 "API Key 未配置"

检查环境变量是否正确设置：
- 确认变量名是 `DEEPSEEK_API_KEY`（不是 `DEEPSEEK_KEY`）
- 确认重启了后端服务

### Q: 跨域问题

确保 Nginx 配置了 CORS 头：
```nginx
add_header Access-Control-Allow-Origin *;
add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
add_header Access-Control-Allow-Headers 'Content-Type, Authorization';
```

### Q: HTTPS 混合内容

如果前端是 HTTPS，后端也必须用 HTTPS。通过 Nginx 反向代理可以解决这个问题。

---

## 六、API 接口列表

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| GET | `/api/debug/env` | 检查环境变量 |
| POST | `/api/llm/chat` | DeepSeek 对话 |
| POST | `/api/llm/test` | 测试 LLM 连接 |
| GET | `/api/presets` | 获取预设人物 |
| GET | `/api/profiles/:id` | 获取人物详情 |
| POST | `/api/timeline/parse` | 解析时间线 |
| POST | `/api/agents/build` | 构建人格 |
| POST | `/api/arena/run` | 运行议会 |
