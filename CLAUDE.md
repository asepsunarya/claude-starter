# claude-code-starter

This repository is a starter kit for Claude Code, not an application. Everything
under `template/` is what gets copied into other repositories; this file only
governs work on the kit itself and must not be copied anywhere.

## Layout

- `template/CLAUDE.md`, `template/.gitignore`, `template/.claude/rules/` — authored. Edit freely; keep `template/CLAUDE.md` under ~150 lines.
- `template/.claude/{skills,commands,agents,references,hooks,UPSTREAM.md}` — generated from addyosmani/agent-skills by `scripts/update-from-upstream.ps1`. Never hand-edit; change the rewrite rules in the script and regenerate.
- `install.ps1`, `scripts/update-from-upstream.ps1` — Windows PowerShell 5.1 tooling. No `&&`, `||`, `??`, ternaries; use `-LiteralPath` for every user-derived path.
- `README.md` is written in Indonesian for the kit's user; template files and skills are in English.

## Commands

- Regenerate generated folders: `.\scripts\update-from-upstream.ps1` (or `-Source <local clone>`)
- Install into a project: `.\install.ps1 -Project <path>` (`-Force` overwrites generated files only)
- Smoke test after changes: run `install.ps1` against a scratch folder twice (second run must copy 0 files), and once with `-Global -UserDir <scratch>`; confirm no `~/~` double prefixes and no leftover `.claude.new-*` staging folders.

## Boundaries

- Always: keep `README.md` counts (25 skills, 9 commands, 4 agents, 7 references, 3 rules) in sync with `template/.claude/`.
- Always: preserve UTF-8 without BOM and LF line endings in `*.sh` files.
- Ask first: adding new files to `template/` that could collide with files in a target repository (for example `settings.json`, `README.md`).
- Never: paste full SKILL.md content into `template/CLAUDE.md` or rules; reference the skill by name instead.
- Never: commit `.claude/settings.local.json` or hook caches.
