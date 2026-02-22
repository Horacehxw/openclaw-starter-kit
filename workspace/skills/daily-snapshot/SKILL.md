---
name: daily-snapshot
description: "每日配置快照：确定性脚本处理文件复制/删除，Agent 负责生成描述性总结"
metadata:
  openclaw:
    emoji: "📸"
    requires:
      bins_any: [["bash", "diff", "date"], ["powershell"]]
---

# Daily Snapshot — 每日配置快照

## 设计原则

文件复制、diff、清理等操作由快照脚本**确定性执行**，不依赖 LLM 判断。
Agent 的职责仅限于：触发脚本 → 阅读 CHANGELOG → 追加描述性总结。

## 快照脚本

| 平台 | 脚本 |
|------|------|
| Linux / WSL2 / macOS | `scripts/snapshot.sh` |
| Windows (PowerShell) | `scripts/snapshot.ps1` |

两个脚本功能完全对等，自动完成：
1. 创建 `snapshots/YYYY-MM-DD/` 目录
2. 复制 9 个核心 .md 文件 + `skills/` + `.learnings/`
3. 与上一次快照做 diff，统计变更行数
4. 生成 `CHANGELOG.md`（含变更文件列表和 diff 统计）
5. 清理 >30 天的旧快照（保留每月 1 日）
6. 在今日 daily log 记录快照完成

## 触发方式

### 自动触发（cron）

已由 `setup-cron.sh` 配置为每天 02:00 isolated session 运行。

### 手动触发

用户在 IM 中说：
- "做一次配置快照"
- "备份当前配置"

### 执行流程

```
1. 运行脚本（根据平台选择）:
   Linux/WSL/macOS:  bash ~/.openclaw/workspace/scripts/snapshot.sh
   Windows:          powershell -ExecutionPolicy Bypass -File ~/.openclaw/workspace/scripts/snapshot.ps1

2. 阅读生成的 CHANGELOG.md:
   cat snapshots/YYYY-MM-DD/CHANGELOG.md

3. 在 CHANGELOG.md 末尾追加一段中文描述:
   - 简要说明今日主要变更的原因和背景
   - 如果无变更，写"今日配置无变动"

4. 向用户确认（如非 cron 触发）:
   "📸 快照完成！保存在 snapshots/YYYY-MM-DD/，共 X 个文件。"
```

## 回滚

用户说"恢复到 YYYY-MM-DD 的配置"时：

```
1. 确认快照存在:
   ls snapshots/YYYY-MM-DD/

2. 列出将被覆盖的文件，请求用户确认

3. 确认后，逐个复制回工作区根目录:
   cp snapshots/YYYY-MM-DD/SOUL.md ./SOUL.md
   cp snapshots/YYYY-MM-DD/IDENTITY.md ./IDENTITY.md
   ...（所有核心文件）

4. 回滚后立即做一次新快照（记录回滚事件）
```

## 保留策略

| 快照年龄 | 策略 |
|----------|------|
| ≤ 30 天 | 全部保留 |
| > 30 天 + 每月 1 日 | 永久保留 |
| > 30 天 + 非月初 | 自动删除 |

## 快照目录结构

```
snapshots/
├── 2026-02-20/
│   ├── CHANGELOG.md
│   ├── SOUL.md
│   ├── IDENTITY.md
│   ├── AGENTS.md
│   ├── ...
│   ├── skills/
│   └── .learnings/
├── 2026-02-21/
│   └── ...
└── 2026-02-01/     ← 月初快照永久保留
    └── ...
```
