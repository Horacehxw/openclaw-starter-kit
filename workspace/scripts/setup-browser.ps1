# ─────────────────────────────────────────────────────────────
# setup-browser.ps1 — 为 OpenClaw Agent 配置 headless 浏览器 (Windows)
#
# 可在安装时由 install.ps1 调用，也可后续单独运行：
#   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.openclaw\workspace\scripts\setup-browser.ps1"
# ─────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

function Write-OK    { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }
function Write-Info  { param($msg) Write-Host "  ℹ  $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "  🌐 OpenClaw Headless 浏览器配置 (Windows)" -ForegroundColor White
Write-Host "  ════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# ── 前置检查 ──────────────────────────────────────────────────
try {
    & openclaw --version 2>$null | Out-Null
} catch {
    Write-Fail "openclaw 未安装，请先完成基础部署"
    exit 1
}

# ── Step 1: 检测 Chrome/Edge/Brave ───────────────────────────
Write-Info "检测浏览器..."
$chromiumPath = $null
$candidates = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)
foreach ($p in $candidates) {
    if (Test-Path $p) { $chromiumPath = $p; break }
}
if (-not $chromiumPath) {
    foreach ($name in @("chrome", "chromium", "brave", "msedge")) {
        $found = Get-Command $name -ErrorAction SilentlyContinue
        if ($found) { $chromiumPath = $found.Source; break }
    }
}

if (-not $chromiumPath) {
    Write-Fail "未检测到 Chrome/Edge/Brave"
    Write-Host "    请安装以下任一浏览器后重新运行本脚本："
    Write-Host "      · Google Chrome:    https://www.google.com/chrome/"
    Write-Host "      · Microsoft Edge:   系统自带或 https://www.microsoft.com/edge"
    Write-Host "      · Brave:            https://brave.com/"
    exit 1
}
Write-OK "已检测到: $chromiumPath"

# ── Step 2: 写入 OpenClaw 配置 ───────────────────────────────
Write-Info "写入 browser 配置..."
& openclaw config set browser.enabled true 2>$null
& openclaw config set browser.defaultProfile '"openclaw"' 2>$null
& openclaw config set browser.headless true 2>$null
& openclaw config set browser.noSandbox true 2>$null
Write-OK "browser 配置写入完成"

# ── Step 3: 安装 Playwright ──────────────────────────────────
Write-Info "检测 Playwright..."
$pwDir = Join-Path $env:USERPROFILE ".openclaw\node_modules\playwright"
if (Test-Path $pwDir) {
    Write-OK "Playwright 已安装"
} else {
    Write-Info "安装 Playwright（可能需要几分钟）..."
    $openclawDir = Join-Path $env:USERPROFILE ".openclaw"
    Push-Location $openclawDir
    try {
        & npm install playwright 2>$null
        Pop-Location
        if (Test-Path $pwDir) {
            Write-OK "Playwright 安装完成"
        } else {
            Write-Warn "Playwright 安装失败"
            Write-Host "    后续可手动安装: cd $openclawDir && npm install playwright"
        }
    } catch {
        Pop-Location
        Write-Warn "Playwright 安装失败"
        Write-Host "    后续可手动安装: cd $openclawDir && npm install playwright"
    }
}

# ── Step 4: 重启 Gateway 并验证 ──────────────────────────────
Write-Info "重启 Gateway..."
try {
    & openclaw gateway restart 2>$null
    Start-Sleep -Seconds 3
    Write-OK "Gateway 已重启"
} catch {
    Write-Warn "Gateway 重启失败，请手动执行: openclaw gateway restart"
}

Write-Info "验证浏览器..."
try {
    & openclaw browser start --profile openclaw 2>$null
    Write-OK "浏览器启动成功"
} catch {
    Write-Warn "浏览器启动验证失败，可稍后手动测试: openclaw browser snapshot"
}

Write-Host ""
Write-Host "  ════════════════════════════════════════════" -ForegroundColor White
Write-Host "  ✅ Headless 浏览器配置完成" -ForegroundColor Green
Write-Host ""
Write-Host "  Agent 现在可以通过 browser 工具自主访问网页。"
Write-Host "  关闭浏览器: openclaw config set browser.enabled false; openclaw gateway restart"
Write-Host ""
