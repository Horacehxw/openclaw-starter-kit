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
header "📋 Step 1/8 — 前置检查"

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

# ── OpenClaw Onboard 环境引导 ──────────────────────────────────
header "🚀 Step 2/8 — OpenClaw 环境引导"

ONBOARD_NEEDED=false
if [ -f "$WORKSPACE/SOUL.md" ] && [ -f "$WORKSPACE/IDENTITY.md" ]; then
    ok "检测到已完成 onboard（SOUL.md、IDENTITY.md 存在）"
else
    ONBOARD_NEEDED=true
    if ! command -v openclaw &>/dev/null; then
        warn "OpenClaw CLI 未安装，无法执行 onboard"
        warn "请先安装 OpenClaw 后重新运行本脚本"
        warn "继续安装 Starter Kit 文件（onboard 部分跳过）..."
        ONBOARD_NEEDED=false
    fi
fi

if [ "$ONBOARD_NEEDED" = true ]; then
    info "未检测到 OpenClaw 工作区（缺少 SOUL.md / IDENTITY.md）"
    info "需要先完成 OpenClaw 初始化 (onboard)"
    echo ""

    # --- API 提供商选择 ---
    echo "  请选择 API 提供商:"
    echo "    [1] Anthropic (官方 Claude API)"
    echo "    [2] 自定义 API 端点 (OpenRouter、Azure 等)"
    echo "    [3] Z.AI"
    echo ""
    read -p "  请输入选项 [1]: " auth_choice
    auth_choice="${auth_choice:-1}"

    ONBOARD_AUTH_ARGS=""
    case "$auth_choice" in
        1)
            # Anthropic 官方
            ONBOARD_AUTH_ARGS="--auth-choice apiKey"
            echo ""
            read -sp "  请输入 Anthropic API Key: " api_key
            echo ""
            if [ -z "$api_key" ]; then
                fail "API Key 不能为空"
                exit 1
            fi
            ONBOARD_AUTH_ARGS="$ONBOARD_AUTH_ARGS --anthropic-api-key $api_key"
            ;;
        2)
            # 自定义端点
            ONBOARD_AUTH_ARGS="--auth-choice custom-api-key"
            echo ""
            read -p "  请输入 API Base URL (例: https://openrouter.ai/api/v1): " custom_url
            if [ -z "$custom_url" ]; then
                fail "API Base URL 不能为空"
                exit 1
            fi
            read -sp "  请输入 API Key: " api_key
            echo ""
            if [ -z "$api_key" ]; then
                fail "API Key 不能为空"
                exit 1
            fi
            read -p "  请输入模型 ID [claude-sonnet-4-6]: " custom_model
            custom_model="${custom_model:-claude-sonnet-4-6}"
            read -p "  API 兼容类型 [openai]: " custom_compat
            custom_compat="${custom_compat:-openai}"
            ONBOARD_AUTH_ARGS="$ONBOARD_AUTH_ARGS --custom-base-url $custom_url --custom-api-key $api_key --custom-model-id $custom_model --custom-compatibility $custom_compat"
            ;;
        3)
            # Z.AI
            ONBOARD_AUTH_ARGS="--auth-choice zai-api-key"
            echo ""
            read -sp "  请输入 Z.AI API Key: " api_key
            echo ""
            if [ -z "$api_key" ]; then
                fail "API Key 不能为空"
                exit 1
            fi
            ONBOARD_AUTH_ARGS="$ONBOARD_AUTH_ARGS --zai-api-key $api_key"
            ;;
        *)
            fail "无效选项: $auth_choice"
            exit 1
            ;;
    esac

    # --- 安装为系统服务 ---
    echo ""
    read -p "  是否将 Gateway 安装为系统服务 (开机自启)? [Y/n] " install_daemon
    DAEMON_FLAG=""
    if [[ "$install_daemon" != "n" && "$install_daemon" != "N" ]]; then
        DAEMON_FLAG="--install-daemon"
    fi

    # --- 清理可能残留的旧 Gateway（避免端口冲突和 nameconflict）---
    if command -v openclaw &>/dev/null; then
        openclaw gateway stop 2>/dev/null || true
    fi

    # Linux/WSL: 停止 systemd 服务（避免 nameconflict）
    if [[ "$OS" != "macos" ]] && command -v systemctl &>/dev/null; then
        if systemctl --user is-active openclaw-gateway.service &>/dev/null; then
            warn "检测到运行中的 openclaw-gateway systemd 服务，正在停止..."
            systemctl --user stop openclaw-gateway 2>/dev/null || true
            sleep 2
        fi
    fi

    # 释放 18789 端口（兜底，lsof → ss → netstat 三级 fallback）
    STALE_PID=""
    if command -v lsof &>/dev/null; then
        STALE_PID=$(lsof -ti:18789 2>/dev/null)
    elif command -v ss &>/dev/null; then
        STALE_PID=$(ss -tlnp 2>/dev/null | grep ":18789 " | sed 's/.*pid=\([0-9]*\).*/\1/')
    elif command -v netstat &>/dev/null; then
        STALE_PID=$(netstat -tlnp 2>/dev/null | grep ":18789 " | awk '{print $NF}' | cut -d'/' -f1)
    fi
    if [ -n "$STALE_PID" ] && [ "$STALE_PID" != "-" ]; then
        warn "端口 18789 被占用 (PID: $STALE_PID)，尝试释放..."
        kill "$STALE_PID" 2>/dev/null || true
        sleep 2
    fi

    # --- 执行 onboard ---
    echo ""
    info "正在执行 OpenClaw 初始化..."
    info "（跳过消息渠道配对和技能安装，可稍后通过 openclaw onboard 补充配置）"
    echo ""

    # shellcheck disable=SC2086
    openclaw onboard \
        --non-interactive \
        --flow quickstart \
        $ONBOARD_AUTH_ARGS \
        --skip-channels \
        --skip-skills \
        --accept-risk \
        $DAEMON_FLAG \
        --workspace "$WORKSPACE" \
    && {
        ok "OpenClaw 初始化完成"
    } || {
        fail "OpenClaw 初始化失败"
        echo ""
        echo "  可能原因:"
        echo "    · API Key 无效或过期"
        echo "    · 网络连接问题"
        echo "    · OpenClaw CLI 版本过旧 (尝试: npm update -g openclaw)"
        echo ""
        echo "  你可以手动执行: openclaw onboard"
        echo "  完成后重新运行本安装脚本"
        exit 1
    }

    # 自定义 API 端点: 补充 contextWindow / maxTokens（onboard 默认值可能缺失）
    if [ "$auth_choice" = "2" ]; then
        OPENCLAW_JSON="$HOME/.openclaw/openclaw.json"
        if [ -f "$OPENCLAW_JSON" ]; then
            python3 -c "
import json
with open('$OPENCLAW_JSON') as f:
    cfg = json.load(f)
providers = cfg.get('models', {}).get('providers', {})
for pid, prov in providers.items():
    for m in prov.get('models', []):
        m['contextWindow'] = 200000
        m['maxTokens'] = 128000
with open('$OPENCLAW_JSON', 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
" && ok "模型参数: contextWindow=200000, maxTokens=128000" \
              || warn "模型参数配置失败，请手动编辑 openclaw.json"
        fi
    fi

    # 验证 + 显示 Dashboard URL
    if [ -f "$WORKSPACE/SOUL.md" ]; then
        ok "工作区文件验证通过 (SOUL.md 已创建)"
    else
        warn "onboard 已执行但未检测到 SOUL.md，可能需要手动检查"
    fi

    # 等待 Gateway 启动
    if [ -n "$DAEMON_FLAG" ]; then
        info "Gateway 服务启动中..."
        sleep 5
    fi

    # 显示带 token 的 Dashboard URL（最多重试 3 次）
    DASH_OK=false
    for i in 1 2 3; do
        DASH_OUTPUT=$(openclaw dashboard --no-open 2>/dev/null)
        if [ -n "$DASH_OUTPUT" ] && echo "$DASH_OUTPUT" | grep -q "http"; then
            echo ""
            ok "Gateway Dashboard 链接:"
            echo -e "    ${CYAN}${DASH_OUTPUT}${NC}"
            echo ""
            info "在浏览器中打开此链接即可访问 Agent 控制台"
            DASH_OK=true
            break
        fi
        sleep 3
    done
    if [ "$DASH_OK" = false ]; then
        warn "Dashboard URL 暂时不可用，请稍后运行: openclaw dashboard --no-open"
    fi
fi

# ── 备份已有工作区 ────────────────────────────────────────────
header "📦 Step 3/8 — 备份检查"

if [ -d "$WORKSPACE" ] && [ "$(ls -A "$WORKSPACE" 2>/dev/null)" ]; then
    BACKUP="${WORKSPACE}.backup.$(date +%Y%m%d%H%M%S)"
    warn "发现已有工作区，备份到: $BACKUP"
    cp -r "$WORKSPACE" "$BACKUP"
    ok "备份完成"
else
    info "工作区为空或不存在，无需备份"
fi

# ── 创建目录结构 ──────────────────────────────────────────────
header "📁 Step 4/8 — 创建目录结构"

mkdir -p "$WORKSPACE"/{memory,skills,snapshots,.learnings,scripts}
ok "目录结构就绪"

# ── 复制配置文件 ──────────────────────────────────────────────
header "📝 Step 5/8 — 复制配置文件"

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
    ok "skills/ (self-evolution, daily-snapshot, risk-skill-scanner, scan-all-risk-skill)"
fi

# .learnings
if [ -d "$SOURCE_DIR/.learnings" ]; then
    cp -r "$SOURCE_DIR/.learnings/"* "$WORKSPACE/.learnings/" 2>/dev/null
    ok ".learnings/ (LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md)"
fi

# Scripts
for script in setup-cron.sh snapshot.sh snapshot.ps1 setup-browser.sh setup-browser.ps1; do
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
header "🔧 Step 6/8 — ClawdHub CLI"

if command -v clawdhub &>/dev/null; then
    ok "ClawdHub CLI 已安装"
else
    info "正在安装 ClawdHub CLI..."
    npm i -g clawdhub 2>/dev/null && ok "ClawdHub CLI 安装完成" \
        || warn "安装失败，请手动执行: npm i -g clawdhub"
fi

# ── 工具权限配置 ──────────────────────────────────────────────
header "🔑 Step 7/8 — 工具权限"

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
header "⏰ Step 8/8 — 定时任务"

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
echo "     2. 获取 Dashboard 链接:  openclaw dashboard --no-open"
echo "     3. 配置定时任务:         bash $WORKSPACE/scripts/setup-cron.sh"
echo "     4. 在 IM 中发送:         「让我们来设置一下吧」"
echo "     5. 按照引导完成初始化 (约 2 分钟)"
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
