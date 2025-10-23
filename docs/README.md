# do-wp-cluster — Docs Index

This repo orchestrates a dual-zone WordPress deployment on DigitalOcean:

- **Primary Zone (PZ)**: `nyc3`
- **Backup Zone (BZ)**: `sfo3` (on-demand / cold)
- **Kubernetes (DOKS)** per zone
- **Managed MySQL (DigitalOcean)** per zone (PZ active, BZ optional/cold)
- **Ingress/TLS** via NGINX Ingress + cert-manager (DNS-01 / Cloudflare)
- **Observability** via kube-prometheus-stack (SLOs, synthetics)

> We use **default regional VPCs** (`default-<region>`) for both clusters and DBs.  
> During **Stage-02** there is **no DB firewall** (by design). TLS + credentials only.  
> Hardening (DB firewall / WAF) happens after functionality is proven.

---

## Repo Map (docs/)

- `docs/README.md` ← this file (high-level map & stage guide)
- `docs/infra/` — infra notes (workspaces, regions, VPC, autoscaling)
- `docs/dns/` — DNS strategy (CNAME active/pz/bz), TTL policy
- `docs/app/` — WordPress app notes (external DB, media offload, caching)
  - `docs/app/wp-perf-roadmap.md` — Hybrid approach: RWX `wp-content/` + immutable core
- `docs/security/` — secrets, state backend, trusted sources, backup policy
- `docs/observability/` — SLOs, metrics, logs, synthetics
- `docs/runbooks/` — operational procedures (flip CNAME, promote/restore, failback, deploy)
  - `docs/runbooks/stage-02-db.md` — **Stage-02 DB runbook (create/apply/validate/destroy)** ✅
- `docs/testing/` — test plans & evidence
  - `docs/testing/db-smoke-test.md` — **Stage-02 DB connectivity test (PZ/BZ)** ✅

---

## Stages (high-level)

1. **Stage-01** — Bootstrap repo, providers, versions, workspaces.
2. **Stage-02** — **Infra apply (K8s) + Managed MySQL (DO)**
   - DBs attach automatically to the **default regional VPC** (`default-nyc3`, `default-sfo3`).
   - **No DB firewall** in this stage to keep bring-up zero-touch.
   - Terraform outputs include: `private_host`, `host`, `port`, `database`, `username`, `password`, `ca_cert`.
   - Validate with **`docs/testing/db-smoke-test.md`** and operate with **`docs/runbooks/stage-02-db.md`**.
3. **Stage-03** — Ingress + cert-manager (DNS-01 via Cloudflare), minimal exposure.
4. **Stage-04** — DNS CNAME wiring (manual), active/pz/bz endpoints.
5. **Stage-05** — WordPress minimal (external DB, media offload).
6. **Stage-06/07** — BZ on-demand + DR Game-Day; add DB firewall, WAF/IP ACLs.

---

## Stage-02 — How DBs are provisioned (summary)

- Module path: `terraform/doks/modules/db/`
- Root wiring: `terraform/doks/db-variables.tf`, `terraform/doks/db-main.tf`, `terraform/doks/db-outputs.tf`
- **VPC**: we **do not create** VPCs. We **lookup** `default-<region>` and pass its UUID to the DB module.
- **Firewall**: none during Stage-02 (TLS + creds only).
- **Workspaces**: `prod-pz`, `prod-bz`
- **tfvars**: `terraform/env/prod/pz.tfvars`, `terraform/env/prod/bz.tfvars`
  - Each file contains **both** K8s and DB blocks; **BZ DB** usually **disabled** by default.

### Minimal commands

```bash
cd terraform/doks
terraform init -upgrade

# PZ
terraform workspace select prod-pz || terraform workspace new prod-pz
terraform plan  -var-file=../env/prod/pz.tfvars  -out=tfplan-pz
terraform apply tfplan-pz

# (Optional) BZ for test
terraform workspace select prod-bz || terraform workspace new prod-bz
terraform plan  -var-file=../env/prod/bz.tfvars  -out=tfplan-bz
terraform apply tfplan-bz
```

### Outputs

```bash
terraform output -json | jq 'keys'
terraform output -json db_pz | jq 'keys'   # host, private_host, port, database, username, password, ca_cert
```

> **Store secrets safely** (vault/secret manager). Avoid printing raw values in CI logs.

---

## Stage-02 — Connectivity smoke test

Follow **`docs/testing/db-smoke-test.md`**.  
It runs a **Kubernetes Job** in each cluster that:
- waits for DNS and TCP,
- `mysqladmin` ping with `VERIFY_CA`,
- `SELECT 1` using the private endpoint and the CA from Terraform outputs.

**Success:** Job `Complete`, logs show `mysqld is alive`, `SELECT 1` returns `1`, then `OK`.

---

## Branching & Safety

- Use feature branches for risky changes (e.g., `dodb` for DB work).
- Each **workspace** has its **own state**; `terraform destroy` affects **only** the active workspace.
- Keep BZ **cold** (`enable_db_bz = false`) unless testing DR.

---

## Next

- Proceed to **Stage-03** (cert-manager + ingress).  
- Prepare a **Cloudflare API token** with DNS-edit for the domain (for DNS-01).  
- After functionality is validated, add **DB firewall** (VPC CIDR or k8s UUID) and WAF/IP ACLs.
