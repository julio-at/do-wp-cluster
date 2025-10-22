# Documentation Index — do-wp-cluster

**Purpose:** Master guide to design, operations, and runbooks for WordPress on DigitalOcean Kubernetes (DOKS) with multi‑zone DR (PZ nyc3 / BZ sfo3).  
**Workflow:** documentation → implementation → tests.

---

## Conventions
- **Zones:** **PZ** = Primary Zone (nyc3), **BZ** = Backup Zone (sfo3).
- **Domains:** `wp-active.guajiro.xyz` (logical CNAME) → `wp-pz.guajiro.xyz` or `wp-bz.guajiro.xyz`.
- **Principles:** minimal steady cost, explicit flips, managed DB, object storage for media.

---

## Start Here (Stages)
1. Stage 01 — Preparation → `docs/stages/01-preparation.md`
2. Stage 02 — Minimal Infrastructure → `docs/stages/02-minimal-infrastructure.md`
3. Stage 03 — Ingress & Certs (docs-first) → `docs/stages/03-ingress-and-certs.md`
4. Stage 04 — DNS CNAME & Exposure → `docs/stages/04-dns-cname-and-exposure.md`
5. Stage 05 — WordPress Minimal → `docs/stages/05-wordpress-minimal.md`
6. Stage 06 — Backup Zone On-Demand → `docs/stages/06-backup-zone-on-demand.md`
7. Stage 07 — DR Game Day → `docs/stages/07-disaster-recovery-game-day.md`

> Stages are designed to be executed in order; each stage has acceptance criteria and links to supporting docs.

---

## Operations Runbooks
- **DNS flip (CNAME)** — `docs/runbooks/dns/flip-active-cname.md`
- **Promote replica to writer (BZ)** — `docs/runbooks/db/promote-replica-to-writer.md`
- **Restore writer in BZ** — `docs/runbooks/db/restore-writer-in-bz.md`
- **Platform bring‑up (zone)** — `docs/runbooks/platform/platform-bringup-zone.md`
- **Platform teardown (zone)** — `docs/runbooks/platform/platform-teardown-zone.md`
- **Failback to PZ** — `docs/runbooks/platform/failback-to-primary-zone.md`
- **WP minimal deploy** — `docs/runbooks/app/wp-minimal-deploy.md`
- **DR Game‑Day playbook** — `docs/runbooks/dr-game-day-playbook.md`

---

## Infra
- Overview — `docs/infra/00-overview.md`
- Layout — `docs/infra/terraform-layout.md`
- Environments & Workspaces — `docs/infra/environments-and-workspaces.md`
- Variables & tfvars — `docs/infra/variables-and-tfvars.md`
- DOKS module — `docs/infra/doks-module.md`
- Networking & VPC — `docs/infra/networking-vpc.md`
- Tagging & Naming — `docs/infra/tagging-and-naming.md`
- Cost controls — `docs/infra/cost-controls.md`
- Cost & Hygiene (extended) — `docs/infra/cost-playbook.md`

---

## DNS
- CNAME Strategy — `docs/dns/cname-strategy.md`
- TTL Policy — `docs/dns/ttl-policy.md`

---

## App (WordPress)
- Overview — `docs/app/00-overview.md`
- Configuration — `docs/app/wordpress-configuration.md`
- Values Blueprint — `docs/app/values-blueprint.md`
- Content & Media Strategy — `docs/app/content-media-strategy.md`
- Blue/Green release plan — `docs/app/bluegreen-release-plan.md`
- Operational checklists — `docs/app/operational-checklists.md`

---

## Observability
- Overview — `docs/observability/00-overview.md`
- Metrics stack — `docs/observability/01-metrics-stack.md`
- Alerts & SLOs — `docs/observability/02-alerts-and-slos.md`
- Grafana dashboards — `docs/observability/03-grafana-dashboards.md`
- Synthetic probes — `docs/observability/04-synthetic-probes.md`
- Logging & tracing — `docs/observability/05-logging-and-tracing.md`
- Multi‑zone & DR observability — `docs/observability/06-multi-zone-dr-observability.md`
- Observability runbooks — `docs/observability/07-runbooks-observability.md`

---

## Security
- Secrets policy — `docs/security/secrets-policy.md`
- Backup policy — `docs/security/backup-policy.md`
- State backend — `docs/security/state-backend.md`
- Trusted sources — `docs/security/trusted-sources.md`

---

## CI/CD
- Overview — `docs/cicd/00-overview.md`
- GitHub Actions (design) — `docs/cicd/github-actions.md`
- GitLab CI (design) — `docs/cicd/gitlab-ci.md`
- Pipelines & gates — `docs/cicd/pipelines-and-gates.md`
- Secrets & permissions — `docs/cicd/secrets-and-permissions.md`
- GitOps vs Actions — `docs/cicd/gitops-vs-actions.md`
- Promotion strategy — `docs/cicd/promotion-strategy.md`

---

## Platform (Ingress)
- Ingress operations (ES) — `docs/platform/ingress-operations.md`
- Ingress operations (EN) — `docs/platform/ingress-operations-en.md`
- LB IP rotation (ES) — `docs/platform/lb-ip-rotation.md`
- LB IP rotation (EN) — `docs/platform/lb-ip-rotation-en.md`
- Exposure policy (ES) — `docs/platform/exposure-policy.md`
- Exposure policy (EN) — `docs/platform/exposure-policy-en.md`

---

## Database
- Overview — `docs/db/00-overview.md`
- Operations — `docs/db/operations.md`
- Connectivity & TLS tests — `docs/db/connectivity-tests.md`
- Password rotation — `docs/db/password-rotation.md`
- Sizing & maintenance — `docs/db/sizing-and-maintenance.md`

---

## Testing
- Overview — `docs/testing/00-overview.md`
- Stage 05 — smoke/functional — `docs/testing/stage05-smoke-tests.md`
- Stage 06 — BZ readiness — `docs/testing/stage06-bz-readiness.md`
- Stage 07 — DR rehearsal — `docs/testing/stage07-dr-rehearsal.md`
- Evidence checklist — `docs/testing/evidence-checklist.md`
- RTO/RPO measurement — `docs/testing/rto-rpo-method.md`

---

## Snippets (reference)
- ClusterIssuers (Cloudflare) — `docs/snippets/clusterissuers-cloudflare.md`
- Ingress-NGINX values — `docs/snippets/ingress-nginx-values.md`
- kube-prometheus-stack values — `docs/snippets/kps-values.md`
- ExternalDNS annotations — `docs/snippets/externaldns-annotations.md`

---

## Decisions & FAQ
- ADRs — `docs/decisions/adr-01-cname-active-record.md`, `adr-02-dr-strategy-replica-vs-restore.md`, `adr-03-managed-mysql-vs-selfhosted.md`, `adr-04-externaldns-scope.md`, `adr-05-gitops-vs-actions.md`
- FAQ — `docs/faq.md`

---

## Next Steps
- Lock docs → implement Stages 01–04 in PZ → Stage 05 (WP minimal) → Stage 06 (BZ on‑demand) → Stage 07 (DR Game‑Day).
- After first pass: consider Argo CD, ExternalDNS, and exposing monitoring behind auth.
