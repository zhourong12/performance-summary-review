# 系统对接配置（jixiao2）

将本 Skill 接入其他绩效系统时，复制本文件为 `integration.md` 并改写下列项。Agent 调 API 前**先读此文件**。

## 环境

| 变量 | jixiao2 默认值 | 说明 |
|------|----------------|------|
| `baseUrl` | `http://172.25.1.43:8081` | API 根地址 |
| `frontendUrl` | `http://172.25.1.43:8081` | 登录页；与 API 同域时与 baseUrl 相同 |
| `sessionCookie` | `jx_session` | 登录 Cookie 名 |
| `cookieJar` | `.auth/cookies.txt` | 本地 cookie jar（勿提交 Git） |
| `authHeader` | — | 若用 Bearer Token，在此说明 |

## 登录与会话

账密可能关闭。**优先飞书登录**，流程见 [auth.md](auth.md)：

1. `GET /api/session/me` 检查是否已登录
2. 未登录 → 打开 `{frontendUrl}/login`，用户飞书授权
3. 将 `jx_session` 保存到 `.auth/cookies.txt`
4. 后续 API 使用 `curl -b .auth/cookies.txt`

可执行 `scripts/open-feishu-login.ps1` 唤起浏览器。

```http
GET {baseUrl}/api/session/me
Cookie: {sessionCookie}=...
```

| 字段 | 用途 |
|------|------|
| `authenticated` | 须为 `true` |
| `role` | 驳回操作须为 `super_admin` |
| `menus.performance_list_all` | 有则可查看任意绩效详情（批量审核） |

403 / 未登录 → 停止写操作，提示用户登录或换账号。

## 数据字段映射

| 逻辑名 | jixiao2 JSON 字段 |
|--------|-------------------|
| 记录 ID | `id` |
| 员工姓名 | `employeeName` |
| 考核周期 | `period` |
| 流程状态 | `status` |
| 自我总结（**唯一审核字段**） | `personalSummary` |

以下字段可忽略，**不得**用于审核判定：`selfReview`、`indicators`、`cultureSelfReview` 等。

## API 端点（jixiao2）

### 单条详情

```http
GET {baseUrl}/api/performances/{id}
```

### 列表（批量）

```http
GET {baseUrl}/api/performances?page=1&pageSize=50&status=manager_review&period={period}&departmentId={deptId}
```

常用 `status`：`self_review`、`manager_review`、`dual_manager_review`、`dotted_manager_review`（逗号分隔可多选）

### 超管驳回自评（Skill 写操作）

```http
POST {baseUrl}/api/performances/ops/reject-self-review
Content-Type: application/json

{ "recordId": "{id}", "reason": "驳回原因" }
```

- 角色：`super_admin`
- 允许状态：`manager_review` | `dual_manager_review` | `dotted_manager_review`
- 成功：`{ "success": true, "newStatus": "self_review" }`

### 上级驳回（Skill 不使用，仅 Web 详情页）

```http
POST {baseUrl}/api/performances/{id}/reject
{ "reason": "..." }
```

需直属/虚线上级身份。

## 流程状态说明（jixiao2）

| status | 含义 | 可否驳回 |
|--------|------|----------|
| `self_review` | 员工自评中 | 否（未提交） |
| `manager_review` | 待直属上级评 | 是 |
| `dual_manager_review` | 待双上级评 | 是 |
| `dotted_manager_review` | 待虚线上级评 | 是 |

驳回后状态变为 `self_review`，`rejectionReason` 写入原因，并触发飞书通知员工。
