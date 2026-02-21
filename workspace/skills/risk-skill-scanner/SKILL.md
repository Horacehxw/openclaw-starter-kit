---
name: risky-skill-scan
description: Manual security audit guide for inspecting OpenClaw AgentSkills. Provides systematic checklist, pattern recognition guidance, and risk assessment framework for evaluating whether a skill is safe to use or potentially harmful. Use when asked to review a skill for security concerns, verify a skill is safe, or determine if a skill exhibits risky behavior.
---

# Risky Skill Inspection Guide

**This is a manual audit framework—not an automated scanner.** Use this guide to systematically review a skill's code, configuration, and behavior to assess security risks.

## When to Use This Skill

- You need to evaluate a skill before installing or enabling it
- You suspect a skill may be doing something harmful or unauthorized
- You want to establish a security review process for skills
- You're comparing multiple skills and need to assess their risk profiles

## Audit Process Overview

1. **Gather skill files** - Locate the skill directory and collect all code, config, and assets
2. **Static review** - Read through code looking for red flags (use checklists below)
3. **Behavioral analysis** - Understand what the skill actually does and who benefits
4. **Permission check** - Verify required capabilities match the skill's purpose
5. **Risk determination** - Assign severity and decide on installation

## Quick Checklist (Prioritized)

Start with these high-impact checks. If any trigger **CRITICAL** or **HIGH**, stop and investigate further before proceeding.

### 🔴 CRITICAL Risks (Immediate stop)
- [ ] Does it read `/etc/passwd`, `/etc/shadow`, SSH private keys, or browser data (Cookies/History)?
- [ ] Does it upload files/data to anonymous services (pastebin, file.io, anonfile, etc.)?
- [ ] Does it contain `eval(base64_decode(...))`, `exec(compile(...))`, or similar obfuscation?
- [ ] Does it include cryptocurrency mining code or DoS loops?
- [ ] Does it run `rm -rf /` or `kill -9 -1` (system destruction)?
- [ ] Does it use `sudo` without explicit, per-command user confirmation?

### 🟠 HIGH Risks (Caution required)
- [ ] Does it make network calls to hardcoded third-party endpoints (not configurable)?
- [ ] Does it access parent directories (`../`) escaping the workspace?
- [ ] Does it use `chmod 777` or world-writable permissions?
- [ ] Does it have `subprocess(..., shell=True)` with user input?
- [ ] Does it send data to analytics/telemetry services without opt-in?
- [ ] Does it request wildcard (`*`) permissions or file access?

### 🟡 MEDIUM Risks (Review needed)
- [ ] Does it make external API calls that could leak data if misused?
- [ ] Does it have infinite loops without clean exit conditions?
- [ ] Does it use hex/base64 blobs that could hide payloads?
- [ ] Does it import `*` (wildcard) making code harder to audit?
- [ ] Does it perform mass file operations (recursive `os.walk('*')`) without clear purpose?

### 🟢 LOW Risks (Best practice)
- [ ] Code clarity: Is logic straightforward and well-commented?
- [ ] Input validation: Are user inputs validated before use?
- [ ] Error handling: Are failures handled gracefully?
- [ ] Scope: Does the skill stay within its intended domain?

## Detailed Inspection Areas

### A. File System Operations

**Questions to ask:**
- What files does it read/write? Are they within the workspace or user-specified paths only?
- Does it traverse directories? If so, is there a clear limit?
- Does it access sensitive system files? Why?
- Does it use `../` to escape the workspace?

**Patterns to look for:**
```python
# RED FLAGS
open('/etc/passwd')
open('~/.ssh/id_rsa')
os.walk('*')
Path.rglob('*')
../  # parent directory access
```

**Safe alternatives:**
```python
# Use workspace-relative paths
workspace = os.getenv('OPENCLA_WORKSPACE')
file_path = os.path.join(workspace, user_provided_name)
```

### B. Network & Data Exfiltration

**Questions to ask:**
- Does the skill need to make network calls? Are they the core functionality?
- Are endpoints configurable? Are they hardcoded?
- Is there telemetry/analytics? Is it disclosed and opt-in?
- Does it upload data? Where? For what purpose?

**Patterns to look for:**
```python
# Be cautious
requests.post('https://hardcoded-endpoint.com/api', data=...)
urllib.request.urlopen('http://tracking.service.com')
upload_to_pastebin(content)
```

**Safe approach:**
- Endpoints should be configurable via environment or skill parameters
- No hidden data collection; user must explicitly consent
- Prefer local processing; network calls only when essential

### C. Privilege & Capability Use

**Questions to ask:**
- Does the skill request elevated execution? Is it truly necessary?
- Does it use `sudo`, `chmod 777`, or destructive commands?
- Could the same result be achieved with safer, user-initiated actions?

**Patterns to look for:**
```bash
# Dangerous
sudo rm -rf /
chmod 777 /some/file
kill -9 -1
```

**Safe approach:**
- Use OpenClaw's `elevated` tool system for privileged operations (user approval per command)
- Never privilege-escalate automatically
- Principle of least privilege

### D. Code Obfuscation & Suspicious Behavior

**Questions to ask:**
- Is the code readable? Or is there hidden logic?
- Are there infinite loops, long sleeps, or resource exhaustion patterns?
- Could the skill be doing something the user didn't explicitly request?

**Patterns to look for:**
```python
# Obfuscation
eval(base64.b64decode('...'))
compile(hex_string, ...)
exec(malicious_payload)

# Behavior risks
while True:  # without exit
time.sleep(10000)  # multi-hour sleep
mining_code = ...
```

**Safe approach:**
- Code should be clear and maintainable
- All loops have bounded iterations or explicit exit conditions
- No hidden payloads or encoded strings (unless clearly documented)

### E. Permission Alignment

**Check the skill's declared capabilities vs. actual needs:**
- Does `SKILL.md` description clearly state what the skill does?
- Do the file accesses, network calls, and tools used align with that description?
- Is the skill asking for broader permissions than its functionality requires?

**Example mismatch:**
- Description: "A simple markdown formatter"
- Code reads: `~/.ssh/`, uploads to external API → **MISMATCH**

## Risk Assessment Framework

### Severity Levels

| Level   | Meaning                                                                 | Action                                  |
|---------|-------------------------------------------------------------------------|------------------------------------------|
| CRITICAL| Immediate danger: data exfiltration, system compromise, malware        | **DO NOT INSTALL**. Investigate author. |
| HIGH    | Serious misuse: excessive permissions, suspicious network activity     | **High caution**. Require manual review.|
| MEDIUM  | Over-reaching but possibly justified                                   | Review justification; consider alternatives |
| LOW     | Best practice violations; minor issues                                 | Acceptable but could be improved        |
| INFO    | Documentation or structure notes                                       | No security concern                     |

**Confidence**: Percentage indicating how certain the finding is actually risky. Higher confidence = clearer pattern match.

### Categories

- **file_access** - Reading/writing files, path traversal, sensitive system files
- **network** - External API calls, data uploads, telemetry, hardcoded endpoints
- **privilege** - Elevation (`sudo`), destructive commands, permission changes
- **obfuscation** - Hidden code (base64, hex blobs, `eval`, `exec(compile(...))`)
- **behavior** - Infinite loops, DoS, crypto mining, suspicious timing
- **code_quality** - Wildcards, unclear logic that reduces auditability

### Common False Positives

Some risky patterns are legitimate in the right context. Always consider:

- **`/etc/passwd` read**: Acceptable for system admin tools, user management skills
- **External API calls**: Fine if that's the skill's core purpose (e.g., GitHub integration)
- **`sudo`**: OK in setup scripts (not runtime), or when using OpenClaw's elevated tool system
- **`shell=True`**: May be necessary for shell features; just be cautious with user input
- **Infinite loops**: Acceptable for daemons with proper exit signals
- **Hex strings**: Could be hashes (SHA256), colors, UUIDs—context matters

If you encounter a false positive:
1. Note the context that makes it safe
2. Consider if the code could be clearer to avoid the trigger
3. Document the exception in your audit report

## Example Audit Report

When asked to audit a skill, produce:

```
# Security Audit: skill-name

**Path**: /path/to/skill
**Auditor**: (your name)
**Date**: 2026-02-20

## Summary
- Overall risk: MEDIUM
- Findings: 3 HIGH, 2 MEDIUM, 4 LOW

## Critical/High Findings
1. [HIGH] Hardcoded external API endpoint in `scripts/main.py:45`
   - Current: `requests.post('https://tracking.example.com/...')`
   - Issue: Data sent to third-party without user configuration
   - Fix: Make endpoint configurable via environment variable

2. [HIGH] Parent directory access in `utils.py:12`
   - Current: `open('../config.json')`
   - Issue: Escapes workspace; could read unrelated files
   - Fix: Use workspace-relative paths only

## Medium Findings
...

## Conclusion
- Install? **No** - High findings require fixes first
- Recommended actions: 1) remove hardcoded endpoint, 2) restrict file access to workspace
```

## Decision Guide

After inspection, decide:

1. **Clean** - No findings or only LOW. Install freely.
2. **Review with mitigation** - MEDIUM findings that are justified. Document the justification.
3. **Reject** - Any HIGH without strong evidence of necessity. Seek alternative skill.
4. **Block** - Any CRITICAL. Do not install. Report to skill maintainer.

## Limitations

Manual inspection has limits:
- Cannot prove absence of hidden behavior
- Relies on auditor's experience and attention
- May miss sophisticated obfuscation or runtime-only effects
- Does not verify skill author trustworthiness

For high-stakes skills, combine with:
- Code review by multiple auditors
- Running in a sandboxed environment first
- Checking skill provenance (official vs. third-party)
- Monitoring runtime behavior with network filtering
