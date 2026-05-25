---
name: performance-summary-review
description: >-
  审核绩效自评的自我总结内容质量，并在不合格时驳回员工自评。检查 personalSummary
  和 selfReview comments 是否充实、是否与绩效指标相关；结论为不通过时可调用驳回 API
  退回员工修改。支持单条审核、批量审核与驳回。对接细节见 integration.md。
  当用户提到"审核自评"、"驳回自评"、"检查自我总结"、"自评不合格"、
  "review summary"、"自评内容审核"、"批量审核"时使用。
---

# 绩效自评审核

审核员工自评的 **自我总结**（`personalSummary`）与 **各指标评分详情**（`selfReview[].comment`）的内容质量。可对接任意绩效系统，**API 与权限以 [integration.md](integration.md) 为准**。

## 迁移与安装

- 整个 `performance-summary-review/` 目录可复制到任意项目的 `.cursor/skills/`，或 `~/.cursor/skills/`
- 接入新系统时**只需修改 `integration.md`**，`SKILL.md` 与 `criteria.md` 通常无需改动
- 安装说明见 [README.md](README.md)

## 何时使用

- 审核某条 / 批量自评内容
- 用户要求驳回不合格自评
- 用户粘贴自评文本，仅做质量分析（无需 API）

## 启动前：读对接配置

1. 读取 [integration.md](integration.md) 获取 `baseUrl`、端点、字段映射、驳回角色
2. 若文件不存在，向用户询问 API 地址与字段名，或仅做纯文本审核

## 权限检查（调 API 前）

1. 调用 integration 中的 **session/身份接口**（jixiao2：`GET /api/session/me`）
2. 未登录 → 提示登录；仅粘贴文本则跳过
3. **读数据**：按 integration 说明（jixiao2：本人 / 上级 / `performance_list_all`）
4. **驳回写操作**：须满足 integration 中的管理员角色（jixiao2：`role === "super_admin"`），否则只出报告不调驳回 API

## 审核范围

| 逻辑字段 | 典型 JSON 键 |
|----------|-------------|
| 自我总结 | `personalSummary` |
| 分项说明 | `selfReview[].comment` |
| 指标定义 | `indicators[]`（name / description / criteria） |

文化价值观、学习成长维度默认不审（除非用户明确要求）。

## 数据获取

按 [integration.md](integration.md) 中的端点执行：

- **单条**：详情接口 → 提取总结、自评、指标、员工名、周期、状态
- **批量**：列表接口分页 → 逐条拉详情（列表通常不含 `personalSummary`）
- **粘贴模式**：用户已提供文本 + 指标 → 跳过 API

若 `status` 非自评进行中且用户未要求审历史，报告中注明「仅作内容质量参考」。

## 审核流程

```
1. 读 integration.md（若调 API）
2. 权限检查（若调 API）
3. 收集 personalSummary + selfReview comments + indicators
4. 充实度 + 相关性检查（见 criteria.md）
5. 输出报告；不通过则附驳回原因草稿
6. 用户确认后，按 integration 调用驳回 API
```

## 审核结论

| 结论 | 条件 | 是否建议驳回 |
|------|------|-------------|
| **通过** | 无严重问题，轻微建议 ≤ 1 条 | 否 |
| **建议修改** | 过短、部分指标未覆盖、comment 空洞 | 默认否；用户明确要求时可驳 |
| **不通过** | 总结空/极短（<20 字）、comment 全空或套话、与指标完全无关 | **是** |

## 驳回自评

### 前提（业务 + integration）

- 员工**已提交**自评，处于上级待评状态（见 integration 允许的状态列表）
- 操作账号具备 integration 定义的驳回角色
- `reason` 非空且具体
- **须用户确认**后再调用写接口

### 执行流程

```
1. 审核 → 报告 + 驳回原因草稿
2. 检查 status、角色（session/me）
3. 展示草稿，等待用户确认
4. POST integration 中的 reject 端点
5. 成功：回报员工、record id、原因摘要；403：提示换管理员账号
```

禁止未经确认直接驳回。

### 驳回原因模板

```text
您的自评总结未通过审核，请修改后重新提交。主要问题：
1. {问题1}
2. {问题2}
请针对以上问题补充具体工作内容、数据或案例后重新提交。
```

## 输出模板

单条：

```markdown
# 自评审核报告

- 员工：{employeeName}
- 考核月：{period}
- 记录 ID：{id}
- 结论：**通过** / **建议修改** / **不通过**
- 是否建议驳回：**是** / **否**
- 当前操作权限：可读 / 可驳回 / 仅文本审核

## 充实度
...

## 指标相关性
| 指标 | comment 状态 | 说明 |

## 问题清单 / 改进建议

## 驳回原因草稿（建议驳回时）
```

批量：汇总通过/建议修改/不通过数量 + 建议驳回清单表。

## 注意事项

- 只审文本质量，不评判分数高低
- 写操作依赖 integration 配置，换系统只改 `integration.md`
- 中文输出报告
- 详细阈值与示例见 [criteria.md](criteria.md)
