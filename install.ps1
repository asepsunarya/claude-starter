<#
.SYNOPSIS
  Pasang claude-code-starter ke sebuah project, atau ke level user (global).

.DESCRIPTION
  Sumber yang disalin adalah isi folder template\ di repo ini.

  Mode project (default):
    Menyalin ke project target:
      - .claude/skills, commands, agents, references, hooks, UPSTREAM.md (generated;
        ditimpa hanya dengan -Force)
      - .claude/rules/*.md (hanya kalau belum ada; TIDAK pernah ditimpa)
      - CLAUDE.md (hanya kalau belum ada; kalau sudah ada, template disimpan
        sebagai CLAUDE.starter.md)
    lalu menambahkan baris .gitignore yang belum ada.

  Mode global (-Global):
    Menyalin skills, commands, agents, references, hooks, UPSTREAM.md ke
    ~/.claude/ sehingga tersedia di semua project lokal. Path ".claude/..."
    di dalam file yang disalin ditulis ulang menjadi "~/.claude/...".
    CLAUDE.md dan rules tetap per project. Tidak berlaku untuk sesi
    Claude Code cloud (lihat README).

.PARAMETER Project
  Path project target. Default: folder kerja saat ini.

.PARAMETER Global
  Pasang ke ~/.claude (berlaku untuk semua project lokal).

.PARAMETER Force
  Timpa file GENERATED yang sudah ada (skills, commands, agents, references,
  hooks, UPSTREAM.md). CLAUDE.md dan .claude/rules/ tidak pernah ditimpa.

.PARAMETER UserDir
  Folder konfigurasi user Claude Code untuk mode -Global. Default: ~/.claude.
  Dipakai untuk pengujian.

.EXAMPLE
  .\install.ps1 -Project C:\src\my-app
  .\install.ps1 -Project C:\src\my-app -Force      # setelah update upstream
  .\install.ps1 -Global
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Project C:\src\my-app
#>
[CmdletBinding()]
param(
  [string]$Project = "",
  [switch]$Global,
  [switch]$Force,
  [string]$UserDir = ""
)

$ErrorActionPreference = "Stop"
$Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)
$KitRoot     = $PSScriptRoot
$KitTemplate = Join-Path $KitRoot "template"
$KitClaude   = Join-Path $KitTemplate ".claude"
$Generated   = @("skills", "commands", "agents", "references", "hooks")
$script:copied  = 0
$script:skipped = 0

if (-not (Test-Path -LiteralPath $KitClaude)) {
  throw "Folder template\.claude tidak ditemukan di $KitRoot. Jalankan skrip ini dari clone repo claude-code-starter yang utuh."
}

function Copy-Merge([string]$Src, [string]$Dst, [switch]$KeepExisting) {
  # Salin rekursif. File yang sudah ada dilewati, kecuali -Force (dan tidak -KeepExisting).
  if (-not (Test-Path -LiteralPath $Src)) { return }
  $srcFull = (Resolve-Path -LiteralPath $Src).Path
  Get-ChildItem -LiteralPath $srcFull -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($srcFull.Length).TrimStart('\', '/')
    $target = Join-Path $Dst $rel
    $exists = Test-Path -LiteralPath $target
    if ($exists -and ($KeepExisting -or -not $Force)) { $script:skipped++; return }
    $dir = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    $script:copied++
  }
}

function Copy-Stamp([string]$DestClaude) {
  $stamp = Join-Path $DestClaude "UPSTREAM.md"
  if ((Test-Path -LiteralPath $stamp) -and -not $Force) { $script:skipped++; return }
  if (-not (Test-Path -LiteralPath $DestClaude)) { New-Item -ItemType Directory -Force $DestClaude | Out-Null }
  Copy-Item -LiteralPath (Join-Path $KitClaude "UPSTREAM.md") -Destination $stamp -Force
  $script:copied++
}

function Rewrite-Files([string]$Dir, [scriptblock]$Rewrite) {
  if (-not (Test-Path -LiteralPath $Dir)) { return }
  Get-ChildItem -LiteralPath $Dir -Recurse -File -Filter *.md | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $new  = & $Rewrite $text
    if ($new -ne $text) { [System.IO.File]::WriteAllText($_.FullName, $new, $Utf8NoBom) }
  }
}

function Warn-IfPluginInstalled {
  $pluginsDir = Join-Path $HOME ".claude\plugins"
  if (Test-Path -LiteralPath $pluginsDir) {
    $hit = Get-ChildItem -LiteralPath $pluginsDir -Recurse -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "*agent-skills*" } | Select-Object -First 1
    if ($hit) {
      Write-Warning "Plugin agent-skills tampaknya sudah terpasang ($($hit.FullName))."
      Write-Warning "Memasang kit ini juga akan membuat skill/command ganda. Pilih salah satu."
    }
  }
}

# ---------------------------------------------------------------------------
# Mode global
# ---------------------------------------------------------------------------
if ($Global) {
  $dest = $UserDir
  if ([string]::IsNullOrWhiteSpace($dest)) { $dest = Join-Path $HOME ".claude" }
  if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Force $dest | Out-Null }
  $dest = (Resolve-Path -LiteralPath $dest).Path
  Warn-IfPluginInstalled

  foreach ($sub in $Generated) {
    Copy-Merge (Join-Path $KitClaude $sub) (Join-Path $dest $sub)
  }
  Copy-Stamp $dest

  # Path relatif-root-project di dalam file generated -> layout ~/.claude.
  # Regex idempoten: tidak menyentuh yang sudah "~/.claude/...".
  $toUserLayout = {
    param($t)
    return [regex]::Replace($t, '(?<![/\w~])\.claude/(?=(skills|references|agents)/)', '~/.claude/')
  }
  foreach ($sub in @("commands", "agents", "skills")) { Rewrite-Files (Join-Path $dest $sub) $toUserLayout }
  Rewrite-Files (Join-Path $dest "hooks") {
    param($t)
    return $t.Replace('${CLAUDE_PROJECT_DIR}/.claude/hooks/', '$HOME/.claude/hooks/')
  }

  Write-Host ""
  Write-Host "Global install selesai -> $dest"
  Write-Host "  disalin : $script:copied file"
  Write-Host "  dilewati: $script:skipped file (sudah ada; pakai -Force untuk menimpa yang generated)"
  Write-Host ""
  Write-Host "Langkah berikutnya, di setiap project:"
  Write-Host "  1. Salin template\CLAUDE.md dari repo ini ke root project, lalu isi Tech Stack, Commands, Boundaries."
  Write-Host "     (path .claude/... di dalamnya otomatis dibaca sebagai ~/.claude/... bila project tidak punya .claude/skills)"
  Write-Host "  2. (Opsional) salin template\.claude\rules\ ke project untuk rule per-path."
  Write-Host "  3. Jalankan Claude Code di project itu; coba /spec atau /review."
  Write-Host "  4. (Opsional) hooks ada di $dest\hooks; daftarkan di ~/.claude/settings.json memakai path `$HOME/.claude/hooks/<skrip>.sh. Butuh Git Bash + jq."
  exit 0
}

# ---------------------------------------------------------------------------
# Mode project
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Project)) { $Project = (Get-Location).Path }
if (-not (Test-Path -LiteralPath $Project)) { New-Item -ItemType Directory -Force $Project | Out-Null }
$Project = (Resolve-Path -LiteralPath $Project).Path

$projN = $Project.TrimEnd('\', '/')
if (($projN -ieq $KitRoot.TrimEnd('\', '/')) -or ($projN -ieq $KitTemplate.TrimEnd('\', '/'))) {
  throw "Target sama dengan folder kit. Jalankan dengan -Project <path project> atau -Global."
}

Warn-IfPluginInstalled
$projClaude = Join-Path $Project ".claude"

# 1. Folder generated (ditimpa hanya dengan -Force)
foreach ($sub in $Generated) {
  Copy-Merge (Join-Path $KitClaude $sub) (Join-Path $projClaude $sub)
}
Copy-Stamp $projClaude

# 2. Rules: milik project setelah disalin; tidak pernah ditimpa
Copy-Merge (Join-Path $KitClaude "rules") (Join-Path $projClaude "rules") -KeepExisting

# 3. CLAUDE.md: tidak pernah ditimpa
$claudeMd = Join-Path $Project "CLAUDE.md"
if (Test-Path -LiteralPath $claudeMd) {
  $alt = Join-Path $Project "CLAUDE.starter.md"
  Copy-Item -LiteralPath (Join-Path $KitTemplate "CLAUDE.md") -Destination $alt -Force
  Write-Host "CLAUDE.md sudah ada dan tidak disentuh; template disimpan sebagai CLAUDE.starter.md untuk digabung manual."
} else {
  Copy-Item -LiteralPath (Join-Path $KitTemplate "CLAUDE.md") -Destination $claudeMd -Force
  $script:copied++
}

# 4. .gitignore (tambahkan baris yang belum ada)
$giKit    = Join-Path $KitTemplate ".gitignore"
$giTarget = Join-Path $Project ".gitignore"
$wanted   = Get-Content -LiteralPath $giKit | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }
$existing = @()
if (Test-Path -LiteralPath $giTarget) { $existing = @(Get-Content -LiteralPath $giTarget | ForEach-Object { $_.Trim() }) }
$missing  = @($wanted | Where-Object { $existing -notcontains $_ })
if ($missing.Count -gt 0) {
  $block = ""
  if ($existing.Count -gt 0) {
    $raw = [System.IO.File]::ReadAllText($giTarget)
    if ($raw.Length -gt 0 -and -not $raw.EndsWith("`n")) { $block += "`n" }
    $block += "`n"
  }
  $block += "# claude-code-starter`n" + ($missing -join "`n") + "`n"
  [System.IO.File]::AppendAllText($giTarget, $block, $Utf8NoBom)
  Write-Host ".gitignore: ditambahkan $($missing.Count) baris."
}

Write-Host ""
Write-Host "Install selesai -> $Project"
Write-Host "  disalin : $script:copied file"
Write-Host "  dilewati: $script:skipped file (sudah ada; -Force menimpa yang generated saja)"
Write-Host ""
Write-Host "Langkah berikutnya:"
Write-Host "  1. Buka CLAUDE.md, isi Tech Stack, Commands, Project Structure, Conventions, Boundaries."
Write-Host "  2. Sesuaikan/hapus .claude\rules\*.md yang tidak relevan dengan stack-mu."
Write-Host "  3. Commit .claude\ dan CLAUDE.md, lalu jalankan Claude Code di project ini (lokal atau cloud); mulai dengan /spec atau /review."
Write-Host "  4. (Opsional) hooks: lihat .claude\hooks\*.md; butuh Git Bash + jq (di cloud sudah tersedia)."
