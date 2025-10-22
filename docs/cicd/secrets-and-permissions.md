# CI/CD — Secrets & Permissions

- CI secrets live in the platform's secret store, scoped to the repo and to **protected branches** only.
- Rotate quarterly and on personnel change.
- Token scopes:
  - DigitalOcean: create/update DOKS, LBs, VPC.
  - Cloudflare: Zone:DNS:Edit for `guajiro.xyz`.
  - Kube access: per-zone ServiceAccount token with minimal RBAC.
