#!/bin/bash
# ============================================================
# setup-cron.sh — 配置 OpenClaw 定时任务
# 用法:   bash scripts/setup-cron.sh
# ============================================================

set -e

echo "🦞 OpenClaw 定时任务配置"
echo "================================"

# 检查 openclaw 是否可用
if ! command -v openclaw &>/dev/null; then
    echo "❌ 未检测到 openclaw 命令，请先安装。"
    exit 1
fi

# 检查 Gateway 是否在运行且已配对
if ! openclaw gateway status &>/dev/null; then
    echo "❌ Gateway 未连接（未运行或 CLI 被拒绝）"
    echo ""
    echo "请依次尝试："
    echo ""
    echo "  1. 确认 Gateway 在运行:"
    echo "     systemctl --user status openclaw-gateway"
    echo "     # 或手动启动: openclaw gateway start"
    echo ""
    echo "  2. 如果报 'pairing required'（2026.2.19 已知问题）:"
    echo "     systemctl --user stop openclaw-gateway"
    echo "     rm -rf ~/.openclaw/devices"
    echo "     systemctl --user start openclaw-gateway"
    echo "     sleep 5"
    echo ""
    echo "  3. 修复后重新运行:  bash $0"
    exit 1
fi

# 获取 workspace 路径 (脚本所在目录的上一级)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

SUCCESS=0
FAIL=0

# ── 1. 每日配置快照（凌晨 2:00）────────────────────────────
echo ""
echo "📸 [1/3] 每日快照 (02:00)..."
if openclaw cron add \
    --name "daily-snapshot" \
    --cron "0 2 * * *" \
    --session isolated \
    --message "运行配置快照脚本: bash $WORKSPACE/scripts/snapshot.sh $WORKSPACE 然后阅读生成的 CHANGELOG.md，在末尾追加一段简要的中文描述总结今日主要变更。" \
    2>/dev/null; then
    echo "  ✅ daily-snapshot 已创建"
    SUCCESS=$((SUCCESS + 1))
else
    echo "  ⚠️  daily-snapshot 创建失败 (可能已存在，用 openclaw cron list 检查)"
    FAIL=$((FAIL + 1))
fi

# ── 2. 每日记忆整理（晚上 23:00）────────────────────────────
echo ""
echo "🧠 [2/3] 每日记忆整理 (23:00)..."
if openclaw cron add \
    --name "daily-memory-review" \
    --cron "0 23 * * *" \
    --session isolated \
    --message "执行每日记忆整理和自省：1) 回顾今日 daily log 2) 将重要信息整理到 MEMORY.md 3) 检查 USER.md 是否需要更新 4) 回顾 .learnings/ 中的新条目 5) 评估 SOUL.md 和 IDENTITY.md 是否需要微调 6) 记录改进计划到明日 daily log" \
    2>/dev/null; then
    echo "  ✅ daily-memory-review 已创建"
    SUCCESS=$((SUCCESS + 1))
else
    echo "  ⚠️  daily-memory-review 创建失败"
    FAIL=$((FAIL + 1))
fi

# ── 3. 每周 Skill 巡检（周日 10:00）─────────────────────────
echo ""
echo "🔧 [3/3] 每周 Skill 巡检 (周日 10:00)..."
if openclaw cron add \
    --name "weekly-skill-review" \
    --cron "0 10 * * 0" \
    --session isolated \
    --message "执行每周 Skill 巡检：1) clawdhub update --all 更新已安装 Skills 2) 根据本周的 .learnings/ 记录搜索 ClawdHub 有无相关新 Skill 3) 汇总巡检结果写入 daily log 4) 如有推荐安装的新 Skill 在下次用户活跃时提出建议" \
    2>/dev/null; then
    echo "  ✅ weekly-skill-review 已创建"
    SUCCESS=$((SUCCESS + 1))
else
    echo "  ⚠️  weekly-skill-review 创建失败"
    FAIL=$((FAIL + 1))
fi

# ── 完成 ─────────────────────────────────────────────────────
echo ""
echo "================================"
if [ $FAIL -eq 0 ]; then
    echo "✅ 全部 $SUCCESS 个定时任务配置成功！"
else
    echo "⚠️  成功 $SUCCESS 个，失败 $FAIL 个"
    if [ $SUCCESS -eq 0 ]; then
        echo ""
        echo "所有任务都失败了，请检查："
        echo "  1. Gateway 是否在运行:  openclaw gateway status"
        echo "  2. 是否已完成配对:      openclaw onboard"
        echo "  3. 修复后重新运行:      bash $0"
    fi
fi
echo ""
echo "验证:"
echo "  openclaw cron list"
echo ""
echo "手动触发测试:"
echo "  openclaw cron run daily-snapshot"
echo "  openclaw cron run daily-memory-review"
echo ""
echo "单独测试快照脚本 (不经过 cron):"
echo "  bash $WORKSPACE/scripts/snapshot.sh"
echo ""
