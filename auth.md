# 登录与会话（Cookie）

账密登录在生产环境可能关闭。**优先使用飞书 OAuth** 获取 `jx_session`。Skill 调业务 API 前须有效会话。

## 限制说明

| 方式 | 是否可行 |
|------|----------|
| 纯 curl 模拟飞书 OAuth | **否**（需跳转 open.feishu.cn，用户扫码/确认） |
| 打开浏览器完成飞书登录后保存 Cookie | **是**（推荐） |
| 用户从浏览器 DevTools 复制 `jx_session` | **是** |
| 账密 `/auth/password/login` | 仅当 `passwordLoginEnabled=true` 时 |

`jx_session` 为 **HttpOnly**，有效期约 **7 天**。过期后重新走飞书登录。

## Cookie 存放（本地，勿提交 Git）

```
performance-summary-review/.auth/cookies.txt   # curl Netscape 格式 cookie jar
```

目录已 `.gitignore`，勿把 Cookie 推上 GitHub。

## 流程 A：Agent 唤起飞书登录（推荐）

### 1. 检查现有会话

```http
GET {baseUrl}/api/session/me
Cookie: jx_session=...   # 若有 .auth/cookies.txt 则 curl -b 该文件
```

`authenticated: true` 且 `role` 满足要求（驳回须 `super_admin`）→ 直接使用，跳过登录。

### 2. 打开登录页

先查主体列表（无需登录）：

```http
GET {baseUrl}/auth/feishu/subjects
```

响应示例：`{ "items": [{ "code": "kzs", "name": "科臻赛" }, ...] }`

在**用户本机**打开浏览器（Agent 执行，用户操作飞书）：

```
{frontendUrl}/login
```

或直接跳转 OAuth（`subjectCode` 取自上一步，如 `kzs`）：

```
{baseUrl}/auth/feishu/login?subjectCode=kzs&next=/todo
```

| 变量 | jixiao2 默认 |
|------|----------------|
| `baseUrl` | `http://172.25.1.43:8081` |
| `frontendUrl` | 与 `baseUrl` 相同（前后端同域部署时）；若前端独立端口则改为前端地址 |

**Windows 唤起示例**：

```powershell
Start-Process "{frontendUrl}/login"
```

也可执行 Skill 附带脚本（见下方「脚本」）。

### 3. 用户完成飞书授权

用户在浏览器中：选主体 → 飞书扫码/确认 → 跳回系统首页/待办。

### 4. 保存 Cookie

登录成功后，从**同一浏览器会话**导出 `jx_session`，写入 `.auth/cookies.txt`：

**方式 1 — 浏览器自动化（Agent 有 browse / agent-browser 等工具时）**

1. 登录完成后访问 `{baseUrl}/api/session/me` 确认 `authenticated: true`
2. 导出当前站点 Cookie，至少包含 `jx_session`
3. 保存为 curl 可用的 cookie jar 到 `.auth/cookies.txt`

**方式 2 — 用户手动提供**

DevTools → Application → Cookies → 选中站点 → 复制 `jx_session` 值。

Agent 写入 jar 或后续请求头：

```http
Cookie: jx_session=<粘贴的值>
```

**方式 3 — 开发环境 Vite 代理**

本地 `http://localhost:5174/login` 飞书登录后，Cookie 在 5174 域名下；调远程 API 时需确认 Cookie 域与 `baseUrl` 一致，生产环境请直接用 `{baseUrl}/login`。

### 5. 验证并继续审核

```bash
curl -s -b .auth/cookies.txt "{baseUrl}/api/session/me"
```

通过后调用绩效列表/详情/驳回 API，均带 `-b .auth/cookies.txt`。

## 流程 B：账密登录（仅备用）

仅当 `GET /auth/feishu/subjects` 返回 `passwordLoginEnabled: true`：

```http
POST {baseUrl}/auth/password/login
Content-Type: application/json

{"username":"...","password":"..."}
```

用 `curl -c .auth/cookies.txt` 保存 Set-Cookie，后续 `-b` 复用。

## 脚本

`scripts/open-feishu-login.ps1`（Windows）：打开 `{frontendUrl}/login`。

Agent 在无会话时先运行脚本，**等待用户确认「已登录」**，再导出/验证 Cookie。

## 安全

- Cookie 等同登录凭证，勿写入 Skill 正文、勿提交仓库
- 驳回等写操作前再次 `GET /api/session/me` 确认身份
