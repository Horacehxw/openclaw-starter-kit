#!/bin/bash
# ============================================================
# snapshot.sh — 确定性配置快照脚本
# 用法:   bash snapshot.sh [workspace_path]
# 功能:   复制核心配置 → diff → 生成变更摘要 → 清理旧快照
# 设计:   所有文件操作是确定性的，不依赖 LLM
# ============================================================

set -e

WORKSPACE="${1:-$HOME/.openclaw/workspace}"
TODAY=$(date +%Y-%m-%d)
NOW=$(date '+%Y-%m-%d %H:%M:%S')
SNAP_DIR="$WORKSPACE/snapshots/$TODAY"
CHANGELOG="$SNAP_DIR/CHANGELOG.md"

# ── 核心配置文件列表 ──────────────────────────────────────────
CORE_FILES=(
    SOUL.md
    IDENTITY.md
    AGENTS.md
    USER.md
    TOOLS.md
    MEMORY.md
    HEARTBEAT.md
    BOOT.md
    BOOTSTRAP.md
)

# ── 辅助函数 ──────────────────────────────────────────────────
log() { echo "[snapshot] $(date '+%H:%M:%S') $1"; }

# ── 1. 创建快照目录 ──────────────────────────────────────────
log "创建快照目录: $SNAP_DIR"
mkdir -p "$SNAP_DIR/skills"

# ── 2. 复制核心配置文件 ──────────────────────────────────────
COPIED=0
MISSING=0
for f in "${CORE_FILES[@]}"; do
    src="$WORKSPACE/$f"
    if [ -f "$src" ]; then
        cp "$src" "$SNAP_DIR/$f"
        COPIED=$((COPIED + 1))
    else
        MISSING=$((MISSING + 1))
    fi
done
log "核心文件: 复制 $COPIED 个, 缺失 $MISSING 个"

# ── 3. 复制 Skills ───────────────────────────────────────────
if [ -d "$WORKSPACE/skills" ]; then
    cp -r "$WORKSPACE/skills/"* "$SNAP_DIR/skills/" 2>/dev/null || true
    SKILL_COUNT=$(find "$SNAP_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l)
    log "Skills: 复制 $SKILL_COUNT 个"
else
    SKILL_COUNT=0
fi

# ── 4. 复制 .learnings ──────────────────────────────────────
if [ -d "$WORKSPACE/.learnings" ]; then
    mkdir -p "$SNAP_DIR/.learnings"
    cp "$WORKSPACE/.learnings/"*.md "$SNAP_DIR/.learnings/" 2>/dev/null || true
fi

# ── 5. 查找上一次快照并 diff ─────────────────────────────────
PREV_SNAP=""
DIFF_SUMMARY=""
CHANGED_FILES=()

# 按日期倒序查找最近一个非今天的快照
for d in $(ls -d "$WORKSPACE/snapshots/"*/  2>/dev/null | sort -r); do
    dir_name=$(basename "$d")
    if [ "$dir_name" != "$TODAY" ] && [ -f "$d/SOUL.md" ]; then
        PREV_SNAP="$d"
        break
    fi
done

if [ -n "$PREV_SNAP" ]; then
    PREV_DATE=$(basename "$PREV_SNAP")
    log "对比上次快照: $PREV_DATE"

    for f in "${CORE_FILES[@]}"; do
        old="$PREV_SNAP/$f"
        new="$SNAP_DIR/$f"
        if [ -f "$old" ] && [ -f "$new" ]; then
            if ! diff -q "$old" "$new" &>/dev/null; then
                CHANGED_FILES+=("$f")
            fi
        elif [ ! -f "$old" ] && [ -f "$new" ]; then
            CHANGED_FILES+=("$f (新增)")
        elif [ -f "$old" ] && [ ! -f "$new" ]; then
            CHANGED_FILES+=("$f (已删除)")
        fi
    done
else
    PREV_DATE="(无)"
    log "没有找到历史快照，这是首次快照"
fi

# ── 6. 生成 CHANGELOG.md ────────────────────────────────────
log "生成 CHANGELOG.md"

cat > "$CHANGELOG" <<EOF
# 快照: $TODAY

**快照时间**: $NOW
**上次快照**: $PREV_DATE
**核心文件**: $COPIED 个已复制
**Skills**: $SKILL_COUNT 个

## 文件变更

EOF

if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    if [ -z "$PREV_SNAP" ]; then
        echo "首次快照，无历史对比。" >> "$CHANGELOG"
    else
        echo "无变更（所有文件与上次快照一致）。" >> "$CHANGELOG"
    fi
else
    echo "以下文件自 $PREV_DATE 以来有变更：" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    for f in "${CHANGED_FILES[@]}"; do
        echo "- \`$f\`" >> "$CHANGELOG"
    done

    # 为每个变更文件生成简要 diff 统计
    echo "" >> "$CHANGELOG"
    echo "### Diff 统计" >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
    echo '```' >> "$CHANGELOG"
    for f in "${CHANGED_FILES[@]}"; do
        # 去掉 "(新增)" "(已删除)" 后缀
        clean_f=$(echo "$f" | sed 's/ (.*)//')
        old="$PREV_SNAP/$clean_f"
        new="$SNAP_DIR/$clean_f"
        if [ -f "$old" ] && [ -f "$new" ]; then
            ADDED=$(diff "$old" "$new" | grep "^>" | wc -l)
            REMOVED=$(diff "$old" "$new" | grep "^<" | wc -l)
            echo "$clean_f: +$ADDED -$REMOVED 行" >> "$CHANGELOG"
        else
            echo "$f" >> "$CHANGELOG"
        fi
    done
    echo '```' >> "$CHANGELOG"
fi

# Agent 稍后可追加描述性总结到此处
echo "" >> "$CHANGELOG"
echo "---" >> "$CHANGELOG"
echo "_快照由 snapshot.sh 自动生成。Agent 可在下方追加描述性总结。_" >> "$CHANGELOG"

# ── 7. 清理旧快照（>30天，保留每月1日） ─────────────────────
DELETED_COUNT=0
CUTOFF=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "")

if [ -n "$CUTOFF" ]; then
    log "清理 $CUTOFF 之前的快照 (保留每月1日)"
    for d in $(ls -d "$WORKSPACE/snapshots/"*/ 2>/dev/null); do
        dir_name=$(basename "$d")
        # 跳过非日期格式的目录
        if [[ ! "$dir_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            continue
        fi
        # 保留每月 1 日的快照
        if [[ "$dir_name" == *"-01" ]]; then
            continue
        fi
        # 删除超过 30 天的
        if [[ "$dir_name" < "$CUTOFF" ]]; then
            rm -rf "$d"
            DELETED_COUNT=$((DELETED_COUNT + 1))
        fi
    done
    if [ $DELETED_COUNT -gt 0 ]; then
        log "清理了 $DELETED_COUNT 个旧快照"
    fi
else
    log "跳过清理 (无法计算日期，请手动清理旧快照)"
fi

# ── 8. 写入今日 daily log ────────────────────────────────────
DAILY_LOG="$WORKSPACE/memory/$TODAY.md"
if [ -f "$DAILY_LOG" ]; then
    echo "" >> "$DAILY_LOG"
    echo "## 配置快照" >> "$DAILY_LOG"
    echo "" >> "$DAILY_LOG"
    echo "- 时间: $NOW" >> "$DAILY_LOG"
    echo "- 文件: $COPIED 个核心 + $SKILL_COUNT 个 Skill" >> "$DAILY_LOG"
    if [ ${#CHANGED_FILES[@]} -gt 0 ]; then
        echo "- 变更: ${CHANGED_FILES[*]}" >> "$DAILY_LOG"
    else
        echo "- 变更: 无" >> "$DAILY_LOG"
    fi
    if [ $DELETED_COUNT -gt 0 ]; then
        echo "- 清理: $DELETED_COUNT 个旧快照" >> "$DAILY_LOG"
    fi
fi

# ── 完成 ─────────────────────────────────────────────────────
log "✅ 快照完成: $SNAP_DIR"
log "   CHANGELOG: $CHANGELOG"
echo ""
