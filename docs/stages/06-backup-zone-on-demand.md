# Stage 06 — Backup Zone On-Demand (BZ)

> **Goal:** Be able to **create BZ from scratch on demand**, mirror the platform/app baseline from PZ with minimum cost, and leave it ready for a DR promotion (but **not exposed publicly** yet). We keep the DNS strategy from Stage 04 (flip only `wp-active.guajiro.xyz`).

- BZ region: **sfo3**
- PZ remains the live zone (nyc3). BZ is cold/warm depending on your DB choice below.

---

## Strategy Options for Database (choose one)

### Option A — **Read-Replica in BZ** (lower RPO, some steady cost)
- Create a **managed MySQL read-replica** in BZ fed from the PZ writer.
- Pros: lower RPO (replication lag), faster promotion at DR time.
- Cons: cost for the replica, cross-region data transfer.

### Option B — **Backup/Restore on Activation** (lowest cost, higher RTO/RPO)
- Keep **no database** in BZ until DR. On activation, **restore** from recent backup or PITR into BZ region.
- Pros: minimal standing cost.
- Cons: higher RPO (since last backup) and RTO (restore time + app wiring).

> Decide here. The rest of the stage is the same for platform/app; only DB differs and impacts the DR runbook.

---

## Scope of this Stage
- **Create BZ infra** (if not already): VPC + DOKS cluster (Stage 02 outputs reused).
- **Install platform baseline** (Stage 03) in BZ: namespaces, cert-manager (DNS-01 CF), kube-prometheus-stack.
- **Prepare WordPress** with `replicas=0` or `1` (your choice). No public exposure yet.
- **Database** per chosen option (replica **or** restore plan doc).
- **DNS**: keep `wp-bz.guajiro.xyz` reserved; do **not** route traffic.

---

## Prerequisites
- Kubeconfig for BZ: `artifacts/kubeconfig-bz` (from Stage 02).
- Cloudflare token (same as PZ) scoped to `guajiro.xyz`.
- Decisions captured in docs: **Option A vs B** for DB.

Set context:
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-bz
kubectl get nodes
```

---

## Steps (high level)

### 1) Ensure BZ infra exists (or create)
- Terraform workspace: `prod-bz`
- Apply using `terraform/env/prod/bz.tfvars` (already defined in Stage 02).  
- Verify: `kubectl get nodes`, VPC CIDR unique.

### 2) Install **platform baseline** (Stage 03) on BZ
- Namespaces `platform`, `app`
- Install **cert-manager** with CRDs and the **Cloudflare token** secret in `platform`
- Apply **ClusterIssuers** (`le-staging-cloudflare`, `le-prod-cloudflare`)
- Install **kube-prometheus-stack** (ClusterIP services only)

**Validation:** all pods healthy; Prometheus targets UP; no LoadBalancers created.

### 3) Database in BZ
- **Option A (Replica):**
  - Create DO Managed MySQL **read-replica** in **sfo3** from the PZ writer.
  - Monitor **replication lag** (expose metric to Prometheus if possible).
  - Store connection details and **CA** as secrets in `app` (similar to PZ).
- **Option B (Restore on activation):**
  - Document **backup source** (PITR window, object storage location).
  - Prepare automation/scripting for **restore into BZ** with parameters templated.
  - Keep a **checklist** of indexes/migrations that must run post-restore.

### 4) WordPress in BZ (cold/warm)
- Deploy the same chart/manifests as PZ but with:
  - `replicaCount: 0` (cold) **or** `1` (warm)
  - External DB env pointing to **replica** (read-only) *or* left **unconfigured** until DR (restore path)
  - S3/Spaces secrets replicated (pointing to the same bucket **or** to a replicated bucket, per your policy)
- Do **not** create a public Ingress yet.
- Optionally create an internal-only Ingress/Service for smoke tests via `port-forward`.

### 5) DNS reservations
- Reserve `wp-bz.guajiro.xyz` (record can be created but **not** used by `wp-active` yet).
- Keep `wp-active.guajiro.xyz` pointing to **PZ** until DR.

---

## Validation Checklist (BZ)
- `platform` and `app` namespaces present.
- cert-manager + ClusterIssuers healthy in BZ.
- kube-prometheus-stack healthy; targets UP.
- WordPress resources present with `replicas=0/1` as decided.
- **DB (only if Option A):** replica accepting connections; observe **replication lag** metric and set an alert.
- **No public exposure** in BZ (no LoadBalancer, no public Ingress).

---

## Observability Additions (useful for DR)
- Dashboard tile for **replication lag** (Option A).
- Synthetic probes for:
  - `wp-active.guajiro.xyz` (live path)  
  - `wp-pz.guajiro.xyz` and `wp-bz.guajiro.xyz` (per-zone reachability) — can be DNS-only until exposed.
- Alert rules:
  - **DB replication lag** over threshold (A)
  - **Backup freshness** / restore verification staleness (B)

---

## Costs & Hygiene
- **Keep BZ small**: minimal node count, `replicas=0` for app if you want “cold” BZ.
- Turn BZ **off** (destroy workspace) when not actively testing to save costs.
- Ensure **CIDRs don’t overlap** across zones.

---

## Runbook Hooks for Stage 07 (DR Game-Day)

### If Option A (Replica):
1. Validate incident → decide DR.
2. **Promote** BZ replica to **writer**.
3. Scale WP up in BZ; reconfigure DB endpoint if needed.
4. Create/enable public Ingress in BZ; obtain TLS via `le-prod-cloudflare`.
5. **Flip** `wp-active.guajiro.xyz` → `wp-bz.guajiro.xyz`.
6. Post-checks: login, post creation, media writes.

### If Option B (Restore):
1. Validate incident → decide DR.
2. **Restore** latest backup / PITR to BZ; run migrations.
3. Wire WP to the new writer; scale up.
4. Expose BZ and obtain TLS.
5. **Flip** `wp-active.guajiro.xyz` → `wp-bz.guajiro.xyz`.
6. Post-checks as above.

**Failback** (both options): re-seed PZ (replica/restore), reverse flip, and validate.

---

## Exit Criteria
- BZ can be created **from scratch** and brought to a **ready-but-not-exposed** posture within your RTO budget (excluding promotion/restore).
- All secrets/configs mirror PZ with environment-appropriate values.
- Clear runbook steps exist for **promotion** (A) or **restore** (B).

---

## Next Stage (07 — DR Game-Day)
- Execute a **full rehearsal**: promote/restore, expose BZ, flip DNS, validate, and fail back to PZ.
- Capture RTO/RPO, issues found, and improvements for automation.
