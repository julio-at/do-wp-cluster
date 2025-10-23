# do-wp-cluster — Documentation Index

> Project: **do-wp-cluster** • Domain: **guajiro.xyz** • Zones: **PZ (nyc3)** / **BZ (sfo3)**

This index keeps pointers to the working docs, runbooks, and snippets we use across stages. It matches the current repository structure (branch `dodb`).

---

## Quick Links

- **Stages**
  - Stage 01: Preparation — `docs/stages/01-preparation.md`
  - Stage 02: Infra (DOKS + DO Managed MySQL) — `docs/stages/02-infra.md` and `docs/stages/02-minimal-infrastructure.md`
  - Stage 03: Platform Baseline (cert-manager + Ingress) — `docs/stages/03-platform-baseline.md`
  - Stage 04: DNS & Exposure — `docs/stages/04-dns-and-exposure.md` / `docs/stages/05-dns-and-exposure.md`
  - Stage 06: Backup Zone (On-demand) — `docs/stages/06-backup-zone-on-demand.md`
  - Stage 07: DR Game Day — `docs/stages/07-disaster-recovery-game-day.md`

- **Runbooks**
  - Stage-02 DB (Primary/Backup) — `docs/runbooks/stage-02-db.md`
  - DB: Promote Replica → Writer (BZ) — `docs/runbooks/db/promote-replica-to-writer.md`
  - DB: Restore Writer in BZ — `docs/runbooks/db/restore-writer-in-bz.md`
  - DNS: Flip Active CNAME — `docs/runbooks/dns/flip-active-cname.md`
  - Platform: Bring-up per Zone (Stage 03) — `docs/runbooks/platform/platform-bringup-zone.md`
  - Platform: Teardown / Failback — `docs/runbooks/platform/platform-teardown-zone.md`, `docs/runbooks/platform/failback-to-primary-zone.md`

- **Snippets**
  - cert-manager ClusterIssuers (Cloudflare DNS-01) — `docs/snippets/clusterissuers-cloudflare.md`
  - cert-manager Certificates (staging → prod) — `docs/snippets/certificates-usage.md`
  - Ingress NGINX values — `docs/snippets/ingress-nginx-values.md`
  - kube-prometheus-stack values — `docs/snippets/kps-values.md`
  - ExternalDNS annotations — `docs/snippets/externaldns-annotations.md`

- **Testing**
  - DB smoke (K8s → DO Managed MySQL, TLS) — `docs/testing/db-smoke-test.md`
  - Evidence checklist — `docs/testing/evidence-checklist.md`
  - Stage 05 smoke — `docs/testing/stage05-smoke-tests.md`
  - Stage 06 BZ readiness — `docs/testing/stage06-bz-readiness.md`
  - Stage 07 DR rehearsal — `docs/testing/stage07-dr-rehearsal.md`

---

## Stage 02 — What to Expect

- Terraform (per workspace) provisions:
  - DOKS cluster per region (PZ: nyc3, BZ: sfo3)
  - DO Managed MySQL per region (tier mínimo), user `wp_app`, DB `wp_prod`
  - VPC: default per region (no DB firewall for now)
- **Outputs**: host/private_host, port, database, username, password, ca_cert, cluster_name.
- **Connectivity test script**: `terraform/scripts/db-smoke.sh` (no env vars required).
  ```bash
  cd terraform/doks
  bash ../scripts/db-smoke.sh --zone pz    # or --zone bz | --zone both
  ```

If `apply` fails with “name already exists”, import existing resources to the workspace before re-applying.

---

## Stage 03 — What to Expect

- Install **cert-manager** with CRDs in each zone; store **Cloudflare API token** as Secret:
  - Secret: `cert-manager/cloudflare-api-token` (key: `api-token`)
- Apply **ClusterIssuers** (staging + prod) per zone:
  - PZ: `k8s/platform/pz/cert-manager/clusterissuers.yaml`
  - BZ: `k8s/platform/bz/cert-manager/clusterissuers.yaml`
- (Optional) Pre-provision **Certificates** (staging) per zone:
  - PZ: `k8s/platform/pz/tls/wp-cert.yaml`
  - BZ: `k8s/platform/bz/tls/wp-cert.yaml`
- Deploy **NGINX Ingress** in **PZ** (`LoadBalancer`, `replicaCount: 2`):
  - `k8s/platform/pz/ingress-nginx/values.yaml`
  - Optional HTTP smoke: `k8s/platform/pz/ingress-nginx/echo.yaml`
- Keep **BZ** ingress **cold** (e.g., `replicaCount: 0`).

Full step-by-step: `docs/runbooks/platform/platform-bringup-zone.md`

---

## ADRs / Decisions

- CNAME active record is **manual** (no ExternalDNS) — `docs/decisions/adr-01-cname-active-record.md`
- DR strategy: **restore-on-activation** (no continuous replica) — `docs/decisions/adr-02-dr-strategy-replica-vs-restore.md`
- Managed MySQL (DO) vs self-hosted — `docs/decisions/adr-03-managed-mysql-vs-selfhosted.md`
- ExternalDNS scope (when/if enabled) — `docs/decisions/adr-04-externaldns-scope.md`
- GitOps vs Actions — `docs/decisions/adr-05-gitops-vs-actions.md`

---

## Repo Structure (short)

See the repo for full tree; key areas:
- `terraform/doks`: IaC for clusters + managed DBs (per workspace).
- `k8s/platform`: platform manifests by zone (cert-manager, ingress, tls).
- `docs/`: stages, runbooks, snippets, testing, decisions.
- `docs/app`, `docs/db`, `docs/observability`: app/database/obs specifics.

---

## Notes

- Keep `BZ` “cold” to control costs; activate on demand (Stage 06).
- `wp-active.guajiro.xyz` remains **manual CNAME** flip.
- No DB firewall for now; TLS + credentials only (per Stage-02 scope).
