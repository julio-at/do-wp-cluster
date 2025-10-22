# CI/CD — Overview

**Goal:** Pipeline(s) that can provision infra (Terraform), sync platform/app (Helm/manifests), and execute DR flips in a **controlled, audited** way. Docs-first; no pipelines are created here.

---

## Principles
- **Everything by PR** to protected branches.
- **Separation**: Infra (Terraform) vs. App/Platform (GitOps or direct Helm).
- **Idempotent** jobs, safe re-runs.
- **Secrets** only from CI vault; masked; least-privilege.
- **Manual approvals** for destructive or DR actions.

---

## Environments
- `prod-pz` and `prod-bz` (match Terraform workspaces).
- Optional preview envs for feature tests (future).

---

## High-level Stages
1) **Validate** (fmt, lint, kubeval, helm template)
2) **Plan** (Terraform plan / Helm diff)
3) **Apply/Sync** (with approvals)
4) **Post-Checks** (smoke tests, synthetics, annotate dashboards)
5) **Rollback** (documented procedures; manual gates)
