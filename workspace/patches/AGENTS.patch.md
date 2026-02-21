
---

<!-- ═══ Starter Kit 扩展（追加到默认 AGENTS.md 之后）═══ -->

## 学习记录

遇到错误、发现技巧、收到功能需求时，记录到 `.learnings/`：
- `LEARNINGS.md` — 通用教训和技巧
- `ERRORS.md` — 错误及解决方案
- `FEATURE_REQUESTS.md` — 用户提出的功能需求

## 配置快照

每天凌晨由 cron 触发配置快照，保存到 `snapshots/YYYY-MM-DD/`。用户说"恢复到某天的配置"时，从快照目录恢复。参见 `skills/daily-snapshot/SKILL.md`。

## Skill 获取

遇到无法完成的任务时，可主动搜索 ClawdHub（`clawdhub search "关键词"`）。安装前告知用户，获得确认后执行。

## 风险扫描

安装新 Skill 后应主动进行风险扫描。每日 01:00 由 cron 自动扫描所有已安装 Skill。
参见 `skills/risk-skill-scanner/SKILL.md` 和 `skills/scan-all-risk-skill/SKILL.md`。

### CRITICAL 风险处理流程

扫描发现 CRITICAL 风险时：

1. 检查 HEARTBEAT.md 中是否已有该 Skill 的「待确认」警告（避免重复）
2. 如无，在 HEARTBEAT.md 末尾追加以下格式：

   ## ⚠️ 风险警告 (YYYY-MM-DD HH:MM)
   **Skill**: <skill-name>
   **风险级别**: CRITICAL
   **发现**: <具体描述>
   **建议操作**: 立即禁用或卸载该 Skill
   **状态**: 待确认

3. 记录到 .learnings/ERRORS.md
4. 用户确认知悉后，将「待确认」改为「已确认 YYYY-MM-DD」
