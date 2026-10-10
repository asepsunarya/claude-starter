# Project: [NAMA PROJECT]

<!--
  Template dari claude-code-starter (berbasis addyosmani/agent-skills).
  Isi bagian dalam [kurung], hapus yang tidak relevan, dan jaga file ini
  tetap pendek (di bawah ~150 baris). Workflow panjang ada di .claude/skills/,
  checklist bersama ada di .claude/references/. Jika file ini dibaca di dalam
  folder kit itu sendiri (bukan project), anggap sebagai template.
-->

Rules file for AI coding agents working in this repository. It is loaded into
every session, so keep it short and current. Long workflows live in
`.claude/skills/`; shared checklists live in `.claude/references/`.
If `.claude/skills/` does not exist in this repository, the kit is installed
at user level: read every `.claude/...` path in this file and in
`.claude/rules/` as `~/.claude/...`.

## Tech Stack

- [Frontend: e.g. Next.js 15, React 19, TypeScript 5, Tailwind CSS 4]
- [Backend: e.g. Node 22, Fastify, PostgreSQL 16, Prisma]
- [Tooling: e.g. pnpm, Vitest, Playwright, ESLint, Prettier]

## Commands

| Task            | Command                                   |
|-----------------|-------------------------------------------|
| Install         | `[pnpm install]`                          |
| Dev server      | `[pnpm dev]`                              |
| Build           | `[pnpm build]`                            |
| Test (all)      | `[pnpm test]`                             |
| Test (one file) | `[pnpm test -- path/to/file.test.ts]`     |
| Lint / format   | `[pnpm lint]` / `[pnpm format]`           |
| Type check      | `[pnpm typecheck]`                        |

Run the relevant checks before claiming a task is done. "Seems right" is not evidence.

## Project Structure

```
src/
  [app/         → routes / pages]
  [components/  → UI components]
  [lib/         → shared utilities, validation, errors]
  [server/      → services, data access]
tests/          → [or colocated: Foo.ts → Foo.test.ts]
docs/           → ADRs (docs/adr/), specs, ideas
tasks/          → tasks/plan.md and tasks/todo.md written by /plan
```

## Code Conventions

- [Named exports; no default exports]
- [Functional components with hooks; no class components]
- [Colocate tests next to source: `Button.tsx` → `Button.test.tsx`]
- [Validate input at the boundary with Zod; throw `AppError`, never raw errors]
- [Reuse helpers in `src/lib/` before writing new ones]
- Code reveals intent through names and structure. No dead code, no debug output, no commented-out blocks.

## Boundaries

**Always**
- Read the file (and its tests) before editing it; copy an existing pattern instead of inventing one.
- Run tests, lint, and type check before committing.
- Keep changes scoped to the task. Touch only what you were asked to touch.

**Ask first**
- Database schema or migration changes
- New dependencies (state the size and the reason)
- Changes to auth, permissions, payments, or anything irreversible
- Deleting code that "seems unused"

**Never**
- Commit secrets or `.env*` files
- Silence failing tests, lower thresholds, or add suppressions to get green
- Force-push to shared branches
- Invent requirements the spec does not cover: stop and ask

## How to Work

These behaviours apply at all times (see the `using-agent-skills` skill):

1. **Surface assumptions** before non-trivial work: list them and ask for correction.
2. **Manage confusion.** When the spec and the code disagree, stop and ask. Do not guess.
3. **Push back** when an approach has a concrete downside; propose an alternative, then accept the decision.
4. **Prefer the boring solution.** If 100 lines would do, do not write 1000.
5. **Scope discipline.** No drive-by refactors; never remove things you do not understand.
6. **Verify, do not assume.** Every task ends with evidence: test output, build result, runtime check.

For multi-step work, emit a short plan first and proceed unless redirected.

## Workflow

Skills in `.claude/skills/` activate automatically from their descriptions.
The slash commands are the entry points:

| Phase       | Command                      | Skill(s) and artifacts                                              |
|-------------|------------------------------|---------------------------------------------------------------------|
| Define      | `/spec`                      | spec-driven-development → `SPEC.md`                                 |
| Quality bar | `/constraints`               | constraint-driven-development → `CONSTRAINTS.md`                    |
| Plan        | `/plan`                      | planning-and-task-breakdown → `tasks/plan.md`, `tasks/todo.md`      |
| Build       | `/build` or `/build auto`    | incremental-implementation + test-driven-development                |
| Verify      | `/test`                      | test-driven-development (Prove-It pattern for bugs)                 |
| Review      | `/review`, `/code-simplify`  | code-review-and-quality, code-simplification                        |
| Ship        | `/ship`                      | shipping-and-launch (fans out to code-reviewer, security-auditor, test-engineer) |
| Perf audit  | `/webperf`                   | web-performance-auditor subagent (web apps only; single persona, no fan-out) |

Typical paths:
- New feature: `/spec` → `/plan` → `/build` (repeat per task) → `/review` → `/ship`
- Bug fix: debugging-and-error-recovery → `/test` (failing test first) → `/review`
- Unclear request: interview-me or idea-refine before `/spec`

Specialist subagents live in `.claude/agents/`. They never call each other;
the user or a slash command does the orchestration.

If `CONSTRAINTS.md` exists, read it before writing code and never weaken it to make a change pass.

## Definition of Done

A task is done only when its acceptance criteria are met **and** the standing
bar in `.claude/references/definition-of-done.md` holds: verified at runtime,
covered by a test that fails without the change and passes with it, no
regressions, lint and types clean, scoped to the task, and documented where
public behaviour changes.

## Git

- Conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`. The body explains *why*.
- One logical change per commit, ~100 lines target; split anything over ~1000.
- Keep refactors separate from behaviour changes.
- Commit only when the user asks, or when a command defines the commit step (`/build` commits once per task; `/ship` never commits).
- Branch names: `feature/<desc>`, `fix/<desc>`, `chore/<desc>`.

## Patterns

[Paste one short example of a well-written module in this project's style:
a component, a service, or a test. Agents copy what they see.]
