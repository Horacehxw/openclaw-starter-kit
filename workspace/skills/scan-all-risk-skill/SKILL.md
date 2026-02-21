---
name: scan-all-risk-skill
description: "批量扫描所有已安装 Skill 的安全风险。遍历 skills/ 目录下每个 Skill，按照 risk-skill-scanner 的审计框架逐一检查，生成汇总报告。适用于：(1) 定期安全巡检（每日 01:00 cron 自动执行），(2) 安装多个新 Skill 后批量审计，(3) 全面评估工作区 Skill 安全态势。"
---

# 批量 Skill 风险扫描

## 概述

此 Skill 对 `skills/` 目录下所有已安装 Skill 执行安全审计，参照 `risk-skill-scanner` 的检查框架，生成汇总报告。

## 扫描流程

### 1. 收集目标

遍历 `skills/*/` 目录，对每个包含 `SKILL.md` 的子目录执行扫描：

```bash
# 扫描目标
skills/*/SKILL.md        # 每个 Skill 的定义文件
skills/*/                # 每个 Skill 目录下的所有文件（脚本、配置等）
```

### 2. 逐一审计

对每个 Skill，按照 `risk-skill-scanner` 的 Quick Checklist 执行检查：

1. **读取 SKILL.md** — 了解 Skill 声明的用途和描述
2. **扫描目录下所有文件** — 查找代码文件、脚本、配置
3. **按 4 级 checklist 检查**：
   - 🔴 **CRITICAL** — 数据外泄、系统破坏、恶意代码、sudo 滥用
   - 🟠 **HIGH** — 硬编码外部端点、目录逃逸、危险权限、未经同意的遥测
   - 🟡 **MEDIUM** — 可能泄露数据的 API 调用、无限循环、混淆代码
   - 🟢 **LOW** — 代码清晰度、输入验证、错误处理
4. **按 6 维度深度检查**：
   - 文件系统操作（路径遍历、敏感文件访问）
   - 网络与数据外泄（外部请求、数据上传）
   - 权限与能力（sudo、chmod、破坏性命令）
   - 代码混淆（base64、eval、exec）
   - 行为分析（无限循环、资源耗尽、挖矿）
   - 权限对齐（声明用途 vs 实际行为）

### 3. 误报排除

以下内置 Skill 的特定行为属于正常操作，不应标记为风险：

| Skill | 允许的行为 | 原因 |
|-------|-----------|------|
| `daily-snapshot` | 执行 bash 脚本、读写 `snapshots/` 目录 | 核心功能需要 |
| `self-evolution` | 读写 `.learnings/` 目录、修改配置文件 | 自我改进需要读写学习记录 |
| `risk-skill-scanner` | 读取其他 Skill 的文件 | 安全审计需要读取目标文件 |
| `scan-all-risk-skill` | 遍历 `skills/` 目录 | 批量扫描需要遍历所有 Skill |

通用误报规则（参见 `risk-skill-scanner` 的 Common False Positives 章节）：
- Skill 核心功能所必需的外部 API 调用不算风险
- 带有明确退出条件的循环不算无限循环
- 已知安全用途的 hex/base64 字符串（如 SHA256 哈希、颜色值）不算混淆

### 4. 生成汇总报告

输出格式：

```
# 全量 Skill 风险扫描报告

**扫描时间**: YYYY-MM-DD HH:MM
**扫描范围**: skills/ 下共 N 个 Skill
**扫描框架**: risk-skill-scanner v1.0

## 汇总

| Skill | 风险级别 | 发现数 | 关键发现 |
|-------|---------|--------|---------|
| skill-a | ✅ Clean | 0 | — |
| skill-b | 🟡 MEDIUM | 2 | 外部 API 调用未配置化 |
| skill-c | 🔴 CRITICAL | 1 | 检测到数据上传到匿名服务 |

## 需要关注的发现

### [CRITICAL] skill-c
1. [CRITICAL] 文件 `scripts/sync.py:23` — 上传数据到 pastebin
   - 当前: `requests.post('https://pastebin.com/api/...')`
   - 问题: 数据外泄到匿名服务
   - 建议: 立即禁用此 Skill

### [HIGH] skill-d (如有)
...

## 结论

- CRITICAL: X 个（需立即处理）
- HIGH: X 个（需人工复查）
- MEDIUM: X 个（可接受但建议改进）
- Clean: X 个
```

## 注意事项

- 本 Skill 只负责扫描和生成报告，**不会**修改任何文件（HEARTBEAT.md、daily log 等）
- 后续动作（写入 HEARTBEAT 警告、记录到 daily log 等）由调用方（如 cron 编排层）决定
- 扫描结果的准确性取决于静态分析，无法保证检测到所有运行时行为
- 对于高风险 Skill，建议结合 `risk-skill-scanner` 进行人工深度审计
