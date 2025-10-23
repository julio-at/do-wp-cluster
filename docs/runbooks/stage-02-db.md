# Runbook — Stage 02: Managed MySQL (DigitalOcean) + Validation

**Scope:** Provision Managed MySQL in **PZ (nyc3)** and optionally **BZ (sfo3)** using Terraform modules, attach to the **default regional VPC** (`default-<region>`), **no firewall** (TLS+credentials only), and validate connectivity from each cluster.

**File location:** `docs/runbooks/stage-02-db.md`

---

## 0) Prereqs

- `DIGITALOCEAN_TOKEN` exported for Terraform.
- `doctl` authenticated: `doctl auth init --access-token 'dop_v1_xxx'`
- Workspaces created or to be created on the fly: `prod-pz`, `prod-bz`.
- tfvars present:
  - `terraform/env/prod/pz.tfvars` (K8s + DB PZ enabled)
  - `terraform/env/prod/bz.tfvars` (K8s + DB BZ usually disabled; enable only for tests)

---

## 1) Init providers (root: terraform/doks)

```bash
cd terraform/doks
terraform init -upgrade
```

---

## 2) Primary Zone (PZ) — Create

```bash
terraform workspace select prod-pz || terraform workspace new prod-pz

terraform plan   -var-file=../env/prod/pz.tfvars   -out=tfplan-pz

terraform apply tfplan-pz
```

**Expected:** DO DB cluster created in `nyc3`, attached to `default-nyc3`.  
Outputs available: `db_pz` → `host`, `private_host`, `port`, `database`, `username`, `password`, `ca_cert`.

```bash
terraform output -json | jq 'keys'
terraform output -json db_pz | jq 'keys'
```

---

## 3) (Optional) Backup Zone (BZ) — Create for Test

> Only if you enable `enable_db_bz = true` in `bz.tfvars`.

```bash
terraform workspace select prod-bz || terraform workspace new prod-bz

terraform plan   -var-file=../env/prod/bz.tfvars   -out=tfplan-bz

terraform apply tfplan-bz
```

**Expected:** DO DB cluster created in `sfo3`, attached to `default-sfo3`.  
Outputs available: `db_bz` keys similar to PZ.

---

## 4) Connectivity Validation (Smoke Test)

Use the testing guide which runs a **Kubernetes Job** per zone with waits/retries and TLS `VERIFY_CA`:

- `docs/testing/db-smoke-test.md`

High-level:
1. Save kubeconfig for the cluster (`doctl kubernetes cluster kubeconfig save ...`).
2. `terraform output -json` → export `DB_*` env vars + write CA.
3. `kubectl create secret db-smoke ...`
4. Apply **Job** manifest and `kubectl logs job/db-smoke`.

**Success criteria:**
- Logs show `mysqld is alive`, `SELECT 1` table with `1`, and `OK`.
- Job status: `Complete`.

---

## 5) Destroy (Cleanup)

Destroy **per workspace** — BZ first, then PZ, to keep prod stable.

```bash
# BZ
terraform workspace select prod-bz
terraform plan -destroy -var-file=../env/prod/bz.tfvars
terraform destroy      -var-file=../env/prod/bz.tfvars

# PZ
terraform workspace select prod-pz
terraform plan -destroy -var-file=../env/prod/pz.tfvars
terraform destroy      -var-file=../env/prod/pz.tfvars
```

> Reminder: `terraform destroy` only affects the **current workspace** state.

---

## 6) Post-Test Reset

- Keep PZ running.
- Set `enable_db_bz = false` in `terraform/env/prod/bz.tfvars` to return BZ to **cold**.
- Store DB outputs in a secret manager (do **not** commit raw values).

---

## Troubleshooting

- **BZ tries to create PZ DB**  
  Ensure `enable_db_pz = false` in `bz.tfvars` and default is `false` in root vars.

- **VPC errors / overlaps**  
  We no longer create VPCs. Ensure code uses the **default VPC lookup** (`default-<region>`) for cluster and DB.

- **Missing vars prompt (e.g., cluster_name)**  
  Ensure your `*.tfvars` include **both** K8s + DB sections for each zone (or pass two `-var-file` if you separate them).

- **Kubeconfig (Snap)**  
  `sudo snap connect doctl:kube-config`; fix `~/.kube` perms (`700` dir, `600` file).

- **MySQL port empty**  
  Export with `| tostring` and include in Secret; Job defaults to `3306` if empty.

- **TLS/CA issues**  
  Make sure you mount the CA from Terraform outputs and use `--ssl-mode=VERIFY_CA`.
