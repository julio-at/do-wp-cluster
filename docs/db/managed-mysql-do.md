# DigitalOcean Managed MySQL — Approach & Operations

## Goal
Deploy DigitalOcean Managed MySQL for the Primary Zone (PZ, `nyc3`) while keeping the Backup Zone (BZ, `sfo3`) **cold**. The rollout can be done in **one apply** or in **two steps**, depending on where your Kubernetes cluster is defined.

---

## Key Decisions
- **Firewall (Trusted Sources):** May start **OFF** (no rules), relying on **TLS + strong credentials**. Harden later with:
  1) **VPC CIDR** (fast close, use `private_uri`), or
  2) **`k8s` rule** with the **UUID** of the DOKS cluster (stricter).
- **BZ:** “Cold” for cost control; activate on‑demand (restore‑on‑activation).
- **Sensitive outputs:** host/private_host, port, database, username, password, uri/private_uri, CA.

---

## Deployment Approaches

### A) One Apply (recommended if the PZ cluster is in the same stack)
Create the DOKS cluster and **pass its `id` directly** into the DB module’s `trusted_sources.cluster_ids`. Terraform determines the correct order via **implicit dependency** (no `depends_on` needed). If the DO API exhibits eventual consistency around the DB firewall, add a small **`time_sleep`** (20–60s) before the firewall step.

**Pros:** idempotent, simple, no manual data.  
**Cons:** the cluster must live in this same Terraform root.

### B) Separate Stacks (robust at scale)
Read the `cluster_id` from **remote state** via `data.terraform_remote_state`, and pass it to the DB module.

**Pros:** clean separation of concerns, fits larger orgs and CI/CD.  
**Cons:** requires a shared state backend and discipline.

### C) Pre‑existing Cluster (outside Terraform)
Resolve the `cluster_id` by **name** using the `digitalocean_kubernetes_cluster` **data source**. If DO needs a moment before the cluster is discoverable by name, introduce a brief **delay** prior to the data source. As a fallback, you can initially deploy the DB **without firewall** and harden later.

**Pros:** integrates with clusters not managed by TF.  
**Cons:** depends on exact name and active Team/Context.

---

## Security Notes (when firewall is OFF)
- Always connect with **TLS** and **validate the CA** (`VERIFY_CA` or `VERIFY_FULL`).
- Use **long, random** credentials (≥ 32 chars) and **rotate** periodically.
- Application DB user with **least privilege** (not admin).
- **Monitor** connection attempts/errors; alert on spikes and brute‑force patterns.

**Fast hardening later (no UUID required):** add a **single VPC CIDR** rule and switch clients to `private_uri`.  
**Final hardening:** add a **`k8s` rule** with the **cluster UUID**.

---

## Recommended Flow (PZ first, BZ cold)

1. **Prereqs**
   - Valid DO token for Terraform and doctl.
   - Workspaces: `prod-pz`, `prod-bz`.
   - “Frozen” per‑zone variables.

2. **PZ Apply**
   - Create PZ DB with minimal tier (**firewall OFF** initially).
   - Store sensitive outputs in a vault (never in logs).
   - (Optional) Smoke test from a pod using `mysqladmin ping` with `--ssl-mode=VERIFY_CA`.

3. **Harden when ready**
   - Add **VPC CIDR** or **k8s UUID** rule and `apply`.
   - If using private networking, migrate clients from `host` to `private_host`/`private_uri`.

4. **BZ (cold)**
   - Keep defined but `enable = false`.
   - Activate on‑demand with restore; add VPC/UUID rule if needed.

---

## WordPress Updates without PV/PVC
- Treat plugins/themes as **immutable dependencies** via **Composer** (WPackagist/Bedrock).  
- Set `DISALLOW_FILE_MODS=true` to avoid UI‑driven installs/updates.  
- Use **read‑only root filesystem**; offload uploads to S3/R2 (or a small PVC only if truly required).  
- **Update = image rebuild** via CI/CD, not clicks in production.

---

## Rollback
- To remove **only the DB** in PZ: toggle OFF and `apply` in `prod-pz`.  
- Do not destroy BZ; keep it cold and available for DR.
