# CI/CD — GitLab CI (design)

> Alternative to Actions. Keep the same logical jobs; use environments and protected runners.

- `stages`: validate → plan → apply/sync → post
- `only/except` rules on paths (`terraform/**`, `docs/**` etc.)
- `artifacts` for `plan` output
- `environments`: `prod-pz`, `prod-bz`
- `manual` jobs for `apply`, `dr-flip`
