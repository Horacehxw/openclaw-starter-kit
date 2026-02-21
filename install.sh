#!/bin/bash
# ============================================================
# install.sh — OpenClaw Starter Kit 安装脚本
# 适用于: Linux / WSL2 / macOS
# 用法:   bash install.sh [workspace_path]
# ============================================================

set -e

# ── 颜色输出 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${CYAN}ℹ ${NC}$1"; }
ok()    { echo -e "${GREEN}✅${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠️ ${NC}$1"; }
fail()  { echo -e "${RED}❌${NC} $1"; }
header(){ echo -e "\n${BOLD}$1${NC}"; }

# ── 检测操作系统 ──────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

echo ""
echo "🦞 ═══════════════════════════════════════════════════════"
echo "   OpenClaw Starter Kit — 一键安装"
echo "   系统: $OS | $(uname -m)"
echo "   时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🦞 ═══════════════════════════════════════════════════════"
echo ""

# ── 确定路径 ──────────────────────────────────────────────────
DEFAULT_WORKSPACE="$HOME/.openclaw/workspace"
WORKSPACE="${1:-$DEFAULT_WORKSPACE}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/workspace"

info "目标工作区: $WORKSPACE"

# ── 前置检查 ──────────────────────────────────────────────────
header "📋 Step 1/7 — 前置检查"

# Node.js
if command -v node &>/dev/null; then
    ok "Node.js $(node -v)"
else
    fail "未检测到 Node.js"
    echo "    安装方法:"
    case $OS in
        macos)
            echo "      brew install node"
            echo "    或 https://nodejs.org 下载安装包" ;;
        wsl|linux)
            echo "      curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -"
            echo "      sudo apt-get install -y nodejs" ;;
    esac
    exit 1
fi

# npm
if command -v npm &>/dev/null; then
    ok "npm $(npm -v)"
else
    fail "未检测到 npm (通常随 Node.js 一起安装)"
    exit 1
fi

# OpenClaw
if command -v openclaw &>/dev/null; then
    OC_VER=$(openclaw --version 2>/dev/null || echo "version unknown")
    ok "OpenClaw ($OC_VER)"
else
    warn "未检测到 openclaw 命令"
    read -p "    是否现在安装 OpenClaw? [Y/n] " install_oc
    if [[ "$install_oc" != "n" && "$install_oc" != "N" ]]; then
        info "正在安装 OpenClaw..."
        npm install -g openclaw 2>/dev/null || {
            fail "自动安装失败，请手动安装: npm install -g openclaw"
            fail "或参考: https://docs.openclaw.ai/install"
            exit 1
        }
        ok "OpenClaw 安装完成"
    else
        warn "跳过。部分功能(cron)需要 openclaw CLI，后续可手动安装。"
    fi
fi

# git (可选)
if command -v git &>/dev/null; then
    ok "Git $(git --version | awk '{print $3}')"
else
    warn "Git 未安装 (可选，推荐用于快照版本管理)"
fi

# ── 备份已有工作区 ────────────────────────────────────────────
header "📦 Step 2/7 — 备份检查"

if [ -d "$WORKSPACE" ] && [ "$(ls -A "$WORKSPACE" 2>/dev/null)" ]; then
    BACKUP="${WORKSPACE}.backup.$(date +%Y%m%d%H%M%S)"
    warn "发现已有工作区，备份到: $BACKUP"
    cp -r "$WORKSPACE" "$BACKUP"
    ok "备份完成"
else
    info "工作区为空或不存在，无需备份"
fi

# ── 创建目录结构 ──────────────────────────────────────────────
header "📁 Step 3/7 — 创建目录结构"

mkdir -p "$WORKSPACE"/{memory,skills,snapshots,.learnings,scripts}
ok "目录结构就绪"

# ── 复制配置文件 ──────────────────────────────────────────────
header "📝 Step 4/7 — 复制配置文件"

# --- 策略 1: 追加补丁（保留 OpenClaw 默认内容，追加扩展）---
for patchfile in AGENTS TOOLS; do
    PATCH_SRC="$SOURCE_DIR/patches/${patchfile}.patch.md"
    TARGET="$WORKSPACE/${patchfile}.md"
    if [ -f "$PATCH_SRC" ]; then
        if [ -f "$TARGET" ]; then
            # 检查是否已经追加过（避免重复）
            if grep -q "Starter Kit 扩展" "$TARGET" 2>/dev/null; then
                info "${patchfile}.md 已包含 Starter Kit 扩展，跳过"
            else
                cat "$PATCH_SRC" >> "$TARGET"
                ok "${patchfile}.md ← 追加扩展（保留默认内容）"
            fi
        else
            warn "${patchfile}.md 不存在。请先运行 openclaw onboard 生成默认文件"
        fi
    fi
done

# --- 策略 2: 仅创建新文件（默认没有的文件）---
for newfile in BOOT.md MEMORY.md; do
    if [ ! -f "$WORKSPACE/$newfile" ]; then
        if [ -f "$SOURCE_DIR/$newfile" ]; then
            cp "$SOURCE_DIR/$newfile" "$WORKSPACE/$newfile"
            ok "$newfile（新建）"
        fi
    else
        info "$newfile 已存在，跳过"
    fi
done

# Skills
if [ -d "$SOURCE_DIR/skills" ]; then
    cp -r "$SOURCE_DIR/skills/"* "$WORKSPACE/skills/" 2>/dev/null
    ok "skills/ (self-evolution, daily-snapshot)"
fi

# .learnings
if [ -d "$SOURCE_DIR/.learnings" ]; then
    cp -r "$SOURCE_DIR/.learnings/"* "$WORKSPACE/.learnings/" 2>/dev/null
    ok ".learnings/ (LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md)"
fi

# Scripts
for script in setup-cron.sh snapshot.sh setup-browser.sh; do
    if [ -f "$SOURCE_DIR/scripts/$script" ]; then
        cp "$SOURCE_DIR/scripts/$script" "$WORKSPACE/scripts/$script"
        chmod +x "$WORKSPACE/scripts/$script"
        ok "scripts/$script"
    fi
done

# Daily log
if [ ! -f "$WORKSPACE/memory/$(date +%Y-%m-%d).md" ]; then
    cat > "$WORKSPACE/memory/$(date +%Y-%m-%d).md" <<EOF
# $(date +%Y-%m-%d) — 每日活动日志

## 系统事件

- OpenClaw Starter Kit 初始化完成 ($(date '+%H:%M'))
- 操作系统: $OS $(uname -m)
EOF
    ok "memory/$(date +%Y-%m-%d).md"
fi

# ── 安装 ClawdHub CLI ─────────────────────────────────────────
header "🔧 Step 5/7 — ClawdHub CLI"

if command -v clawdhub &>/dev/null; then
    ok "ClawdHub CLI 已安装"
else
    info "正在安装 ClawdHub CLI..."
    npm i -g clawdhub 2>/dev/null && ok "ClawdHub CLI 安装完成" \
        || warn "安装失败，请手动执行: npm i -g clawdhub"
fi

# ── 工具权限配置 ──────────────────────────────────────────────
header "🔑 Step 6/7 — 工具权限"

if command -v openclaw &>/dev/null; then
    read -p "是否配置工具权限（推荐首次使用）? [Y/n] " setup_tools
    if [[ "$setup_tools" != "n" && "$setup_tools" != "N" ]]; then
        # Tools: 开启全部核心能力
        info "配置工具策略 (full profile + 安全限制)..."
        openclaw config set tools.profile '"full"' 2>/dev/null \
            && ok "tools.profile = full" \
            || warn "tools.profile 设置失败"
        openclaw config set tools.deny '["sessions_spawn", "sessions_send"]' 2>/dev/null \
            && ok "tools.deny = [sessions_spawn, sessions_send]" \
            || warn "tools.deny 设置失败"
        openclaw config set tools.fs.workspaceOnly true 2>/dev/null \
            && ok "tools.fs.workspaceOnly = true (文件操作限 workspace)" \
            || warn "tools.fs.workspaceOnly 设置失败"
        openclaw config set tools.elevated.enabled false 2>/dev/null \
            && ok "tools.elevated = 关闭" \
            || warn "tools.elevated 设置失败"

        # Browser: headless Chromium (可选，独立脚本)
        echo ""
        info "Headless 浏览器让 Agent 可自主访问和操作网页（点击、填表、截图等）。"
        info "需要下载 Chromium + Playwright，可能耗时较长（3-10 分钟）。"
        info "跳过后 Agent 仍可用 web_fetch 读取网页内容（纯 HTTP，不执行 JS）。"
        read -p "是否现在配置 headless 浏览器? [y/N] " setup_browser
        if [[ "$setup_browser" == "y" || "$setup_browser" == "Y" ]]; then
            BROWSER_SCRIPT="$WORKSPACE/scripts/setup-browser.sh"
            if [ -f "$BROWSER_SCRIPT" ]; then
                bash "$BROWSER_SCRIPT"
            else
                warn "setup-browser.sh 未找到，请手动运行"
            fi
        else
            info "跳过。后续可单独运行:"
            echo "    bash ~/.openclaw/workspace/scripts/setup-browser.sh"
        fi

        # Exec Approvals: allowlist + on-miss IM 询问
        APPROVALS_FILE="$HOME/.openclaw/exec-approvals.json"
        APPROVALS_SRC="$SOURCE_DIR/exec-approvals.json"
        if [ -f "$APPROVALS_SRC" ]; then
            if [ -f "$APPROVALS_FILE" ]; then
                # 检查是否是空配置（只有 socket 和空 defaults/agents）
                HAS_ALLOWLIST=$(grep -c "allowlist" "$APPROVALS_FILE" 2>/dev/null || echo 0)
                if [ "$HAS_ALLOWLIST" -gt 0 ]; then
                    info "exec-approvals.json 已有自定义配置，跳过覆盖"
                else
                    # 保留 socket 信息，合并 allowlist 模板
                    SOCKET_PATH=$(python3 -c "import json; d=json.load(open('$APPROVALS_FILE')); print(d.get('socket',{}).get('path',''))" 2>/dev/null)
                    SOCKET_TOKEN=$(python3 -c "import json; d=json.load(open('$APPROVALS_FILE')); print(d.get('socket',{}).get('token',''))" 2>/dev/null)
                    cp "$APPROVALS_FILE" "${APPROVALS_FILE}.bak"
                    cp "$APPROVALS_SRC" "$APPROVALS_FILE"
                    # 回写 socket 信息
                    if [ -n "$SOCKET_PATH" ] && [ -n "$SOCKET_TOKEN" ]; then
                        python3 -c "
import json
with open('$APPROVALS_FILE') as f: d = json.load(f)
d['socket'] = {'path': '$SOCKET_PATH', 'token': '$SOCKET_TOKEN'}
with open('$APPROVALS_FILE', 'w') as f: json.dump(d, f, indent=2)
" 2>/dev/null
                    fi
                    ok "exec-approvals.json (allowlist 模式，已保留 socket 配置)"
                fi
            else
                cp "$APPROVALS_SRC" "$APPROVALS_FILE"
                ok "exec-approvals.json (新建)"
            fi
        fi

        echo ""
        info "工具权限策略:"
        echo "    ✅ 只读命令 (ls/cat/grep/find...)  → 自动放行"
        echo "    ✅ 文件操作 (mkdir/cp/mv...)        → 自动放行"
        echo "    ✅ 开发工具 (git/python/node/npm...) → 自动放行"
        echo "    ✅ 浏览器 (headless Chromium)       → Agent 可自主访问网页"
        echo "    ⚠️  rm/sudo/apt/kill 等             → IM 询问"
        echo "    🚫 sessions_spawn/send              → 禁止"
    else
        info "跳过。后续可手动配置，参考 TUTORIAL.md"
    fi
else
    warn "OpenClaw 未安装，跳过工具权限配置"
fi

# ── 配置定时任务 ──────────────────────────────────────────────
header "⏰ Step 7/7 — 定时任务"

if command -v openclaw &>/dev/null; then
    # 检查 Gateway 是否在运行且已配对
    GW_OK=false
    if openclaw gateway status &>/dev/null; then
        GW_OK=true
    fi

    if [ "$GW_OK" = true ]; then
        read -p "是否现在配置定时任务? [y/N] " setup_cron
        if [[ "$setup_cron" == "y" || "$setup_cron" == "Y" ]]; then
            bash "$WORKSPACE/scripts/setup-cron.sh"
        else
            info "跳过。后续运行: bash $WORKSPACE/scripts/setup-cron.sh"
        fi
    else
        warn "Gateway 未连接（可能未运行，或存在设备配对问题）"
        echo ""
        echo "  请确认："
        echo "    1. Gateway 已启动:  systemctl --user status openclaw-gateway"
        echo "    2. 如果报 'pairing required': 见 FAQ 或运行:"
        echo "       systemctl --user stop openclaw-gateway"
        echo "       rm -rf ~/.openclaw/devices && systemctl --user start openclaw-gateway"
        echo "    3. 然后运行: bash $WORKSPACE/scripts/setup-cron.sh"
    fi
else
    warn "OpenClaw 未安装，跳过 cron 配置"
fi

# ── 完成 ──────────────────────────────────────────────────────
echo ""
echo "🦞 ═══════════════════════════════════════════════════════"
echo "   ✅ 安装完成！"
echo "🦞 ═══════════════════════════════════════════════════════"
echo ""
echo "  📁 工作区: $WORKSPACE"
echo ""
echo "  📋 下一步:"
echo "     1. 确认 Gateway 在运行:  systemctl --user status openclaw-gateway"
echo "     2. 配置定时任务:         bash $WORKSPACE/scripts/setup-cron.sh"
echo "     3. 在 IM 中发送:         「让我们来设置一下吧」"
echo "     4. 按照引导完成初始化 (约 2 分钟)"
echo ""

case $OS in
    wsl)
        echo "  💡 WSL 提示:"
        echo "     · Gateway 在 WSL 内运行即可"
        echo "     · 如需 Windows 侧访问，配置 WSL 端口转发"
        echo "     · 日志路径: ~/.openclaw/logs/"
        ;;
    macos)
        echo "  💡 macOS 提示:"
        echo "     · 推荐用菜单栏应用管理 Gateway"
        echo "     · 首次运行可能需要授权辅助功能权限"
        ;;
    linux)
        echo "  💡 Linux 提示:"
        echo "     · 服务器推荐用 systemd 管理 Gateway (见下方)"
        echo "     · 远程访问推荐配置 Tailscale"
        ;;
esac
echo ""
echo "  📖 完整教程: TUTORIAL.md"
echo ""
