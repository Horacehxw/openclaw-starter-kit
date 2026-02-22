[English](README.md) | 中文

# OpenClaw 自进化 Agent 配置最佳实践

## 🎯 这是什么

在 `openclaw onboard` 默认配置基础上的增量扩展包。默认配置已经提供了可用的 Agent（记忆系统、人格、安全规则等），本 Starter Kit 只补齐它缺失的部分，不修改任何默认文件的已有内容：

- **记忆可靠性** — 预创建 `MEMORY.md` 和 `memory/` 目录（默认不创建，导致很多用户的 Agent 不写长期记忆）
- **启动检查清单** — 新建 `BOOT.md`（默认不存在）
- **自主进化** — `.learnings/` 学习记录 + 4 个自定义 Skill（self-evolution、daily-snapshot、risk-skill-scanner、scan-all-risk-skill）
- **配置版本管理** — 每日快照脚本 + cron 任务 + 30 天回滚
- **安全加固** — exec-approvals 白名单 + `tools.profile = full`
- **技能风险扫描** — 6 维度安全扫描 + 每日 01:00 自动扫描 + HEARTBEAT CRITICAL 警告
- **网页浏览** — 可选 headless Chromium（默认只有纯 HTTP 的 `web_fetch`）

安装策略：只在 AGENTS.md 和 TOOLS.md 末尾**追加**少量扩展段落（指向新功能），其余全部是新建文件和目录。不修改 SOUL.md、IDENTITY.md、USER.md、HEARTBEAT.md、BOOTSTRAP.md。

**前置条件**：Node.js + npm。安装脚本可自动完成 `openclaw onboard` 初始化（交互式配置 API Key，渠道可稍后配置）。

**支持平台**：Linux / WSL2 / macOS / Windows

---

## 🚀 一键安装（推荐）

### 解压配置包

所有平台通用，先解压：

```bash
unzip openclaw-starter-kit.zip
cd openclaw-starter-kit
```

### 按平台运行对应脚本

#### 🐧 Linux（服务器 / 桌面）

```bash
chmod +x install.sh
bash install.sh
```

> 如果部署在远程服务器，建议用 systemd 管理 Gateway（见后文"服务化部署"章节）。

#### 🪟 WSL2（推荐 Windows 用户使用）

```bash
chmod +x install.sh
bash install.sh
```

脚本会自动检测 WSL 环境并给出针对性提示。WSL2 下运行 OpenClaw 兼容性最好，和原生 Linux 体验一致。

#### 🍎 macOS

```bash
chmod +x install.sh
bash install.sh
```

macOS 用户还可以使用 OpenClaw 菜单栏应用来管理 Gateway。

#### 🪟 Windows 原生（PowerShell）

```powershell
# 方式 1：在 PowerShell 中运行
powershell -ExecutionPolicy Bypass -File install.ps1

# 方式 2：右键 install.ps1 → 使用 PowerShell 运行

# 方式 3：自定义工作区路径
powershell -ExecutionPolicy Bypass -File install.ps1 -WorkspacePath "D:\my-agent"
```

> ⚠️ 如遇 npm 全局安装权限问题，请以**管理员身份**运行 PowerShell。
> 💡 推荐在 Windows 上优先使用 WSL2 方案，兼容性和性能更优。

### 安装脚本做了什么

无论哪个平台，脚本都执行 8 步：

1. **前置检查** — 检测 Node.js、npm、OpenClaw（未安装可自动安装）
2. **环境引导** — 检测 `openclaw onboard` 是否完成；未完成则引导配置 API 提供商、API Key，自动执行 `openclaw onboard --non-interactive`（跳过渠道配对，可稍后配置）
3. **备份** — 已有工作区自动备份
4. **建目录** — 创建 memory/、skills/、snapshots/ 等
5. **复制文件** — 追加补丁到 AGENTS/TOOLS + 新建 BOOT.md、MEMORY.md 等缺失文件
6. **装 CLI** — 安装 ClawdHub CLI
7. **工具权限** — 工具策略 + 命令白名单 + headless 浏览器（详见[附录 C](#附录-c工具权限详解)）
8. **配 Cron** — 可选配置定时任务（详见[附录 D](#附录-d定时任务详解)）

> Step 2 若已完成 onboard（检测到 SOUL.md）则自动跳过。Step 7 增量写入 `openclaw.json`，不覆盖模型/频道等配置。Step 8 需要 Gateway 在线。

---

## 🏁 首次使用流程

> ⚠️ 本配置包只操作 `~/.openclaw/workspace/` 目录（.md 文件和 skills），**不会覆盖** `openclaw.json` 中的模型、频道、插件等配置。如果尚未完成 `openclaw onboard`，安装脚本会自动引导你完成初始化。

安装完成后，按顺序执行：

```bash
# 1. 确认 Gateway 在运行
systemctl --user status openclaw-gateway
# 或手动启动: openclaw gateway start

# 2. 配置定时任务
bash ~/.openclaw/workspace/scripts/setup-cron.sh

# 3. 在 IM 中给 Agent 发第一条消息
```

在 IM 中发送：

```
让我们来设置一下吧
```

Agent 会按照 OpenClaw 默认的 BOOTSTRAP.md 引导你完成身份设置（取名字、了解你的偏好等）。完成后 BOOTSTRAP.md 会自动删除。

---

## 📖 配置文件详解

### 追加补丁（2 个，末尾追加，不改已有内容）

**AGENTS.md** ← 追加 ~700B：学习记录（`.learnings/` 目录说明）、配置快照（`snapshots/` 目录 + daily-snapshot Skill）、Skill 获取（ClawdHub 搜索/安装流程）。

**TOOLS.md** ← 追加 ~500B：已安装 Skills 列表（self-evolution、daily-snapshot、risk-skill-scanner、scan-all-risk-skill）、ClawdHub CLI 速查。

### 新建文件（默认不存在）

**BOOT.md**：每次 session 启动检查清单 — 身份检查、用户状态、记忆加载、快照检查、Skill 状态。

**MEMORY.md**：预创建空结构 — 系统事件、用户偏好、重要决策、项目上下文、教训改进。解决默认不创建此文件导致 Agent 无处写长期记忆的问题。

### 新建目录和 Skills

| 新增内容 | 用途 |
|----------|------|
| `.learnings/` | LEARNINGS.md + ERRORS.md + FEATURE_REQUESTS.md |
| `skills/self-evolution/` | 自主学习与改进驱动 |
| `skills/daily-snapshot/` | 每日配置快照 + 版本回滚 |
| `skills/risk-skill-scanner/` | 单个技能风险扫描（6 维度安全检测） |
| `skills/scan-all-risk-skill/` | 批量技能风险扫描（每日 01:00 自动执行） |
| `scripts/snapshot.sh` | 确定性快照脚本（文件复制/diff/清理） |
| `scripts/setup-cron.sh` | 定时任务配置（快照/整理/巡检） |
| `scripts/setup-browser.sh` | 可选 headless 浏览器安装（Linux/WSL2/macOS） |
| `scripts/setup-browser.ps1` | 可选 headless 浏览器安装（Windows） |
| `snapshots/` | 配置快照存储目录 |
| `memory/` | daily log 目录（默认不预创建） |

### 不修改的文件（全部使用默认）

SOUL.md、IDENTITY.md、USER.md、HEARTBEAT.md、BOOTSTRAP.md — 保持 `openclaw onboard` 生成的原样。

---

## 💡 常用操作

### 恢复到历史配置

在 IM 中说：

```
恢复到 2026-02-20 的配置
```

### 让 Agent 学习新 Skill

```
帮我搜索一下有没有可以管理 GitHub issue 的 Skill
```

### 查看学习记录

```bash
# Linux / WSL / macOS
cat ~/.openclaw/workspace/.learnings/LEARNINGS.md

# Windows PowerShell
Get-Content $env:USERPROFILE\.openclaw\workspace\.learnings\LEARNINGS.md
```

### 手动触发定时任务

```bash
openclaw cron run --force daily-snapshot
```

### 检查 context 注入大小

```bash
openclaw context detail
```

---

## 🔒 安全建议

1. **API Key**：存放在 `~/.openclaw/.env`，设置权限 `chmod 600`（Linux/macOS）
2. **群聊**：SOUL.md 已配置群聊行为限制
3. **Skill 审查**：安装新 Skill 前 Agent 会征求确认
7. **风险扫描**：每日 01:00 自动扫描所有已安装 Skill；CRITICAL 风险触发 HEARTBEAT 警告
4. **快照备份**：建议 snapshots/ 目录用 git 管理或定期 rsync
5. **记忆隐私**：MEMORY.md 只在私聊 session 加载
6. **兼容检查**：安装后运行 `openclaw doctor` 确认无异常

---

## 🔄 可扩展方向

- **添加 Skills**：`clawdhub install <n>` 或手动创建 `skills/xxx/SKILL.md`
- **连接渠道**：Telegram、Slack、Discord、微信等
- **定制 HEARTBEAT**：添加邮件检查、日程提醒等
- **多 Agent**：为不同场景创建不同 Agent 配置
- **EvoMap 联网**：接入全球 Agent 进化网络共享能力（参见 https://evomap.ai）

---

## ❓ FAQ

**Q: Agent 没有触发 BOOTSTRAP？**
A: 发送 "请读取 BOOTSTRAP.md 并引导我完成设置"。

**Q: 定时任务没执行？**
A: `openclaw cron list --verbose` 检查状态，确认 Gateway 在运行。

**Q: 配置 cron 报 "pairing required"？**
A: 2026.2.19 版本的已知问题（[#21236](https://github.com/openclaw/openclaw/issues/21236)）。修复：`systemctl --user stop openclaw-gateway && rm -rf ~/.openclaw/devices && systemctl --user start openclaw-gateway`，等 5 秒后重试。

**Q: 如何完全重置？**
A: 重新运行安装脚本，或手动删除工作区后重新复制文件。

**Q: Token 消耗高？**
A: 降低 HEARTBEAT 频率，或在 cron 中用 `--model` 指定便宜模型。用 `openclaw context detail` 查看各文件注入的 token 量。

**Q: Windows 上路径报错？**
A: 确认 PowerShell 版本 ≥ 5.1，路径中不要有中文。也可改用 WSL2 方案。

**Q: WSL2 下 Gateway 重启后断连？**
A: 用 tmux 保持后台运行，或配置 Windows 任务计划自动启动。

**Q: 补丁追加后文件太大了？**
A: 用 `openclaw context detail` 检查。单文件超 20,000 字符会被截断。如需精简，可手动编辑去掉不需要的段落。

---

_配置包版本: v1.7.0 | 最后更新: 2026-02-22_
_支持平台: Linux / WSL2 / macOS / Windows_
_基于 OpenClaw 社区最佳实践整合，参考了 ClawdHub、self-improving-agent 等开源项目。_

---

## 附录 A：配置包文件结构

```
openclaw-starter-kit/
├── install.sh              # Linux / WSL2 / macOS 安装脚本
├── install.ps1             # Windows PowerShell 安装脚本
├── exec-approvals.json     # 命令执行白名单模板
├── TUTORIAL.md             # 本教程文档
└── workspace/              # Agent 工作区（增量内容）
    ├── patches/            # 追加补丁（追加到默认文件末尾）
    │   ├── AGENTS.patch.md    # → 追加到 AGENTS.md
    │   └── TOOLS.patch.md     # → 追加到 TOOLS.md
    ├── BOOT.md             # 启动检查清单（默认不存在，新建）
    ├── MEMORY.md           # 长期记忆（默认不存在，新建）
    ├── memory/             # daily log 目录
    ├── snapshots/          # 配置快照目录
    ├── .learnings/         # 学习记录
    │   ├── LEARNINGS.md
    │   ├── ERRORS.md
    │   └── FEATURE_REQUESTS.md
    ├── skills/
    │   ├── self-evolution/SKILL.md
    │   ├── daily-snapshot/SKILL.md
    │   ├── risk-skill-scanner/SKILL.md
    │   └── scan-all-risk-skill/SKILL.md
    └── scripts/
        ├── setup-cron.sh
        ├── setup-browser.sh
        ├── setup-browser.ps1
        └── snapshot.sh
```

> 不包含 SOUL.md、IDENTITY.md、USER.md、HEARTBEAT.md、BOOTSTRAP.md — 全部使用默认版本。

---

## 附录 B：服务化部署（长期运行）

### Linux：systemd 服务

```bash
sudo tee /etc/systemd/system/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/home/YOUR_USERNAME/.openclaw
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable openclaw-gateway
sudo systemctl start openclaw-gateway

# 查看状态
sudo systemctl status openclaw-gateway
```

### WSL2：后台运行

WSL2 没有 systemd（除非手动启用），推荐两种方式：

```bash
# 方式 1：tmux（推荐）
tmux new -s openclaw
openclaw gateway start --foreground
# Ctrl+B, D 分离

# 方式 2：nohup
nohup openclaw gateway start --foreground > ~/.openclaw/logs/gateway.log 2>&1 &
```

如需 WSL 开机自动启动，在 Windows 任务计划中添加：
```
wsl -d Ubuntu -e bash -c "cd ~ && openclaw gateway start --foreground"
```

### macOS：launchd 服务

```bash
cat > ~/Library/LaunchAgents/ai.openclaw.gateway.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.openclaw.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/openclaw</string>
        <string>gateway</string>
        <string>start</string>
        <string>--foreground</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-gateway.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-gateway.err</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

或直接使用 OpenClaw 的 macOS 菜单栏应用。

### Windows 原生：后台运行

```powershell
# 方式 1：直接在 PowerShell 前台跑
openclaw gateway start --foreground

# 方式 2：后台任务
Start-Process -NoNewWindow openclaw -ArgumentList "gateway","start","--foreground"

# 方式 3：注册为 Windows 服务 (需要 nssm)
# 下载 nssm: https://nssm.cc/
nssm install OpenClawGateway "C:\Users\YOU\AppData\Roaming\npm\openclaw.cmd" gateway start --foreground
nssm start OpenClawGateway
```

---

## 附录 C：工具权限详解

安装脚本 Step 6 配置两层独立的权限控制。

### 工具策略（写入 `openclaw.json`，增量写入不覆盖已有配置）

| 配置项 | 值 | 含义 |
|--------|-----|------|
| `tools.profile` | `full` | 开启全部核心工具（read/write/exec/web_search 等） |
| `tools.deny` | `[sessions_spawn, sessions_send]` | 禁止跨 session 操作 |
| `tools.fs.workspaceOnly` | `true` | 文件操作限制在 workspace 目录内 |
| `tools.elevated.enabled` | `false` | 禁止宿主机直接执行（elevated） |

### 命令执行策略（`~/.openclaw/exec-approvals.json`）

仅在无自定义配置时写入，已有 allowlist 的不覆盖。

| 策略 | 值 | 含义 |
|------|-----|------|
| `security` | `allowlist` | 只有白名单内的命令自动放行 |
| `ask` | `on-miss` | 白名单外的命令通过 IM 询问你 |
| `askFallback` | `deny` | 你没回复时默认拒绝（防半夜 cron 意外） |
| `autoAllowSkills` | `true` | ClawdHub 安装的 Skill 自动信任 |

### 白名单范围

自动放行：只读命令（ls/cat/grep/find）、文件操作（mkdir/cp/mv/touch）、开发工具（git/python/node/npm）、OpenClaw 自身命令（openclaw/clawdhub）。

IM 询问：`rm`、`sudo`、`apt`、`kill`、`systemctl`（非 `--user`）等不在白名单的命令。

### 扩展白名单

```bash
nano ~/.openclaw/exec-approvals.json
openclaw gateway restart
```

### Headless 浏览器

安装时可选配置隔离的 headless Chromium，Agent 可通过 `browser` 工具自主打开网页、点击、填表、截图。与 `web_fetch`（纯 HTTP GET，不执行 JS）互补，用于 JS 渲染页面和需要交互的场景。

| 配置项 | 值 | 含义 |
|--------|-----|------|
| `browser.enabled` | `true` | 启用浏览器工具 |
| `browser.defaultProfile` | `openclaw` | 使用 managed 隔离浏览器（非个人浏览器） |
| `browser.headless` | `true` | 无头模式（服务器/WSL2 必须） |
| `browser.noSandbox` | `true` | WSL2/Docker 环境兼容 |

前置依赖：Chromium + Playwright（安装时可选配置，也可后续单独运行 `setup-browser.sh`）。空闲占用 ~80MB 内存，打开页面时 150-300MB。

启用/关闭/后续安装，参见[附录 E](#附录-eheadless-浏览器管理)。

---

## 附录 D：定时任务详解

安装脚本 Step 7 可选配置四个定时任务（OpenClaw 内置 cron）：

| 任务 | 时间 | 功能 |
|------|------|------|
| `daily-risk-scan` | 每天 01:00 | 扫描所有已安装 Skill 的安全风险；CRITICAL 发现触发 HEARTBEAT 警告 |
| `daily-snapshot` | 每天 02:00 | 运行 `snapshot.sh` 备份配置 + 生成 CHANGELOG |
| `daily-memory-review` | 每天 23:00 | 整理今日记忆，更新 MEMORY.md |
| `weekly-skill-review` | 每周日 10:00 | 更新已安装 Skill，搜索新能力 |

### 安装时跳过了？后续手动配置

```bash
# Linux / WSL / macOS
bash ~/.openclaw/workspace/scripts/setup-cron.sh

# Windows PowerShell
openclaw cron add --name "daily-risk-scan" --cron "0 1 * * *" --session isolated --message "执行每日技能风险扫描，CRITICAL 发现写入 HEARTBEAT.md"
openclaw cron add --name "daily-snapshot" --cron "0 2 * * *" --session isolated --message "运行 bash scripts/snapshot.sh 然后阅读 CHANGELOG.md 追加总结"
openclaw cron add --name "daily-memory-review" --cron "0 23 * * *" --session isolated --message "执行每日记忆整理"
openclaw cron add --name "weekly-skill-review" --cron "0 10 * * 0" --session isolated --message "执行每周 Skill 巡检"
```

### 验证与手动触发

```bash
openclaw cron list
openclaw cron run --force daily-snapshot
```

---

## 附录 E：Headless 浏览器管理

### 安装时跳过了？后续单独安装

```bash
# Linux / WSL2 / macOS
bash ~/.openclaw/workspace/scripts/setup-browser.sh
```

```powershell
# Windows PowerShell（无需 WSL）
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.openclaw\workspace\scripts\setup-browser.ps1"
```

脚本会自动检测浏览器（Chrome/Edge/Brave）+ 安装 Playwright，写入配置并重启 Gateway。

### 关闭浏览器

```bash
openclaw config set browser.enabled false
openclaw gateway restart
```

关闭后 Agent 仍可用 `web_fetch`（纯 HTTP）读取网页，只是无法执行 JS 或进行页面交互。

### 重新启用

```bash
openclaw config set browser.enabled true
openclaw config set browser.headless true
openclaw gateway restart
```
