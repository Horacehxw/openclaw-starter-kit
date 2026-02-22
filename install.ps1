# ============================================================
# install.ps1 — OpenClaw Starter Kit 安装脚本 (Windows 原生)
# 适用于: Windows 10/11 (PowerShell 5.1+)
# 用法:   powershell -ExecutionPolicy Bypass -File install.ps1
#    或:  右键 → 使用 PowerShell 运行
# ============================================================

param(
    [string]$WorkspacePath = ""
)

$ErrorActionPreference = "Stop"

# ── 输出工具 ──────────────────────────────────────────────────
function Write-OK    { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Info  { param($msg) Write-Host "  ℹ  $msg" -ForegroundColor Cyan }
function Write-Head  { param($msg) Write-Host "`n  $msg" -ForegroundColor White }

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  🦞 ══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "     OpenClaw Starter Kit — Windows 安装" -ForegroundColor Magenta
Write-Host "     系统: Windows $([System.Environment]::OSVersion.Version)" -ForegroundColor Magenta
Write-Host "     时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Magenta
Write-Host "  🦞 ══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# ── 确定路径 ──────────────────────────────────────────────────
if ($WorkspacePath -eq "") {
    $WorkspacePath = Join-Path $env:USERPROFILE ".openclaw\workspace"
}
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $ScriptDir "workspace"

Write-Info "目标工作区: $WorkspacePath"

# ── 前置检查 ──────────────────────────────────────────────────
Write-Head "📋 Step 1/8 — 前置检查"

# Node.js
try {
    $nodeVer = & node -v 2>$null
    Write-OK "Node.js $nodeVer"
} catch {
    Write-Fail "未检测到 Node.js"
    Write-Host "    安装方法:"
    Write-Host "      winget install OpenJS.NodeJS.LTS"
    Write-Host "    或从 https://nodejs.org 下载安装"
    exit 1
}

# npm
try {
    $npmVer = & npm -v 2>$null
    Write-OK "npm $npmVer"
} catch {
    Write-Fail "未检测到 npm"
    exit 1
}

# OpenClaw
$hasOpenClaw = $false
try {
    $ocVer = & openclaw --version 2>$null
    Write-OK "OpenClaw ($ocVer)"
    $hasOpenClaw = $true
} catch {
    Write-Warn "未检测到 openclaw"
    $install = Read-Host "    是否现在安装 OpenClaw? [Y/n]"
    if ($install -ne "n" -and $install -ne "N") {
        Write-Info "正在安装 OpenClaw..."
        try {
            & npm install -g openclaw 2>$null
            Write-OK "OpenClaw 安装完成"
            $hasOpenClaw = $true
        } catch {
            Write-Fail "安装失败，请手动执行: npm install -g openclaw"
        }
    } else {
        Write-Warn "跳过。后续可手动安装。"
    }
}

# Git (可选)
try {
    $gitVer = & git --version 2>$null
    Write-OK "Git $($gitVer -replace 'git version ','')"
} catch {
    Write-Warn "Git 未安装 (可选，推荐用于快照版本管理)"
}

# ── OpenClaw Onboard 环境引导 ──────────────────────────────────
Write-Head "🚀 Step 2/8 — OpenClaw 环境引导"

$onboardNeeded = $false
$soulFile = Join-Path $WorkspacePath "SOUL.md"
$identityFile = Join-Path $WorkspacePath "IDENTITY.md"

if ((Test-Path $soulFile) -and (Test-Path $identityFile)) {
    Write-OK "检测到已完成 onboard（SOUL.md、IDENTITY.md 存在）"
} else {
    $onboardNeeded = $true
    if (-not $hasOpenClaw) {
        Write-Warn "OpenClaw CLI 未安装，无法执行 onboard"
        Write-Warn "请先安装 OpenClaw 后重新运行本脚本"
        Write-Warn "继续安装 Starter Kit 文件（onboard 部分跳过）..."
        $onboardNeeded = $false
    }
}

if ($onboardNeeded) {
    Write-Info "未检测到 OpenClaw 工作区（缺少 SOUL.md / IDENTITY.md）"
    Write-Info "需要先完成 OpenClaw 初始化 (onboard)"
    Write-Host ""

    # --- API 提供商选择 ---
    Write-Host "  请选择 API 提供商:"
    Write-Host "    [1] Anthropic (官方 Claude API)"
    Write-Host "    [2] 自定义 API 端点 (OpenRouter、Azure 等)"
    Write-Host "    [3] Z.AI"
    Write-Host ""
    $authChoice = Read-Host "  请输入选项 [1]"
    if ($authChoice -eq "") { $authChoice = "1" }

    $onboardAuthArgs = @()
    switch ($authChoice) {
        "1" {
            # Anthropic 官方
            $onboardAuthArgs += "--auth-choice", "apiKey"
            Write-Host ""
            $apiKey = Read-Host "  请输入 Anthropic API Key" -AsSecureString
            $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
            if ($apiKeyPlain -eq "") {
                Write-Fail "API Key 不能为空"
                exit 1
            }
            $onboardAuthArgs += "--anthropic-api-key", $apiKeyPlain
        }
        "2" {
            # 自定义端点
            $onboardAuthArgs += "--auth-choice", "custom-api-key"
            Write-Host ""
            $customUrl = Read-Host "  请输入 API Base URL (例: https://openrouter.ai/api/v1)"
            if ($customUrl -eq "") {
                Write-Fail "API Base URL 不能为空"
                exit 1
            }
            $apiKey = Read-Host "  请输入 API Key" -AsSecureString
            $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
            if ($apiKeyPlain -eq "") {
                Write-Fail "API Key 不能为空"
                exit 1
            }
            $customModel = Read-Host "  请输入模型 ID [claude-sonnet-4-6]"
            if ($customModel -eq "") { $customModel = "claude-sonnet-4-6" }
            $customCompat = Read-Host "  API 兼容类型 [openai]"
            if ($customCompat -eq "") { $customCompat = "openai" }
            $onboardAuthArgs += "--custom-base-url", $customUrl,
                "--custom-api-key", $apiKeyPlain,
                "--custom-model-id", $customModel,
                "--custom-compatibility", $customCompat
        }
        "3" {
            # Z.AI
            $onboardAuthArgs += "--auth-choice", "zai-api-key"
            Write-Host ""
            $apiKey = Read-Host "  请输入 Z.AI API Key" -AsSecureString
            $apiKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
            if ($apiKeyPlain -eq "") {
                Write-Fail "API Key 不能为空"
                exit 1
            }
            $onboardAuthArgs += "--zai-api-key", $apiKeyPlain
        }
        default {
            Write-Fail "无效选项: $authChoice"
            exit 1
        }
    }

    # --- 安装为系统服务 ---
    Write-Host ""
    $installDaemon = Read-Host "  是否将 Gateway 安装为系统服务 (开机自启)? [Y/n]"
    $daemonArgs = @()
    if ($installDaemon -ne "n" -and $installDaemon -ne "N") {
        $daemonArgs += "--install-daemon"
    }

    # --- 执行 onboard ---
    Write-Host ""
    Write-Info "正在执行 OpenClaw 初始化..."
    Write-Info "（跳过消息渠道配对和技能安装，可稍后通过 openclaw onboard 补充配置）"
    Write-Host ""

    $allArgs = @(
        "onboard",
        "--non-interactive",
        "--flow", "quickstart"
    ) + $onboardAuthArgs + @(
        "--skip-channels",
        "--skip-skills",
        "--accept-risk",
        "--workspace", $WorkspacePath
    ) + $daemonArgs

    try {
        & openclaw @allArgs
        Write-OK "OpenClaw 初始化完成"
    } catch {
        Write-Fail "OpenClaw 初始化失败"
        Write-Host ""
        Write-Host "  可能原因:"
        Write-Host "    · API Key 无效或过期"
        Write-Host "    · 网络连接问题"
        Write-Host "    · OpenClaw CLI 版本过旧 (尝试: npm update -g openclaw)"
        Write-Host ""
        Write-Host "  你可以手动执行: openclaw onboard"
        Write-Host "  完成后重新运行本安装脚本"
        exit 1
    }

    # 验证 onboard 成功
    if (Test-Path $soulFile) {
        Write-OK "工作区文件验证通过 (SOUL.md 已创建)"
    } else {
        Write-Warn "onboard 已执行但未检测到 SOUL.md，可能需要手动检查"
    }
}

# ── 备份已有工作区 ────────────────────────────────────────────
Write-Head "📦 Step 3/8 — 备份检查"

if (Test-Path $WorkspacePath) {
    $items = Get-ChildItem $WorkspacePath -Force 2>$null
    if ($items.Count -gt 0) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $backupPath = "$WorkspacePath.backup.$timestamp"
        Write-Warn "发现已有工作区，备份到: $backupPath"
        Copy-Item -Path $WorkspacePath -Destination $backupPath -Recurse -Force
        Write-OK "备份完成"
    } else {
        Write-Info "工作区为空，无需备份"
    }
} else {
    Write-Info "工作区不存在，无需备份"
}

# ── 创建目录结构 ──────────────────────────────────────────────
Write-Head "📁 Step 4/8 — 创建目录结构"

$dirs = @("memory", "skills", "snapshots", ".learnings", "scripts")
foreach ($d in $dirs) {
    $p = Join-Path $WorkspacePath $d
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
Write-OK "目录结构就绪"

# ── 复制配置文件 ──────────────────────────────────────────────
Write-Head "📝 Step 5/8 — 复制配置文件"

# --- 策略 1: 追加补丁（保留默认内容，追加扩展）---
foreach ($pf in @("AGENTS", "TOOLS")) {
    $patchSrc = Join-Path $SourceDir "patches\$pf.patch.md"
    $target = Join-Path $WorkspacePath "$pf.md"
    if (Test-Path $patchSrc) {
        if (Test-Path $target) {
            $content = Get-Content $target -Raw -ErrorAction SilentlyContinue
            if ($content -match "Starter Kit") {
                Write-Info "$pf.md 已包含 Starter Kit 扩展，跳过"
            } else {
                Add-Content -Path $target -Value (Get-Content $patchSrc -Raw)
                Write-OK "$pf.md ← 追加扩展"
            }
        } else {
            Write-Warn "$pf.md 不存在。请先运行 openclaw onboard"
        }
    }
}

# --- 策略 2: 仅创建新文件 ---
foreach ($nf in @("BOOT.md", "MEMORY.md")) {
    $dst = Join-Path $WorkspacePath $nf
    $src = Join-Path $SourceDir $nf
    if (-not (Test-Path $dst)) {
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Force
            Write-OK "$nf（新建）"
        }
    } else {
        Write-Info "$nf 已存在，跳过"
    }
}

# Skills
$skillsSrc = Join-Path $SourceDir "skills"
if (Test-Path $skillsSrc) {
    Copy-Item -Path "$skillsSrc\*" -Destination (Join-Path $WorkspacePath "skills") -Recurse -Force
    Write-OK "skills/ (self-evolution, daily-snapshot)"
}

# .learnings
$learnSrc = Join-Path $SourceDir ".learnings"
if (Test-Path $learnSrc) {
    Copy-Item -Path "$learnSrc\*" -Destination (Join-Path $WorkspacePath ".learnings") -Force
    Write-OK ".learnings/"
}

# Scripts — 复制脚本 (bash 版供 WSL/Git Bash，ps1 版供 Windows 原生)
foreach ($script in @("setup-cron.sh", "snapshot.sh", "setup-browser.sh", "setup-browser.ps1")) {
    $scriptSrc = Join-Path $SourceDir "scripts\$script"
    if (Test-Path $scriptSrc) {
        Copy-Item -Path $scriptSrc -Destination (Join-Path $WorkspacePath "scripts\$script") -Force
        Write-OK "scripts/$script"
    }
}

# Daily log
$today = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path $WorkspacePath "memory\$today.md"
if (-not (Test-Path $logFile)) {
    $logContent = @"
# $today — 每日活动日志

## 系统事件

- OpenClaw Starter Kit 初始化完成 ($(Get-Date -Format 'HH:mm'))
- 操作系统: Windows $([System.Environment]::OSVersion.Version)
"@
    Set-Content -Path $logFile -Value $logContent -Encoding UTF8
    Write-OK "memory/$today.md"
}

# ── 安装 ClawdHub CLI ─────────────────────────────────────────
Write-Head "🔧 Step 6/8 — ClawdHub CLI"

try {
    & clawdhub --version 2>$null | Out-Null
    Write-OK "ClawdHub CLI 已安装"
} catch {
    Write-Info "正在安装 ClawdHub CLI..."
    try {
        & npm i -g clawdhub 2>$null
        Write-OK "ClawdHub CLI 安装完成"
    } catch {
        Write-Warn "安装失败，请手动执行: npm i -g clawdhub"
    }
}

# ── 工具权限配置 ──────────────────────────────────────────────
Write-Head "🔑 Step 7/8 — 工具权限"

if ($hasOpenClaw) {
    $setupTools = Read-Host "是否配置工具权限（推荐首次使用）? [Y/n]"
    if ($setupTools -ne "n" -and $setupTools -ne "N") {
        Write-Info "配置工具策略..."
        & openclaw config set tools.profile '"full"' 2>$null
        & openclaw config set tools.deny '["sessions_spawn", "sessions_send"]' 2>$null
        & openclaw config set tools.fs.workspaceOnly true 2>$null
        & openclaw config set tools.elevated.enabled false 2>$null
        Write-OK "工具策略配置完成"

        # Browser: headless Chromium (可选)
        Write-Host ""
        Write-Info "Headless 浏览器让 Agent 可自主访问和操作网页（点击、填表、截图等）。"
        Write-Info "需要下载 Playwright，可能耗时较长（3-10 分钟）。"
        Write-Info "跳过后 Agent 仍可用 web_fetch 读取网页内容。"
        $setupBrowser = Read-Host "是否现在配置 headless 浏览器? [y/N]"
        if ($setupBrowser -eq "y" -or $setupBrowser -eq "Y") {
            $browserScript = Join-Path $WorkspacePath "scripts\setup-browser.ps1"
            if (Test-Path $browserScript) {
                & powershell -ExecutionPolicy Bypass -File $browserScript
            } else {
                Write-Warn "setup-browser.ps1 未找到，请手动运行"
            }
        } else {
            Write-Info "跳过。后续可单独运行:"
            Write-Host "    powershell -ExecutionPolicy Bypass -File `"$WorkspacePath\scripts\setup-browser.ps1`""
        }

        # Exec Approvals
        $approvalsFile = Join-Path $env:USERPROFILE ".openclaw\exec-approvals.json"
        $approvalsSrc = Join-Path $SourceDir "exec-approvals.json"
        if (Test-Path $approvalsSrc) {
            if (-not (Test-Path $approvalsFile) -or -not (Select-String -Path $approvalsFile -Pattern "allowlist" -Quiet)) {
                Copy-Item -Path $approvalsSrc -Destination $approvalsFile -Force
                Write-OK "exec-approvals.json (allowlist 模式)"
            } else {
                Write-Info "exec-approvals.json 已有自定义配置，跳过"
            }
        }

        Write-Host ""
        Write-Info "权限策略: allowlist 内命令自动放行，其余IM 询问"
    } else {
        Write-Info "跳过。后续可手动配置。"
    }
} else {
    Write-Warn "OpenClaw 未安装，跳过"
}

# ── 配置定时任务 ──────────────────────────────────────────────
Write-Head "⏰ Step 8/8 — 定时任务"

if ($hasOpenClaw) {
    # 检查 Gateway 是否在线
    $gwOk = $false
    try {
        & openclaw gateway status 2>$null | Out-Null
        $gwOk = $true
    } catch {}

    if ($gwOk) {
        $setupCron = Read-Host "是否现在配置定时任务? [y/N]"
        if ($setupCron -eq "y" -or $setupCron -eq "Y") {
            Write-Info "配置每日快照 (凌晨 2:00)..."
            & openclaw cron add --name "daily-snapshot" --cron "0 2 * * *" --session isolated --message "运行配置快照脚本: bash scripts/snapshot.sh 然后阅读 CHANGELOG.md 追加总结" 2>$null
            Write-Info "配置每日记忆整理 (23:00)..."
            & openclaw cron add --name "daily-memory-review" --cron "0 23 * * *" --session isolated --message "执行每日记忆整理和自省" 2>$null
            Write-Info "配置每周 Skill 巡检 (周日 10:00)..."
            & openclaw cron add --name "weekly-skill-review" --cron "0 10 * * 0" --session isolated --message "执行每周 Skill 巡检" 2>$null
            Write-OK "定时任务配置完成"
        } else {
            Write-Info "跳过。后续可在 Gateway 运行后手动配置。"
        }
    } else {
        Write-Warn "Gateway 未运行或未完成配对，跳过 cron 配置"
        Write-Host ""
        Write-Host "  定时任务需要 Gateway 在线才能配置。请在完成以下步骤后手动配置："
        Write-Host "    1. 启动 Gateway:    openclaw gateway start"
        Write-Host "    2. 完成频道配对:    openclaw onboard"
        Write-Host "    3. 配置定时任务:    openclaw cron add ..."
    }
} else {
    Write-Warn "OpenClaw 未安装，跳过"
}

# ── 完成 ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "  🦞 ══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "     ✅ 安装完成！" -ForegroundColor Green
Write-Host "  🦞 ══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "  📁 工作区: $WorkspacePath"
Write-Host ""
Write-Host "  📋 下一步:"
Write-Host "     1. 启动 Gateway:  openclaw gateway start"
Write-Host "     2. 在 IM 中发送: 「让我们来设置一下吧」"
Write-Host "     3. 按照引导完成初始化 (约 2 分钟)"
Write-Host ""
Write-Host "  💡 Windows 提示:" -ForegroundColor Yellow
Write-Host "     · Gateway 推荐在 PowerShell 中前台运行，或注册为 Windows 服务"
Write-Host "     · 也可以在 WSL2 中运行 Gateway (推荐，兼容性更好)"
Write-Host "     · 如果遇到 npm 全局安装权限问题，以管理员运行 PowerShell"
Write-Host ""
Write-Host "  📖 完整教程: TUTORIAL.md"
Write-Host ""
