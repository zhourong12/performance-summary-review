---
name: performance-summary-review
description: >-
  审核绩效自评的自我总结（personalSummary）内容质量，并在不合格时驳回员工自评。
  仅检查总结是否充实、是否空洞套话；不审核各指标评分详情、不判断总结与指标是否相关。
  结论为不通过时可调用驳回 API。对接见 integration.md。当用户提到"审核自评"、
  "驳回自评"、"检查自我总结"、"自评不合格"、"review summary"、"自评内容审核"、
  "批量审核"时使用。
---

# 绩效自评审核（自我总结）

**只审核 `personalSummary`（自我总结）**，不审核 `selfReview[].comment`，也不判断总结与绩效指标是否相关。API 与权限见 [integration.md](integration.md)。

## 何时使用

- 审核某条 / 批量自评的**自我总结**
- 用户要求驳回总结不合格的自评
- 用户粘贴总结文本，仅做质量分析

## 启动前

1. 读 [integration.md](integration.md)
2. **会话**：按 [auth.md](auth.md) 优先读取 `.auth/token.txt`，所有业务 API 使用 `Authorization: Bearer <token>`
3. 调 API 前 `GET /api/session/me` 验证 `authenticated=true`；驳回须 `role=super_admin`

## 审核范围

| 审 | 不审 |
|----|------|
| `personalSummary` 字数、是否空洞套话、是否有具体工作描述 | `selfReview[].comment`（各指标评分详情） |
| | 总结与 `indicators` 是否相关、是否提及指标名 |
| | 自评分数、文化/学习维度 |

## 数据获取

- **单条**：详情接口 → 取 `personalSummary`、`employeeName`、`period`、`status`、`id`
- **批量**：列表分页 → 逐条拉详情（列表通常不含 `personalSummary`）
- **粘贴**：用户只给总结文本 → 跳过 API

无需为审核目的拉取或分析 `indicators`、`selfReview`。

## 审核流程

```
1. 读 integration.md（若调 API）
2. 确保会话（auth.md：优先读取 .auth/token.txt；无 Token/失效则提示用户在 API Token 页创建）
3. 权限检查 GET /api/session/me
4. 仅取 personalSummary
5. 按 criteria.md 做充实度 / 套话检查
6. 输出报告；不通过则附驳回原因草稿
7. 用户确认后调用驳回 API
```

标准详见 [criteria.md](criteria.md)。

## 审核结论

| 结论 | 条件 | 建议驳回 |
|------|------|----------|
| **通过** | ≥50 字且有具体工作/成果描述，非空洞套话 | 否 |
| **建议修改** | 20–49 字，或字数够但偏套话、缺具体事项 | 默认否 |
| **不通过** | 空、极短（<20 字）、或极短套话（如「整体表现良好」） | **是** |

## 驳回

前提：员工已提交（`manager_review` 等，见 integration）、Bearer Token 对应账号为 `super_admin`、`reason` 具体、**用户已确认**。

```http
POST {baseUrl}/api/performances/ops/reject-self-review
Authorization: Bearer {token}
Content-Type: application/json

{ "recordId": "{id}", "reason": "..." }
```

### 驳回原因模板

只描述 **personalSummary** 问题：

```text
您的自评总结未通过审核，请修改后重新提交。主要问题：
1. {如：自我总结内容过短，仅「整体表现良好」，未描述具体工作成果}
2. {如：总结多为套话，缺少本月具体工作事项或数据}
请补充具体工作内容、数据或案例后重新提交。
```

**禁止**在驳回原因中写：指标评分详情为空、总结与某指标无关等。

## 输出模板

```markdown
# 自评总结审核报告

- 员工：{employeeName}
- 考核月：{period}
- 记录 ID：{id}
- 结论：**通过** / **建议修改** / **不通过**
- 是否建议驳回：**是** / **否**

## 自我总结（personalSummary）

- 字数：{n} 字
- 判定：{通过 / 过短 / 空洞套话 / 为空}

## 问题清单

1. {仅针对总结本身}

## 改进建议

1. {如何写更充实的总结}

## 驳回原因草稿（建议驳回时）
```

批量：汇总数量 + 建议驳回清单（勿列指标 comment 问题）。

## 注意事项

- 不评判分数；不审指标分项 comment
- 调 API 优先使用 API Token；Cookie/飞书登录仅用于创建 Token 或备用排查
- 驳回须用户确认后再调 API
- 中文输出
