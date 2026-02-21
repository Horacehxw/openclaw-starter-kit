---
name: self-evolution
description: "自主学习和改进能力。当遇到以下情况时使用：(1) 命令或操作意外失败，(2) 用户纠正了我的错误，(3) 发现更好的方法来完成重复任务，(4) 外部 API 或工具失败，(5) 发现知识过时。同时在执行重大任务前回顾已有的学习记录。"
---

# 自主进化 Skill

## 概述

此 Skill 让 Agent 具备自主学习和改进的能力。通过记录学习、错误和纠正，实现持续改进。

## 目录结构

```
.learnings/
├── LEARNINGS.md      # 学习记录
├── ERRORS.md         # 错误记录
└── FEATURE_REQUESTS.md  # 功能需求记录
```

## 记录格式

### 学习记录 (.learnings/LEARNINGS.md)

```markdown
## [日期] - [类别] - [标题]

**触发**: 什么引发了这次学习
**发现**: 学到了什么
**应用**: 如何应用到未来的工作中
**状态**: open | resolved | promoted
**优先级**: P1(关键) | P2(重要) | P3(一般)
```

### 错误记录 (.learnings/ERRORS.md)

```markdown
## [日期] - [错误类型] - [标题]

**命令/操作**: 执行了什么
**错误信息**: 具体错误
**根因**: 为什么出错
**解决**: 如何修复
**预防**: 如何避免再犯
**状态**: open | resolved | wont_fix
```

## 触发条件

| 情况 | 动作 |
|------|------|
| 命令/操作失败 | 记录到 ERRORS.md |
| 用户纠正我 | 记录到 LEARNINGS.md，类别: correction |
| 用户要求缺失功能 | 记录到 FEATURE_REQUESTS.md |
| API/外部工具失败 | 记录到 ERRORS.md |
| 知识过时 | 记录到 LEARNINGS.md，类别: knowledge_gap |
| 发现更好方法 | 记录到 LEARNINGS.md，类别: best_practice |

## 知识晋升

当一个学习记录具有广泛适用性时，将其晋升到项目记忆：

| 目标文件 | 适合内容 |
|----------|----------|
| AGENTS.md | 工作流改进、工具使用模式 |
| SOUL.md | 行为准则、沟通风格改进 |
| TOOLS.md | 工具注意事项、环境配置 |
| MEMORY.md | 持久性知识、用户偏好 |

## 每日自省流程

在每日记忆整理 cron 任务中，同时执行：

1. 回顾今日的 LEARNINGS.md 和 ERRORS.md 新条目
2. 标记已解决的条目为 `resolved`
3. 评估是否有条目适合晋升
4. 检查 ClawdHub 是否有新的相关 Skill
5. 将改进计划写入明日 daily log

## ClawdHub 集成

当遇到自身无法解决的任务时：

```bash
# 搜索相关 Skill
clawdhub search "描述你需要的能力"

# 如找到合适的 Skill，告知用户后安装
clawdhub install <skill-name>

# 安装后更新 TOOLS.md 中的 Skill 列表
```

**规则**: 安装任何新 Skill 前必须告知用户并获得确认。
