#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup-browser.sh — 为 OpenClaw Agent 配置 headless 浏览器
#
# 可在安装时由 install.sh 调用，也可后续单独运行：
#   bash ~/.openclaw/workspace/scripts/setup-browser.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

info()  { echo -e "\033[34m[INFO]\033[0m $1"; }
ok()    { echo -e "\033[32m[OK]\033[0m   $1"; }
warn()  { echo -e "\033[33m[WARN]\033[0m $1"; }
fail()  { echo -e "\033[31m[FAIL]\033[0m $1"; }

echo ""
echo "🌐 OpenClaw Headless 浏览器配置"
echo "════════════════════════════════"
echo ""

# ── 前置检查 ──────────────────────────────────────────────────
if ! command -v openclaw &>/dev/null; then
    fail "openclaw 未安装，请先完成基础部署"
    exit 1
fi

# ── Step 1: 检测 / 安装 Chromium ─────────────────────────────
info "检测 Chromium..."
CHROMIUM_BIN=""
for bin in chromium-browser chromium google-chrome brave-browser microsoft-edge; do
    if command -v "$bin" &>/dev/null; then
        CHROMIUM_BIN="$bin"
        break
    fi
done

if [ -n "$CHROMIUM_BIN" ]; then
    ok "已检测到: $CHROMIUM_BIN"
else
    info "未检测到 Chromium，尝试安装..."
    if command -v apt &>/dev/null; then
        info "运行 sudo apt install -y chromium-browser（可能需要输入密码）..."
        sudo apt install -y chromium-browser 2>/dev/null && CHROMIUM_BIN="chromium-browser"
    elif command -v brew &>/dev/null; then
        info "运行 brew install --cask chromium..."
        brew install --cask chromium 2>/dev/null && CHROMIUM_BIN="chromium"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm chromium 2>/dev/null && CHROMIUM_BIN="chromium"
    fi

    if [ -z "$CHROMIUM_BIN" ]; then
        fail "Chromium 安装失败。请手动安装后重新运行本脚本。"
        echo "    Ubuntu/Debian: sudo apt install chromium-browser"
        echo "    macOS:         brew install --cask chromium"
        echo "    Arch:          sudo pacman -S chromium"
        exit 1
    fi
    ok "Chromium 安装完成: $CHROMIUM_BIN"
fi

# ── Step 2: 安装 Playwright ──────────────────────────────────
info "检测 Playwright..."
if [ -d "$HOME/.openclaw/node_modules/playwright" ]; then
    ok "Playwright 已安装"
else
    info "安装 Playwright（用于 snapshot/action，可能需要几分钟）..."
    if (cd "$HOME/.openclaw" && npm install playwright 2>/dev/null); then
        ok "Playwright 安装完成"
    else
        warn "Playwright 安装失败，browser snapshot/action 可能受限"
        warn "后续可手动安装: cd ~/.openclaw && npm install playwright"
    fi
fi

# ── Step 3: 写入 OpenClaw 配置 ───────────────────────────────
info "写入 browser 配置..."
openclaw config set browser.enabled true 2>/dev/null
openclaw config set browser.defaultProfile '"openclaw"' 2>/dev/null
openclaw config set browser.headless true 2>/dev/null
openclaw config set browser.noSandbox true 2>/dev/null
ok "browser 配置写入完成"

# ── Step 4: 重启 Gateway 并验证 ──────────────────────────────
info "重启 Gateway..."
if openclaw gateway restart &>/dev/null; then
    sleep 3
    ok "Gateway 已重启"
else
    warn "Gateway 重启失败，请手动执行: openclaw gateway restart"
fi

# 验证
info "验证浏览器..."
if openclaw browser start --profile openclaw &>/dev/null; then
    ok "浏览器启动成功"
else
    warn "浏览器启动验证失败，可稍后手动测试: openclaw browser snapshot"
fi

echo ""
echo "════════════════════════════════"
echo "✅ Headless 浏览器配置完成"
echo ""
echo "Agent 现在可以通过 browser 工具自主访问网页。"
echo "关闭浏览器: openclaw config set browser.enabled false && openclaw gateway restart"
echo ""
