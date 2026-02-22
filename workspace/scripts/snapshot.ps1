# ============================================================
# snapshot.ps1 — 确定性配置快照脚本 (Windows)
# 用法:   powershell -ExecutionPolicy Bypass -File snapshot.ps1 [workspace_path]
# 功能:   复制核心配置 → diff → 生成变更摘要 → 清理旧快照
# 设计:   所有文件操作是确定性的，不依赖 LLM
# ============================================================

param(
    [string]$WorkspacePath = ""
)

if ($WorkspacePath -eq "") {
    $WorkspacePath = Join-Path $env:USERPROFILE ".openclaw\workspace"
}

$Today = Get-Date -Format "yyyy-MM-dd"
$Now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$SnapDir = Join-Path $WorkspacePath "snapshots\$Today"
$Changelog = Join-Path $SnapDir "CHANGELOG.md"

# ── 核心配置文件列表 ──────────────────────────────────────────
$CoreFiles = @(
    "SOUL.md"
    "IDENTITY.md"
    "AGENTS.md"
    "USER.md"
    "TOOLS.md"
    "MEMORY.md"
    "HEARTBEAT.md"
    "BOOT.md"
    "BOOTSTRAP.md"
)

# ── 辅助函数 ──────────────────────────────────────────────────
function Log { param($msg) Write-Host "[snapshot] $(Get-Date -Format 'HH:mm:ss') $msg" }

# ── 1. 创建快照目录 ──────────────────────────────────────────
Log "创建快照目录: $SnapDir"
New-Item -ItemType Directory -Path (Join-Path $SnapDir "skills") -Force | Out-Null

# ── 2. 复制核心配置文件 ──────────────────────────────────────
$Copied = 0
$Missing = 0
foreach ($f in $CoreFiles) {
    $src = Join-Path $WorkspacePath $f
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $SnapDir $f) -Force
        $Copied++
    } else {
        $Missing++
    }
}
Log "核心文件: 复制 $Copied 个, 缺失 $Missing 个"

# ── 3. 复制 Skills ───────────────────────────────────────────
$SkillCount = 0
$skillsSrc = Join-Path $WorkspacePath "skills"
if (Test-Path $skillsSrc) {
    Copy-Item -Path "$skillsSrc\*" -Destination (Join-Path $SnapDir "skills") -Recurse -Force -ErrorAction SilentlyContinue
    $SkillCount = (Get-ChildItem -Path (Join-Path $SnapDir "skills") -Recurse -Filter "SKILL.md" -ErrorAction SilentlyContinue | Measure-Object).Count
    Log "Skills: 复制 $SkillCount 个"
}

# ── 4. 复制 .learnings ──────────────────────────────────────
$learnSrc = Join-Path $WorkspacePath ".learnings"
if (Test-Path $learnSrc) {
    $learnDst = Join-Path $SnapDir ".learnings"
    New-Item -ItemType Directory -Path $learnDst -Force | Out-Null
    Copy-Item -Path "$learnSrc\*.md" -Destination $learnDst -Force -ErrorAction SilentlyContinue
}

# ── 5. 查找上一次快照并 diff ─────────────────────────────────
$PrevSnap = ""
$ChangedFiles = @()

$snapParent = Join-Path $WorkspacePath "snapshots"
if (Test-Path $snapParent) {
    $prevDirs = Get-ChildItem -Path $snapParent -Directory |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' -and $_.Name -ne $Today } |
        Sort-Object Name -Descending
    foreach ($d in $prevDirs) {
        if (Test-Path (Join-Path $d.FullName "SOUL.md")) {
            $PrevSnap = $d.FullName
            break
        }
    }
}

$PrevDate = "(无)"
if ($PrevSnap -ne "") {
    $PrevDate = Split-Path -Leaf $PrevSnap
    Log "对比上次快照: $PrevDate"

    foreach ($f in $CoreFiles) {
        $old = Join-Path $PrevSnap $f
        $new = Join-Path $SnapDir $f
        $oldExists = Test-Path $old
        $newExists = Test-Path $new
        if ($oldExists -and $newExists) {
            $oldContent = Get-Content $old -ErrorAction SilentlyContinue
            $newContent = Get-Content $new -ErrorAction SilentlyContinue
            $diff = Compare-Object -ReferenceObject ($oldContent ?? @()) -DifferenceObject ($newContent ?? @()) -ErrorAction SilentlyContinue
            if ($diff) {
                $ChangedFiles += $f
            }
        } elseif (-not $oldExists -and $newExists) {
            $ChangedFiles += "$f (新增)"
        } elseif ($oldExists -and -not $newExists) {
            $ChangedFiles += "$f (已删除)"
        }
    }
} else {
    Log "没有找到历史快照，这是首次快照"
}

# ── 6. 生成 CHANGELOG.md ────────────────────────────────────
Log "生成 CHANGELOG.md"

$clContent = @"
# 快照: $Today

**快照时间**: $Now
**上次快照**: $PrevDate
**核心文件**: $Copied 个已复制
**Skills**: $SkillCount 个

## 文件变更

"@

if ($ChangedFiles.Count -eq 0) {
    if ($PrevSnap -eq "") {
        $clContent += "首次快照，无历史对比。`n"
    } else {
        $clContent += "无变更（所有文件与上次快照一致）。`n"
    }
} else {
    $clContent += "以下文件自 $PrevDate 以来有变更：`n`n"
    foreach ($f in $ChangedFiles) {
        $clContent += "- ``$f```n"
    }

    # Diff 统计
    $clContent += "`n### Diff 统计`n`n``````n"
    foreach ($f in $ChangedFiles) {
        $cleanF = $f -replace ' \(.*\)', ''
        $old = Join-Path $PrevSnap $cleanF
        $new = Join-Path $SnapDir $cleanF
        if ((Test-Path $old) -and (Test-Path $new)) {
            $oldContent = Get-Content $old -ErrorAction SilentlyContinue
            $newContent = Get-Content $new -ErrorAction SilentlyContinue
            $diff = Compare-Object -ReferenceObject ($oldContent ?? @()) -DifferenceObject ($newContent ?? @()) -ErrorAction SilentlyContinue
            $added = ($diff | Where-Object { $_.SideIndicator -eq "=>" } | Measure-Object).Count
            $removed = ($diff | Where-Object { $_.SideIndicator -eq "<=" } | Measure-Object).Count
            $clContent += "${cleanF}: +$added -$removed 行`n"
        } else {
            $clContent += "$f`n"
        }
    }
    $clContent += "```````n"
}

$clContent += "`n---`n_快照由 snapshot.ps1 自动生成。Agent 可在下方追加描述性总结。_`n"

Set-Content -Path $Changelog -Value $clContent -Encoding UTF8

# ── 7. 清理旧快照（>30天，保留每月1日） ─────────────────────
$DeletedCount = 0
$Cutoff = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

Log "清理 $Cutoff 之前的快照 (保留每月1日)"
if (Test-Path $snapParent) {
    $oldDirs = Get-ChildItem -Path $snapParent -Directory |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' }
    foreach ($d in $oldDirs) {
        # 保留每月 1 日
        if ($d.Name -match '-01$') { continue }
        # 删除超过 30 天的
        if ($d.Name -lt $Cutoff) {
            Remove-Item -Path $d.FullName -Recurse -Force
            $DeletedCount++
        }
    }
}
if ($DeletedCount -gt 0) {
    Log "清理了 $DeletedCount 个旧快照"
}

# ── 8. 写入今日 daily log ────────────────────────────────────
$DailyLog = Join-Path $WorkspacePath "memory\$Today.md"
if (Test-Path $DailyLog) {
    $logEntry = @"

## 配置快照

- 时间: $Now
- 文件: $Copied 个核心 + $SkillCount 个 Skill
"@
    if ($ChangedFiles.Count -gt 0) {
        $logEntry += "- 变更: $($ChangedFiles -join ', ')`n"
    } else {
        $logEntry += "- 变更: 无`n"
    }
    if ($DeletedCount -gt 0) {
        $logEntry += "- 清理: $DeletedCount 个旧快照`n"
    }
    Add-Content -Path $DailyLog -Value $logEntry -Encoding UTF8
}

# ── 完成 ─────────────────────────────────────────────────────
Log "✅ 快照完成: $SnapDir"
Log "   CHANGELOG: $Changelog"
Write-Host ""
