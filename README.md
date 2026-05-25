# performance-summary-review

Cursor Agent Skill：审核绩效自评「自我总结」内容质量，不合格时可经超管 API 驳回。

## 功能

- 单条 / 批量审核 `personalSummary`（自我总结）；不审各指标评分详情、不判总结与指标相关性
- 判定：通过 / 建议修改 / 不通过
- 不通过时可生成驳回原因并调用后端 API 退回员工修改

## 安装

### 方式一：放入项目（推荐，随仓库共享）

```bash
# 在本仓库根目录已位于 .cursor/skills/performance-summary-review/
# 克隆到其他项目：
git clone <本仓库URL> /tmp/performance-summary-review
cp -r /tmp/performance-summary-review/.cursor/skills/performance-summary-review \
  /path/to/your-project/.cursor/skills/
```

若 GitHub 仓库**根目录即 Skill 目录**（含 `SKILL.md`）：

```bash
git clone <本仓库URL> /path/to/your-project/.cursor/skills/performance-summary-review
```

### 方式二：个人全局 Skill

```bash
mkdir -p ~/.cursor/skills
cp -r performance-summary-review ~/.cursor/skills/
```

## 文件说明

| 文件 | 作用 |
|------|------|
| `SKILL.md` | 主指令（通用审核流程，可迁移） |
| `criteria.md` | 审核标准与示例 |
| `integration.md` | **对接配置**（API、字段、权限；按目标系统修改） |
| `auth.md` | **飞书登录与 Cookie 保存**（账密关闭时使用） |
| `scripts/open-feishu-login.ps1` | Windows 打开登录页 |
| `.auth/cookies.txt` | 本地会话（gitignore，勿提交） |
| `README.md` | 本说明 |

## 接入新系统

1. 复制 `integration.md`，按目标系统改写 `baseUrl`、端点、字段映射、角色名
2. 确保后端提供：读绩效详情、列表筛选、超管驳回（或等价写接口）
3. 在 Cursor 中 @ 引用 `performance-summary-review` 或说「审核自评」触发

## jixiao2 默认对接

本目录内 `integration.md` 已配置 jixiao2 后端：

- 读：`GET /api/performances/{id}`
- 驳：`POST /api/performances/ops/reject-self-review`（`super_admin`）

## 使用示例

```
审核 record id xxx 的自评总结
批量审核 2026-05 待上级评分的自评，列出建议驳回
驳回张三的自评（先出报告，我确认后再提交）
```

## 许可

与宿主项目保持一致。
