# claude-code-starter

Starter pack konfigurasi **Claude Code** supaya pengerjaan kode lebih disiplin
dan rapi: spec dulu, rencana kecil-kecil, implementasi per irisan dengan test,
review sebelum merge, lalu ship dengan checklist. Dibangun dari
[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
(v0.6.12, MIT) dan disusun ulang menjadi layout `.claude/` lokal yang tinggal
dicopas ke repo mana pun, tanpa perlu install plugin. Berlaku untuk Claude Code
lokal maupun cloud.

```
DEFINE        PLAN        BUILD        VERIFY       REVIEW        SHIP
/spec   ───▶  /plan  ───▶ /build  ───▶ /test  ───▶  /review ───▶  /ship
SPEC.md       tasks/      commit per   test gagal   5 sumbu       go / no-go
              plan.md     task         dulu         + severity    + rollback
```

## Isi repo

```
.
├── README.md                  ← file ini (jangan dicopas ke project)
├── CLAUDE.md                  ← aturan untuk memelihara repo ini (jangan dicopas)
├── install.ps1                ← pemasang otomatis (Windows PowerShell)
├── scripts/
│   └── update-from-upstream.ps1   ← sinkron ulang dari addyosmani/agent-skills
└── template/                  ← INI yang dicopas ke root project
    ├── CLAUDE.md              ← template rules file project (ISI bagian [kurung])
    ├── .gitignore             ← baris ignore yang disarankan
    └── .claude/
        ├── skills/        25 skill (SKILL.md per folder) — otomatis aktif sesuai konteks
        ├── commands/      9 slash command: /spec /constraints /plan /build /test
        │                  /review /code-simplify /ship /webperf
        ├── agents/        4 subagent: code-reviewer, security-auditor,
        │                  test-engineer, web-performance-auditor
        ├── references/    7 checklist bersama (definition-of-done, testing,
        │                  security, performance, accessibility, observability,
        │                  orchestration-patterns)
        ├── rules/         3 rule per-path (testing, security-sensitive, frontend)
        ├── hooks/         2 hook opsional + dokumentasinya
        └── UPSTREAM.md    versi & commit upstream yang dipakai
```

Yang **milik kit ini** (boleh diedit): `template/CLAUDE.md`,
`template/.claude/rules/`, `template/.gitignore`, `install.ps1`, `scripts/`.
Yang **di-generate dari upstream** (jangan diedit manual, nanti tertimpa saat
update): `template/.claude/skills`, `commands`, `agents`, `references`,
`hooks`, `UPSTREAM.md`.

## Pasang ke repo yang sudah ada

### Cara 1 — copas manual (paling sederhana)

1. Salin **isi** folder `template/` ke root repo tujuan: `CLAUDE.md`, `.claude/`, dan `.gitignore`.
   Jangan salin `README.md`, `CLAUDE.md` root, `install.ps1`, atau `scripts/` dari repo ini.
2. Kalau repo sudah punya `CLAUDE.md`, jangan timpa: gabungkan bagian *How to Work*, *Workflow*, *Definition of Done*, dan *Git* dari template ke file yang ada.
3. Kalau repo sudah punya `.gitignore`, jangan timpa: tambahkan tiga baris ini saja.
   ```
   .claude/settings.local.json
   .claude/sdd-cache/
   .claude/.simplify-ignore-cache/
   ```
4. Isi `CLAUDE.md` (lihat [Mengisi CLAUDE.md](#mengisi-claudemd)), lalu commit `CLAUDE.md` dan `.claude/`.

Di Git Bash / Linux / macOS, langkah 1 untuk repo yang belum punya `CLAUDE.md`:

```bash
cp -r /path/ke/claude-code-starter/template/. /path/ke/repo/
```

### Cara 2 — `install.ps1` (Windows, aman dijalankan berulang)

```powershell
.\install.ps1 -Project C:\path\ke\repo
```

Kalau execution policy memblokir skrip, awali dengan
`powershell -ExecutionPolicy Bypass -File`. Perlakuannya:

| Apa | Perlakuan |
|---|---|
| `.claude/skills`, `commands`, `agents`, `references`, `hooks`, `UPSTREAM.md` | generated; dilewati kalau sudah ada, ditimpa hanya dengan `-Force` |
| `.claude/rules/*.md` | disalin hanya kalau belum ada; **tidak pernah** ditimpa |
| `CLAUDE.md` | disalin hanya kalau belum ada; kalau sudah ada, template disimpan sebagai `CLAUDE.starter.md` |
| `.gitignore` | baris yang belum ada ditambahkan |

### Cara 3 — global di mesin lokal

```powershell
.\install.ps1 -Global
```

Skills, commands, agents, references, dan hooks disalin ke `~/.claude/` dan
berlaku untuk semua project **lokal**; tiap project tinggal diberi `CLAUDE.md`
(dan, kalau mau, `.claude/rules/`). Path `.claude/...` di file yang disalin
ditulis ulang otomatis menjadi `~/.claude/...`; `CLAUDE.md` template sudah
berisi kalimat yang memberi tahu agent soal ini. Cara ini **tidak** berlaku
untuk sesi Claude Code cloud, lihat bagian berikut.

### Cara 4 — plugin resmi (tanpa kit ini)

```
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

Lalu salin hanya `template/CLAUDE.md`. **Jangan** pasang plugin dan kit ini
sekaligus: skill dan command akan dobel (`install.ps1` memberi peringatan).
Plugin tidak dimuat di sesi cloud. Catatan Windows: marketplace meng-clone
lewat SSH; kalau muncul `Permission denied (publickey)`, set sekali:

```bash
git config --global url."https://github.com/".insteadOf git@github.com:
```

## Pakai di Claude Code cloud

Sesi cloud (claude.ai/code) selalu mulai dari clone repo GitHub yang bersih,
jadi yang dibaca hanya yang ada di dalam repo. Dengan Cara 1 atau 2 lalu
commit + push, semuanya jalan:

- `CLAUDE.md`, `.claude/skills`, `commands`, `agents`, `rules`, dan `.claude/settings.json` (hooks + permission) dibaca dari clone, sama seperti lokal.
- Hooks justru lebih gampang di cloud: VM-nya Ubuntu 24.04 dengan `bash` dan `jq` sudah terpasang. Daftarkan di `.claude/settings.json` yang di-commit, bukan `settings.local.json`.

Yang tidak ikut ke cloud: `~/.claude/` lokal (Cara 3), `.claude/settings.local.json`,
dan plugin marketplace (Cara 4). Catatan lain:

- Network default sesi cloud ("Trusted") hanya mengizinkan GitHub, registry paket, dan dokumentasi Anthropic. Skill `source-driven-development` yang mem-fetch dokumentasi framework lain butuh network level Custom atau Full di pengaturan environment.
- Hooks dan permission dari `settings.json` hanya dibaca di sesi satu repo; sesi multi-repo mengabaikannya.
- Kalau custom command seperti `/spec` tidak dikenali di composer web, minta dengan kalimat biasa ("jalankan workflow spec-driven-development untuk fitur X").

Sumber: [cloud environments](https://code.claude.com/docs/en/cloud-environments#what-carries-over-from-your-setup),
[settings di sesi cloud](https://code.claude.com/docs/en/settings#settings-in-cloud-sessions),
[plugin di cloud](https://code.claude.com/docs/en/plugins/install).

## Cara pakai

Semua perintah `/...` diketik di dalam sesi Claude Code yang dibuka di folder
project.

### Siklus fitur baru

| Langkah | Perintah | Hasil |
|---|---|---|
| 1. Tentukan apa yang dibangun | `/spec` | `SPEC.md` (tujuan, perintah, struktur, gaya kode, testing, batasan) |
| 2. Pecah jadi task kecil | `/plan` | `tasks/plan.md`, `tasks/todo.md` dengan acceptance criteria |
| 3. Bangun satu task | `/build` | test gagal → implementasi → test lolos → build → commit |
| 3b. Bangun semua task sekaligus | `/build auto` | satu persetujuan di awal, lalu jalan sendiri; tetap berhenti kalau ada test gagal atau langkah berisiko |
| 4. Review sebelum merge | `/review` | temuan per sumbu (correctness, readability, architecture, security, performance) dengan label Critical / Important / Suggestion |
| 5. Rapikan | `/code-simplify` | kurangi kompleksitas tanpa mengubah perilaku |
| 6. Ship | `/ship` | tiga subagent paralel (reviewer, security, test) → keputusan GO/NO-GO + rencana rollback; tidak melakukan commit |

### Perintah lain

- `/test` — alur TDD; untuk bug memakai pola *Prove-It* (tulis test yang mereproduksi bug dulu).
- `/constraints` — wawancara singkat lalu tulis `CONSTRAINTS.md` (coverage, lint, security, dsb.) dan pasang pengecekannya. Ada sub-perintah `check`, `guard`, `ratchet`.
- `/webperf` — audit Core Web Vitals lewat subagent web-performance-auditor (khusus aplikasi web, satu persona, tanpa fan-out).

### Skill yang aktif otomatis

Tidak semua skill punya slash command. Claude Code memilih skill dari
deskripsinya, jadi cukup bicara biasa:

- "Kenapa test ini gagal?" → `debugging-and-error-recovery`
- "Bikin endpoint POST /orders" → `api-and-interface-design` + `incremental-implementation`
- "Interview aku dulu soal fitur ini" → `interview-me`
- "Cek keamanan handler upload" → `security-and-hardening`
- "Tulis ADR untuk keputusan ini" → `documentation-and-adrs`

Minta subagent langsung juga bisa: "review perubahan ini pakai code-reviewer".
Kalau ingin menyesuaikan sebuah persona, edit `.claude/agents/<nama>.md` di
project dan simpan salinannya: `install.ps1 -Force` setelah update upstream
akan menimpanya. Instruksi khusus project lebih aman ditaruh di `CLAUDE.md`
atau `.claude/rules/`.

### Artefak kerja

`SPEC.md`, `tasks/plan.md`, `tasks/todo.md`, dan `CONSTRAINTS.md` adalah
dokumen hidup selama pekerjaan berjalan. Simpan di git supaya sesi berikutnya
(atau rekan tim) bisa melanjutkan dari file, bukan dari ingatan chat. Kalau
tidak ingin menyimpannya permanen, hapus sebelum merge.

Untuk pekerjaan besar, satu sesi per fase (spec → plan → build → review)
menjaga konteks tetap fokus. Di sesi baru, minta Claude membaca `SPEC.md`,
`tasks/`, dan `git status` sebelum mulai.

### Codebase yang sudah ada (brownfield)

Jangan langsung `/spec` untuk kode lama. Urutan yang aman, mengikuti
[adoption guide](https://github.com/addyosmani/agent-skills/blob/main/docs/adoption-guide.md)
upstream:

1. Isi `CLAUDE.md` dengan konvensi yang benar-benar ada di kode dan "ranjau" yang tidak boleh disentuh.
2. Mulai dari yang tidak mengubah kode: `/review` untuk perubahan masuk, `debugging-and-error-recovery` untuk bug yang memang sedang diperbaiki.
3. Sebelum mengubah area lama, minta *characterization test* dulu (test yang memotret perilaku saat ini).
4. Fitur baru di atas kode lama baru memakai siklus penuh `/spec → /plan → /build → /review`.

## Mengisi CLAUDE.md

`CLAUDE.md` dimuat di setiap sesi, jadi isinya harus pendek dan benar.
Bagian yang wajib diisi:

1. **Tech Stack** — versi framework dan tooling yang benar-benar dipakai.
2. **Commands** — perintah nyata untuk dev, build, test (termasuk test satu file), lint, type check.
3. **Project Structure** — arti tiap folder utama.
4. **Code Conventions** — aturan yang ada di kode, bukan yang ada di wiki.
5. **Boundaries** — Always / Ask first / Never. Sebut "ranjau" yang tidak boleh disentuh.
6. **Patterns** — satu contoh pendek kode yang bagus di project ini. Agent meniru apa yang dilihat.

Bagian *How to Work*, *Workflow*, *Definition of Done*, dan *Git* sudah
terisi dan berlaku umum. Jangan menempel isi SKILL.md ke CLAUDE.md: skill
sudah dimuat sendiri saat relevan, dan duplikasi hanya membuang konteks.

## Rules per-path

`.claude/rules/*.md` hanya dimuat ketika Claude menyentuh file yang cocok
dengan `paths:` di frontmatter-nya, jadi tidak membebani konteks sesi lain.
Yang disertakan:

| File | Aktif untuk | Isi |
|---|---|---|
| `testing.md` | `*.test.*`, `*.spec.*`, `tests/`, `__tests__/` | TDD, Prove-It, uji perilaku bukan implementasi, jangan lemahkan test |
| `security-sensitive.md` | `auth/`, `*auth*` (nama yang mengandung "auth": `oauth.ts`, `useAuth.ts`, tapi juga `author.ts`), `api/`, `middleware/`, `payment*/`, `webhook*/` | validasi di boundary, authz tiap path, jangan log rahasia |
| `frontend.md` | `components/`, `*.tsx`, `*.jsx`, `*.vue`, `*.svelte` | design system, keyboard & a11y, verifikasi di browser |

Sesuaikan glob-nya dengan struktur project, atau hapus yang tidak relevan.
Tambah rule baru dengan format yang sama. Setelah disalin ke project, rules
menjadi milik project: `install.ps1` tidak pernah menimpanya.

## Hooks (opsional)

Dua hook dari upstream disertakan di `.claude/hooks/` beserta dokumentasinya:

- **simplify-ignore** — tandai blok kode `/* simplify-ignore-start */ ... /* simplify-ignore-end */` agar tidak disentuh `/code-simplify`.
- **sdd-cache** — cache hasil `WebFetch` untuk `source-driven-development`, divalidasi ulang ke server (HTTP 304) setiap dipakai.

Keduanya skrip bash. Di cloud semuanya sudah tersedia. Di Windows, Claude Code
menjalankannya lewat Git Bash (sudah berisi `curl`, `perl`, `shasum`); yang
masih harus dipasang hanya `jq` (`winget install jqlang.jq`). Cara
mendaftarkannya ke `.claude/settings.json` ada di `SDD-CACHE.md` dan
`SIMPLIFY-IGNORE.md`. Pada install global (Cara 3), skripnya ada di
`~/.claude/hooks/`; daftarkan di `~/.claude/settings.json` dengan path
`$HOME/.claude/hooks/<skrip>.sh` (dokumentasi yang tersalin sudah disesuaikan).
Tidak diaktifkan secara default.

## Update dari upstream

```powershell
.\scripts\update-from-upstream.ps1
```

Butuh `git` di PATH (atau beri `-Source <path>` ke clone/ZIP agent-skills
yang sudah diunduh). Skrip membangun ulang skills/references/agents/commands/
hooks di folder staging, membuang prefix plugin `agent-skills:` di command,
menyesuaikan path relatif, lalu mengganti folder lama di `template/.claude/`
setelah semuanya sukses dan menulis versi baru ke `UPSTREAM.md`.
`template/CLAUDE.md`, `template/.claude/rules/`, dan file kit lain tidak disentuh.

Setelah update, commit repo ini, lalu di tiap project yang memakainya: commit
dulu, lalu `.\install.ps1 -Project <path> -Force` (atau copas ulang folder
generated secara manual). Hanya folder generated yang ditimpa; `CLAUDE.md`
dan `.claude/rules/` di project tidak disentuh.

## Prinsip yang dipegang kit ini

- **Proses, bukan prosa.** Skill adalah langkah kerja dengan gerbang verifikasi, bukan bacaan.
- **Bukti, bukan asumsi.** Selesai berarti ada output test, hasil build, atau pengecekan runtime.
- **Perubahan kecil.** Target ~100 baris per commit, satu hal per commit, refactor terpisah dari perubahan perilaku.
- **Konteks hemat.** `CLAUDE.md` pendek; skill dan rule dimuat hanya saat relevan.
- **Manusia yang mengorkestrasi.** Subagent tidak memanggil subagent lain; urutan `/spec → /plan → /build` dijalankan oleh kamu.

## Lisensi

Konten di `template/.claude/skills`, `agents`, `commands`, `references`, dan
`hooks` berlisensi MIT, hak cipta Addy Osmani dan kontributor
[agent-skills](https://github.com/addyosmani/agent-skills). File kit lainnya
bebas dipakai dan diubah.
