---
description: UI code follows the frontend-ui-engineering skill and accessibility checklist
paths:
  - "**/components/**"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
---

# UI code

- Follow the `frontend-ui-engineering` skill: component boundaries, state placement, responsive layout, WCAG 2.1 AA.
- Reuse the project's design-system primitives before adding new styles or components.
- Every interactive element is keyboard reachable, has an accessible name, and visible focus.
- Verify in a real browser when behaviour depends on runtime (use `browser-testing-with-devtools` if available).
- Checklist: `.claude/references/accessibility-checklist.md`. Performance baseline: `.claude/references/performance-checklist.md`.
