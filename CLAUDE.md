# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an **OpenClaw Agent Starter Kit** — an incremental extension pack on top of `openclaw onboard` defaults. It adds memory reliability, self-evolution capabilities, daily config snapshots, and security hardening to OpenClaw agents. Written in Bash scripts, Markdown config files, and JSON. **Primary language of docs and comments is Chinese.**

## Installation & Setup

```bash
# Linux / WSL2 / macOS
bash install.sh [workspace_path]

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File install.ps1 [-WorkspacePath "D:\my-agent"]
```

Default install target: `~/.openclaw/workspace/`

The installer runs 8 steps: prerequisite check → OpenClaw onboard automation (if not yet completed) → backup existing workspace → create directories → copy files & apply patches → install ClawdHub CLI → configure tool permissions → optional cron & browser setup.

## Key Commands

```bash
# Verify installation health
openclaw doctor

# Gateway management
openclaw gateway status
openclaw gateway start --foreground
openclaw gateway restart
systemctl --user status openclaw-gateway   # Linux/WSL2 systemd

# Cron tasks
openclaw cron list
openclaw cron run --force daily-snapshot

# Manual snapshot
bash ~/.openclaw/workspace/scripts/snapshot.sh

# Skill management via ClawdHub
clawdhub search "keyword"
clawdhub install <skill-name>
clawdhub update --all
clawdhub list
```

## Architecture

### Workspace Structure (`workspace/` → installed to `~/.openclaw/workspace/`)

- **Core agent config**: `BOOT.md` (session startup checklist), `MEMORY.md` (long-term memory template)
- **Daily logs**: `memory/YYYY-MM-DD.md` — per-day event logs
- **Self-evolution records**: `.learnings/` — `LEARNINGS.md`, `ERRORS.md`, `FEATURE_REQUESTS.md` with structured templates (status: open/resolved/promoted, priority: P1/P2/P3)
- **Skills**: `skills/<skill-name>/SKILL.md` — YAML frontmatter + markdown definition. Four built-in: `self-evolution` (learning & improvement), `daily-snapshot` (config backup), `risk-skill-scanner` (single skill security audit), and `scan-all-risk-skill` (batch risk scanning)
- **Patches**: `patches/AGENTS.patch.md`, `patches/TOOLS.patch.md` — appended to default AGENTS.md and TOOLS.md (never modifies existing content)
- **Scripts**: `scripts/snapshot.sh` (deterministic backup), `scripts/setup-cron.sh` (cron config), `scripts/setup-browser.sh` (optional headless Chromium for Linux/WSL2/macOS), `scripts/setup-browser.ps1` (optional headless browser for Windows)
- **Snapshots**: `snapshots/YYYY-MM-DD/` — daily config backups with CHANGELOG.md, 30-day retention (monthly 1st preserved permanently)

### Key Design Principles

1. **Append-only patching**: The kit only appends to AGENTS.md and TOOLS.md. It never modifies SOUL.md, IDENTITY.md, USER.md, HEARTBEAT.md, or BOOTSTRAP.md.
2. **Deterministic scripts**: File copy, diff, and cleanup in `snapshot.sh` are pure bash — no LLM dependency. The agent only adds descriptive summaries after script execution.
3. **Allowlist security**: `exec-approvals.json` uses allowlist mode with `ask: "on-miss"` — unlisted commands require user confirmation. Dangerous ops (`rm`, `sudo`, `dd`, `mkfs`) are denied in `.claude/settings.local.json`.
4. **Learning promotion**: Records in `.learnings/` can be "promoted" to core config files (AGENTS.md, SOUL.md, TOOLS.md, MEMORY.md) when broadly applicable.
5. **HEARTBEAT risk alerts**: When daily risk scan detects CRITICAL-level risks in installed Skills, a structured warning block is appended to HEARTBEAT.md (with `待确认` status). The agent reminds the user during heartbeat until acknowledged.

### Cron Automation

Four built-in tasks (configured by `setup-cron.sh`):
- `daily-risk-scan` (01:00) — scans all installed Skills for security risks; CRITICAL findings trigger HEARTBEAT alerts
- `daily-snapshot` (02:00) — config backup + CHANGELOG generation
- `daily-memory-review` (23:00) — memory organization
- `weekly-skill-review` (Sunday 10:00) — skill auditing

All run with `--session isolated` for independent execution.

## File Conventions

- Core markdown: UPPERCASE.md (SOUL.md, BOOT.md, MEMORY.md)
- Daily logs: `memory/YYYY-MM-DD.md`
- Learning records: `.learnings/UPPERCASE_UNDERSCORE.md`
- Scripts: `scripts/lowercase-with-dash.sh`
- Skills: `skills/<skill-name>/SKILL.md` with YAML frontmatter (name, description, metadata)
