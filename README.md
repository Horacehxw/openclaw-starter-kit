English | [中文](README_zh.md)

# OpenClaw Self-Evolving Agent Configuration Best Practices

## 🎯 What Is This

An incremental extension pack on top of `openclaw onboard` defaults. The default configuration already provides a usable Agent (memory system, personality, security rules, etc.). This Starter Kit only fills in the missing pieces without modifying any existing content in default files:

- **Memory Reliability** — Pre-creates `MEMORY.md` and `memory/` directory (not created by default, causing many users' Agents to never write long-term memory)
- **Startup Checklist** — Creates `BOOT.md` (does not exist by default)
- **Self-Evolution** — `.learnings/` records + 4 custom Skills (self-evolution, daily-snapshot, risk-skill-scanner, scan-all-risk-skill)
- **Config Version Control** — Daily snapshot script + cron tasks + 30-day rollback
- **Security Hardening** — exec-approvals allowlist + `tools.profile = full`
- **Skill Risk Scanning** — 6-dimension security scan + daily 01:00 auto-scan + HEARTBEAT CRITICAL alerts
- **Web Browsing** — Optional headless Chromium (default only has plain HTTP `web_fetch`)

Installation strategy: Only **appends** small extension paragraphs to the end of AGENTS.md and TOOLS.md (pointing to new features). Everything else is new files and directories. Does not modify SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, or BOOTSTRAP.md.

**Prerequisites**: Node.js + npm. The install script can automatically run `openclaw onboard` if not yet completed (interactive API key setup, channels can be configured later).

**Supported Platforms**: Linux / WSL2 / macOS / Windows

---

## 🚀 One-Click Install (Recommended)

### Extract the Package

Common to all platforms, extract first:

```bash
unzip openclaw-starter-kit.zip
cd openclaw-starter-kit
```

### Run the Platform-Specific Script

#### 🐧 Linux (Server / Desktop)

```bash
chmod +x install.sh
bash install.sh
```

> For remote server deployment, consider using systemd to manage the Gateway (see "Service Deployment" section below).

#### 🪟 WSL2 (Recommended for Windows Users)

```bash
chmod +x install.sh
bash install.sh
```

The script auto-detects the WSL environment and provides platform-specific hints. Running OpenClaw under WSL2 offers the best compatibility — identical to the native Linux experience.

#### 🍎 macOS

```bash
chmod +x install.sh
bash install.sh
```

macOS users can also use the OpenClaw menu bar app to manage the Gateway.

#### 🪟 Windows Native (PowerShell)

```powershell
# Option 1: Run in PowerShell
powershell -ExecutionPolicy Bypass -File install.ps1

# Option 2: Right-click install.ps1 → Run with PowerShell

# Option 3: Custom workspace path
powershell -ExecutionPolicy Bypass -File install.ps1 -WorkspacePath "D:\my-agent"
```

> ⚠️ If you encounter npm global install permission issues, run PowerShell as **Administrator**.
> 💡 On Windows, WSL2 is recommended for better compatibility and performance.

### What the Install Script Does

Regardless of platform, the script performs 8 steps:

1. **Prerequisite Check** — Detects Node.js, npm, OpenClaw (auto-installs if missing)
2. **OpenClaw Onboard** — Detects if `openclaw onboard` has been completed; if not, guides you through API provider selection, API key input, and runs `openclaw onboard --non-interactive` (channels skipped, configurable later)
3. **Backup** — Automatically backs up existing workspace
4. **Create Directories** — Creates memory/, skills/, snapshots/, etc.
5. **Copy Files** — Appends patches to AGENTS/TOOLS + creates missing files like BOOT.md, MEMORY.md
6. **Install CLI** — Installs ClawdHub CLI
7. **Tool Permissions** — Tool policy + command allowlist + headless browser (see [Appendix C](#appendix-c-tool-permissions))
8. **Configure Cron** — Optional scheduled task setup (see [Appendix D](#appendix-d-scheduled-tasks))

> Step 2 is skipped if onboard is already completed (detected via SOUL.md existence). Step 7 incrementally writes to `openclaw.json` without overwriting model/channel configs. Step 8 requires the Gateway to be online.

---

## 🏁 First-Time Usage

> ⚠️ This configuration pack only operates on the `~/.openclaw/workspace/` directory (.md files and skills). It **does not overwrite** model, channel, plugin, or other settings in `openclaw.json`. If you haven't completed `openclaw onboard` yet, the install script will guide you through it automatically.

**Access the Dashboard**: After installation, the script displays the Gateway Dashboard URL (`http://127.0.0.1:18789/?token=xxx`). Open it in your browser. Retrieve it anytime with `openclaw dashboard --no-open`.

After installation, execute in order:

```bash
# 1. Confirm Gateway is running
systemctl --user status openclaw-gateway
# Or start manually: openclaw gateway start

# 2. Configure scheduled tasks
bash ~/.openclaw/workspace/scripts/setup-cron.sh

# 3. Send the first message to your Agent in IM
```

Send in IM:

```
Let's get set up
```

The Agent will follow OpenClaw's default BOOTSTRAP.md to guide you through identity setup (choosing a name, learning your preferences, etc.). Once complete, BOOTSTRAP.md is automatically deleted.

---

## 📖 Configuration File Details

### Append Patches (2 files, appended to end, no existing content modified)

**AGENTS.md** ← Appends ~700B: learning records (`.learnings/` directory description), config snapshots (`snapshots/` directory + daily-snapshot Skill), Skill acquisition (ClawdHub search/install workflow).

**TOOLS.md** ← Appends ~500B: installed Skills list (self-evolution, daily-snapshot, risk-skill-scanner, scan-all-risk-skill), ClawdHub CLI quick reference.

### New Files (Don't Exist by Default)

**BOOT.md**: Session startup checklist — identity check, user status, memory loading, snapshot check, Skill status.

**MEMORY.md**: Pre-created empty structure — system events, user preferences, important decisions, project context, lessons learned. Solves the issue of Agents having nowhere to write long-term memory when this file isn't created by default.

### New Directories and Skills

| New Content | Purpose |
|-------------|---------|
| `.learnings/` | LEARNINGS.md + ERRORS.md + FEATURE_REQUESTS.md |
| `skills/self-evolution/` | Self-directed learning and improvement |
| `skills/daily-snapshot/` | Daily config snapshots + version rollback |
| `skills/risk-skill-scanner/` | Single Skill security audit (6-dimension inspection) |
| `skills/scan-all-risk-skill/` | Batch Skill risk scanning (daily 01:00 auto-scan) |
| `scripts/snapshot.sh` | Deterministic snapshot script (file copy/diff/cleanup) |
| `scripts/setup-cron.sh` | Scheduled task configuration (snapshot/organize/audit) |
| `scripts/setup-browser.sh` | Optional headless browser installation (Linux/WSL2/macOS) |
| `scripts/setup-browser.ps1` | Optional headless browser installation (Windows) |
| `snapshots/` | Config snapshot storage directory |
| `memory/` | Daily log directory (not pre-created by default) |

### Unmodified Files (All Use Defaults)

SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, BOOTSTRAP.md — kept as generated by `openclaw onboard`.

---

## 💡 Common Operations

### Restore to a Previous Configuration

Say in IM:

```
Restore to the 2026-02-20 configuration
```

### Have the Agent Learn a New Skill

```
Search for a Skill that can manage GitHub issues
```

### View Learning Records

```bash
# Linux / WSL / macOS
cat ~/.openclaw/workspace/.learnings/LEARNINGS.md

# Windows PowerShell
Get-Content $env:USERPROFILE\.openclaw\workspace\.learnings\LEARNINGS.md
```

### Manually Trigger a Scheduled Task

```bash
openclaw cron run --force daily-snapshot
```

### Check Context Injection Size

```bash
openclaw context detail
```

---

## 🔒 Security Recommendations

1. **API Key**: Store in `~/.openclaw/.env`, set permissions with `chmod 600` (Linux/macOS)
2. **Group Chat**: SOUL.md already configures group chat behavior restrictions
3. **Skill Review**: Agent will ask for confirmation before installing new Skills
7. **Risk Scanning**: Daily automatic scanning of all installed Skills at 01:00; CRITICAL risks trigger HEARTBEAT alerts
4. **Snapshot Backup**: Consider managing the snapshots/ directory with git or periodic rsync
5. **Memory Privacy**: MEMORY.md is only loaded in private chat sessions
6. **Compatibility Check**: Run `openclaw doctor` after installation to confirm no issues

---

## 🔄 Extensibility

- **Add Skills**: `clawdhub install <n>` or manually create `skills/xxx/SKILL.md`
- **Connect Channels**: Telegram, Slack, Discord, WeChat, etc.
- **Customize HEARTBEAT**: Add email checking, calendar reminders, etc.
- **Multi-Agent**: Create different Agent configurations for different scenarios
- **EvoMap Network**: Join the global Agent evolution network to share capabilities (see https://evomap.ai)

---

## ❓ FAQ

**Q: Agent didn't trigger BOOTSTRAP?**
A: Send "Please read BOOTSTRAP.md and guide me through setup".

**Q: Scheduled tasks not running?**
A: Check status with `openclaw cron list --verbose`, confirm the Gateway is running.

**Q: Cron config reports "pairing required"?**
A: Known issue in version 2026.2.19 ([#21236](https://github.com/openclaw/openclaw/issues/21236)). Fix: `systemctl --user stop openclaw-gateway && rm -rf ~/.openclaw/devices && systemctl --user start openclaw-gateway`, wait 5 seconds and retry.

**Q: How to fully reset?**
A: Re-run the install script, or manually delete the workspace and re-copy files.

**Q: High token consumption?**
A: Reduce HEARTBEAT frequency, or specify a cheaper model with `--model` in cron. Use `openclaw context detail` to check token usage per injected file.

**Q: Path errors on Windows?**
A: Confirm PowerShell version ≥ 5.1, avoid Chinese characters in paths. Alternatively, use the WSL2 approach.

**Q: Gateway disconnects after restart under WSL2?**
A: Use tmux to keep it running in the background, or configure a Windows Task Scheduler to auto-start it.

**Q: File too large after appending patches?**
A: Check with `openclaw context detail`. Files exceeding 20,000 characters will be truncated. If needed, manually edit to remove unnecessary sections.

---

_Pack version: v1.7.0 | Last updated: 2026-02-22_
_Supported platforms: Linux / WSL2 / macOS / Windows_
_Based on OpenClaw community best practices, referencing ClawdHub, self-improving-agent, and other open-source projects._

---

## Appendix A: Pack File Structure

```
openclaw-starter-kit/
├── install.sh              # Linux / WSL2 / macOS install script
├── install.ps1             # Windows PowerShell install script
├── exec-approvals.json     # Command execution allowlist template
├── TUTORIAL.md             # Tutorial documentation
└── workspace/              # Agent workspace (incremental content)
    ├── patches/            # Append patches (appended to default file endings)
    │   ├── AGENTS.patch.md    # → Appended to AGENTS.md
    │   └── TOOLS.patch.md     # → Appended to TOOLS.md
    ├── BOOT.md             # Startup checklist (new, doesn't exist by default)
    ├── MEMORY.md           # Long-term memory (new, doesn't exist by default)
    ├── memory/             # Daily log directory
    ├── snapshots/          # Config snapshot directory
    ├── .learnings/         # Learning records
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

> Does not include SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, BOOTSTRAP.md — all use default versions.

---

## Appendix B: Service Deployment (Long-Running)

### Linux: systemd Service

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

# Check status
sudo systemctl status openclaw-gateway
```

### WSL2: Background Running

WSL2 doesn't have systemd (unless manually enabled). Two recommended approaches:

```bash
# Option 1: tmux (recommended)
tmux new -s openclaw
openclaw gateway start --foreground
# Ctrl+B, D to detach

# Option 2: nohup
nohup openclaw gateway start --foreground > ~/.openclaw/logs/gateway.log 2>&1 &
```

For WSL auto-start on boot, add to Windows Task Scheduler:
```
wsl -d Ubuntu -e bash -c "cd ~ && openclaw gateway start --foreground"
```

### macOS: launchd Service

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

Or simply use the OpenClaw macOS menu bar app.

### Windows Native: Background Running

```powershell
# Option 1: Run in foreground in PowerShell
openclaw gateway start --foreground

# Option 2: Background job
Start-Process -NoNewWindow openclaw -ArgumentList "gateway","start","--foreground"

# Option 3: Register as Windows Service (requires nssm)
# Download nssm: https://nssm.cc/
nssm install OpenClawGateway "C:\Users\YOU\AppData\Roaming\npm\openclaw.cmd" gateway start --foreground
nssm start OpenClawGateway
```

---

## Appendix C: Tool Permissions

Install script Step 6 configures two independent permission layers.

### Tool Policy (written to `openclaw.json`, incremental — does not overwrite existing config)

| Setting | Value | Meaning |
|---------|-------|---------|
| `tools.profile` | `full` | Enable all core tools (read/write/exec/web_search, etc.) |
| `tools.deny` | `[sessions_spawn, sessions_send]` | Disable cross-session operations |
| `tools.fs.workspaceOnly` | `true` | Restrict file operations to workspace directory |
| `tools.elevated.enabled` | `false` | Disable direct host execution (elevated) |

### Command Execution Policy (`~/.openclaw/exec-approvals.json`)

Only written when no custom config exists; existing allowlists are not overwritten.

| Policy | Value | Meaning |
|--------|-------|---------|
| `security` | `allowlist` | Only allowlisted commands auto-approve |
| `ask` | `on-miss` | Commands not in allowlist prompt you via IM |
| `askFallback` | `deny` | Default deny when you don't respond (prevents late-night cron accidents) |
| `autoAllowSkills` | `true` | Skills installed via ClawdHub are auto-trusted |

### Allowlist Scope

Auto-approved: Read-only commands (ls/cat/grep/find), file operations (mkdir/cp/mv/touch), dev tools (git/python/node/npm), OpenClaw commands (openclaw/clawdhub).

IM prompt required: `rm`, `sudo`, `apt`, `kill`, `systemctl` (non `--user`), and other commands not in the allowlist.

### Extending the Allowlist

```bash
nano ~/.openclaw/exec-approvals.json
openclaw gateway restart
```

### Headless Browser

Optionally configure an isolated headless Chromium during installation. The Agent can use the `browser` tool to open web pages, click, fill forms, and take screenshots. Complements `web_fetch` (plain HTTP GET, no JS execution) for JS-rendered pages and interactive scenarios.

| Setting | Value | Meaning |
|---------|-------|---------|
| `browser.enabled` | `true` | Enable browser tool |
| `browser.defaultProfile` | `openclaw` | Use managed isolated browser (not personal browser) |
| `browser.headless` | `true` | Headless mode (required for server/WSL2) |
| `browser.noSandbox` | `true` | WSL2/Docker environment compatibility |

Prerequisites: Chromium + Playwright (optionally configured during installation, or run `setup-browser.sh` separately later). Idle memory usage ~80MB, 150-300MB when pages are open.

To enable/disable/install later, see [Appendix E](#appendix-e-headless-browser-management).

---

## Appendix D: Scheduled Tasks

Install script Step 7 optionally configures four scheduled tasks (OpenClaw built-in cron):

| Task | Schedule | Function |
|------|----------|----------|
| `daily-risk-scan` | Daily 01:00 | Scans all installed Skills for security risks; CRITICAL findings trigger HEARTBEAT alerts |
| `daily-snapshot` | Daily 02:00 | Runs `snapshot.sh` to backup config + generate CHANGELOG |
| `daily-memory-review` | Daily 23:00 | Organizes today's memory, updates MEMORY.md |
| `weekly-skill-review` | Weekly Sunday 10:00 | Updates installed Skills, searches for new capabilities |

### Skipped During Install? Configure Manually Later

```bash
# Linux / WSL / macOS
bash ~/.openclaw/workspace/scripts/setup-cron.sh

# Windows PowerShell
openclaw cron add --name "daily-risk-scan" --cron "0 1 * * *" --session isolated --message "Execute daily Skill risk scan, write CRITICAL findings to HEARTBEAT.md"
openclaw cron add --name "daily-snapshot" --cron "0 2 * * *" --session isolated --message "Run bash scripts/snapshot.sh then read CHANGELOG.md and append summary"
openclaw cron add --name "daily-memory-review" --cron "0 23 * * *" --session isolated --message "Execute daily memory organization"
openclaw cron add --name "weekly-skill-review" --cron "0 10 * * 0" --session isolated --message "Execute weekly Skill audit"
```

### Verify and Manually Trigger

```bash
openclaw cron list
openclaw cron run --force daily-snapshot
```

---

## Appendix E: Headless Browser Management

### Skipped During Install? Install Separately Later

```bash
# Linux / WSL2 / macOS
bash ~/.openclaw/workspace/scripts/setup-browser.sh
```

```powershell
# Windows PowerShell (no WSL required)
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.openclaw\workspace\scripts\setup-browser.ps1"
```

The script auto-detects browsers (Chrome/Edge/Brave) + installs Playwright, writes config, and restarts the Gateway.

### Disable Browser

```bash
openclaw config set browser.enabled false
openclaw gateway restart
```

After disabling, the Agent can still use `web_fetch` (plain HTTP) to read web pages, but cannot execute JS or interact with pages.

### Re-enable

```bash
openclaw config set browser.enabled true
openclaw config set browser.headless true
openclaw gateway restart
```
