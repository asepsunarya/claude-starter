<#
.SYNOPSIS
  Sinkronkan template kit ini dengan upstream addyosmani/agent-skills.

.DESCRIPTION
  Meng-clone (atau memakai salinan lokal) repo addyosmani/agent-skills, lalu
  membangun ulang folder generated di template\.claude\ sambil menyesuaikan path:

    skills/<name>/SKILL.md      -> template/.claude/skills/<name>/SKILL.md
    references/*.md             -> template/.claude/references/*.md
    agents/*.md                 -> template/.claude/agents/*.md
    .claude/commands/*.md       -> template/.claude/commands/*.md  (prefix "agent-skills:" dibuang)
    hooks/*.sh, hooks/*.md      -> template/.claude/hooks/         (session-start.sh dan *-test.sh dilewati)

  Hasil dibangun di folder staging dulu; folder lama baru diganti setelah
  semuanya sukses. File milik kit (template/CLAUDE.md, template/.claude/rules/,
  README.md, install.ps1) TIDAK disentuh.

.PARAMETER Source
  Path ke salinan lokal agent-skills: git clone, atau hasil ekstrak ZIP dari
  GitHub (info commit lalu ditulis "n/a"). Jika kosong, repo di-clone ke
  folder temp (butuh git di PATH).

.EXAMPLE
  .\scripts\update-from-upstream.ps1
  .\scripts\update-from-upstream.ps1 -Source C:\src\agent-skills
#>
[CmdletBinding()]
param(
  [string]$Source = ""
)

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$KitRoot   = Split-Path -Parent $PSScriptRoot
$ClaudeDir = Join-Path $KitRoot "template\.claude"
$Generated = @("skills", "references", "agents", "commands", "hooks")

function Read-Text([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}
function Write-Text([string]$Path, [string]$Content) {
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}
function Copy-Rewritten([string]$From, [string]$To, [scriptblock]$Rewrite) {
  $text = Read-Text $From
  if ($Rewrite) { $text = & $Rewrite $text }
  Write-Text $To $text
}

# ---------------------------------------------------------------------------
# 1. Ambil upstream
# ---------------------------------------------------------------------------
$tempClone = $null
$haveGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
if ([string]::IsNullOrWhiteSpace($Source)) {
  if (-not $haveGit) {
    throw "git tidak ditemukan di PATH. Install Git for Windows, atau beri -Source <path clone/ZIP agent-skills>."
  }
  $tempClone = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-skills-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
  Write-Host "Cloning addyosmani/agent-skills -> $tempClone"
  git clone --depth 1 --quiet https://github.com/addyosmani/agent-skills.git $tempClone
  if ($LASTEXITCODE -ne 0) { throw "git clone gagal (exit $LASTEXITCODE)" }
  $Source = $tempClone
}
$Source = (Resolve-Path -LiteralPath $Source).Path

# ---------------------------------------------------------------------------
# 2. Pre-flight: tolak source di dalam kit, pastikan semua folder input ada
#    (dicek SEBELUM ada yang dihapus)
# ---------------------------------------------------------------------------
$srcN = $Source.TrimEnd('\', '/')
$kitN = $KitRoot.TrimEnd('\', '/')
if ($srcN -ieq $kitN -or $srcN.StartsWith($kitN + '\', [StringComparison]::OrdinalIgnoreCase)) {
  throw "-Source menunjuk ke dalam folder kit ($KitRoot). Beri path clone agent-skills, atau kosongkan agar di-clone otomatis."
}
foreach ($need in @("skills", "references", "agents", ".claude\commands", "hooks")) {
  if (-not (Test-Path -LiteralPath (Join-Path $Source $need) -PathType Container)) {
    throw "Folder '$need' tidak ditemukan di $Source. Pastikan ini salinan lengkap repo agent-skills."
  }
}

$upstreamCommit = ""
$upstreamDate   = ""
if ($haveGit -and (Test-Path -LiteralPath (Join-Path $Source ".git"))) {
  try {
    $upstreamCommit = (git -C $Source rev-parse --short HEAD)
    $upstreamDate   = (git -C $Source log -1 --format=%cs)
  } catch { $upstreamCommit = ""; $upstreamDate = "" }
}
if ([string]::IsNullOrWhiteSpace($upstreamCommit)) { $upstreamCommit = "n/a"; $upstreamDate = "sumber bukan git clone" }

$version = "unknown"
$pluginJson = Join-Path $Source ".claude-plugin\plugin.json"
if (Test-Path -LiteralPath $pluginJson) { $version = (Get-Content -LiteralPath $pluginJson -Raw | ConvertFrom-Json).version }

# ---------------------------------------------------------------------------
# 3. Bangun di folder staging
# ---------------------------------------------------------------------------
$stage = Join-Path $KitRoot (".claude.new-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force $stage | Out-Null

# Path repo-relative "skills/<name>" dan "references/<file>.md" -> ".claude/...".
# Lookbehind mencegah menyentuh "../skills/", "./skills/", atau ".claude/skills/".
$rxSkills = '(?<![\w./-])skills/(?=[a-z0-9-]+\b)'
$rxRefs   = '(?<![\w./-])references/(?=[a-z-]+\.md)'

try {
  # 3a. Skills (salin semua file; rewrite hanya file teks)
  $skillRewrite = {
    param($t)
    return [regex]::Replace($t, $rxSkills, '.claude/skills/')
  }
  $skillsSrc = Join-Path $Source "skills"
  Get-ChildItem -LiteralPath $skillsSrc -Recurse -File | ForEach-Object {
    $rel  = $_.FullName.Substring($skillsSrc.Length).TrimStart('\', '/')
    $dest = Join-Path (Join-Path $stage "skills") $rel
    if ($_.Extension -in @(".md", ".sh", ".txt", ".json", ".yml", ".yaml")) {
      Copy-Rewritten $_.FullName $dest $skillRewrite
    } else {
      $d = Split-Path -Parent $dest
      if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
      Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
    }
  }

  # 3b. References (checklist bersama)
  Get-ChildItem -LiteralPath (Join-Path $Source "references") -Filter *.md | ForEach-Object {
    Copy-Rewritten $_.FullName (Join-Path $stage ("references\" + $_.Name)) $null
  }

  # 3c. Agents (subagent personas)
  $agentRewrite = {
    param($t)
    # docs/agents.md tidak ikut disalin; materi yang sama ada di orchestration-patterns.md
    $t = $t.Replace('[docs/agents.md](../docs/agents.md)', '[references/orchestration-patterns.md](../references/orchestration-patterns.md)')
    $t = [regex]::Replace($t, $rxRefs, '.claude/references/')
    $t = [regex]::Replace($t, $rxSkills, '.claude/skills/')
    return $t
  }
  Get-ChildItem -LiteralPath (Join-Path $Source "agents") -Filter *.md |
    Where-Object { $_.Name -notmatch '^readme\.md$' } | ForEach-Object {
      Copy-Rewritten $_.FullName (Join-Path $stage ("agents\" + $_.Name)) $agentRewrite
    }

  # 3d. Commands (slash command Claude Code)
  $personaNote = '**Persona resolution.** Claude Code resolves same-named subagents by location: a project''s `.claude/agents/` overrides `~/.claude/agents/`. With a project install of this kit, the personas in `.claude/agents/` *are* the project-level files; to customise one, edit it there and keep a copy, because `install.ps1 -Force` after an upstream update overwrites it. With a global install (`~/.claude/agents/`), a project-level `.claude/agents/<name>.md` overrides the kit''s version.'
  $commandRewrite = {
    param($t)
    # Skill di-install lokal, bukan sebagai plugin -> namespace "agent-skills:" dibuang
    $t = $t.Replace('agent-skills:', '')
    $t = [regex]::Replace($t, $rxRefs, '.claude/references/')
    # Paragraf tentang prioritas subagent ditulis untuk mode plugin; tulis ulang untuk kit lokal
    $t = [regex]::Replace($t, '(?m)^\*\*Persona resolution\.\*\*.*$', $personaNote.Replace('$', '$$'))
    return $t
  }
  Get-ChildItem -LiteralPath (Join-Path $Source ".claude\commands") -Filter *.md | ForEach-Object {
    Copy-Rewritten $_.FullName (Join-Path $stage ("commands\" + $_.Name)) $commandRewrite
  }

  # 3e. Hooks (opsional; butuh bash + jq). session-start.sh dilewati: hanya untuk
  #     host tanpa skill routing native, sedangkan Claude Code sudah punya.
  $hookRewrite = {
    param($t)
    $t = $t.Replace('${CLAUDE_PROJECT_DIR}/hooks/', '${CLAUDE_PROJECT_DIR}/.claude/hooks/')
    $t = $t.Replace('bash hooks/', 'bash .claude/hooks/')
    $t = $t.Replace(
      'If you installed `agent-skills` elsewhere (e.g. as a shared plugin under `~/agent-skills`), replace `${CLAUDE_PROJECT_DIR}/.claude/hooks/...` with the absolute path to each script.',
      'If you installed this kit globally (`install.ps1 -Global`), the scripts live in `~/.claude/hooks/`: register them in `~/.claude/settings.json` and use `$HOME/.claude/hooks/<script>.sh` instead of `${CLAUDE_PROJECT_DIR}/.claude/hooks/<script>.sh`.')
    return $t
  }
  Get-ChildItem -LiteralPath (Join-Path $Source "hooks") -File |
    Where-Object { $_.Name -notmatch '-test\.sh$|^session-start\.sh$' } | ForEach-Object {
      Copy-Rewritten $_.FullName (Join-Path $stage ("hooks\" + $_.Name)) $hookRewrite
    }

  # 3f. Catatan versi upstream (dibaca dari dalam project setelah disalin)
  $stamp = @"
# Upstream

Konten di .claude/skills, .claude/references, .claude/agents, .claude/commands,
dan .claude/hooks di-generate dari:

- Repo    : https://github.com/addyosmani/agent-skills
- Versi   : $version
- Commit  : $upstreamCommit ($upstreamDate)
- Lisensi : MIT (c) Addy Osmani

Jangan edit file di folder-folder itu secara manual. Untuk memperbarui,
jalankan ``scripts\update-from-upstream.ps1`` di repo claude-code-starter lalu
salin ulang ke project ini (``install.ps1 -Project <path> -Force``).
Kustomisasi lokal sebaiknya ditaruh di CLAUDE.md atau .claude/rules/.
"@
  Write-Text (Join-Path $stage "UPSTREAM.md") $stamp

  # -------------------------------------------------------------------------
  # 4. Semua sukses: ganti folder generated yang lama dengan hasil staging
  # -------------------------------------------------------------------------
  if (-not (Test-Path -LiteralPath $ClaudeDir)) { New-Item -ItemType Directory -Force $ClaudeDir | Out-Null }
  foreach ($sub in $Generated) {
    $old = Join-Path $ClaudeDir $sub
    if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Recurse -Force }
    Move-Item -LiteralPath (Join-Path $stage $sub) -Destination $old
  }
  Copy-Item -LiteralPath (Join-Path $stage "UPSTREAM.md") -Destination (Join-Path $ClaudeDir "UPSTREAM.md") -Force
}
finally {
  if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
  if ($tempClone -and (Test-Path -LiteralPath $tempClone)) { Remove-Item -LiteralPath $tempClone -Recurse -Force }
}

$nSkills = (Get-ChildItem -LiteralPath (Join-Path $ClaudeDir "skills") -Directory).Count
$nCmds   = (Get-ChildItem -LiteralPath (Join-Path $ClaudeDir "commands") -Filter *.md).Count
$nAgents = (Get-ChildItem -LiteralPath (Join-Path $ClaudeDir "agents") -Filter *.md).Count
$nRefs   = (Get-ChildItem -LiteralPath (Join-Path $ClaudeDir "references") -Filter *.md).Count
Write-Host "Selesai: $nSkills skills, $nCmds commands, $nAgents agents, $nRefs references (upstream v$version @ $upstreamCommit)"
