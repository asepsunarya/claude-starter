---
description: Auth, API, and payment code follows the security-and-hardening skill
paths:
  - "**/auth/**"
  - "**/*auth*"
  - "**/api/**"
  - "**/middleware/**"
  - "**/payment*/**"
  - "**/webhook*/**"
---

# Security-sensitive code

- Follow the `security-and-hardening` skill before changing anything here.
- Validate and sanitize every input at the boundary; parameterize queries; encode output.
- Check authorization on every protected path, including object-level access (IDOR).
- Never log or return secrets, tokens, password hashes, or full PII.
- Verify webhook signatures; allowlist redirect targets and server-side fetch URLs.
- Treat any change here as "ask first" (see Boundaries in `CLAUDE.md`) and as a `/ship` fan-out candidate.
- Pre-commit checklist: `.claude/references/security-checklist.md`.
