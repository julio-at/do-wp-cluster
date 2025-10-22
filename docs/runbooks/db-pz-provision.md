# Runbook — Provision DB in PZ (nyc3) in 2 Steps

## Goal
Create DigitalOcean Managed MySQL **after** the DOKS PZ cluster exists so the DB firewall only allows the cluster. 100% idempotent and aligned with do-wp-cluster.

---

## Prerequisites
- Valid DO token for Terraform and doctl.
- Up-to-date `terraform` (>= 1.5) and `doctl`.
- This repo layout with `terraform/doks` as the IaC root for DOKS/DB.

---

## Step A — Create/ensure PZ cluster (DB OFF)

1. Edit `terraform/env/prod/pz.tfvars`:
   ```hcl
   enable_db_pz = false
   ```
2. Run:
   ```bash
   cd terraform/doks

   terraform workspace select prod-pz || terraform workspace new prod-pz

   terraform plan      -var-file=../env/prod/pz.tfvars      -out=tfplan-pz

   terraform apply      tfplan-pz
   ```
3. Get the **UUID** of the PZ cluster:
   ```bash
   doctl auth init --access-token 'dop_v1_xxx'   # if needed
   doctl account get                             # sanity check
   doctl kubernetes cluster list                 # copy the UUID
   ```

---

## Step B — Create PZ DB (DB ON) and pin firewall to the cluster

1. Edit `terraform/env/prod/pz.tfvars`:
   ```hcl
   enable_db_pz = true

   trusted_sources_pz_cluster_ids = [
     "UUID_OF_PZ_CLUSTER"
   ]

   trusted_sources_pz_cidrs = [
     # Keep empty unless you need temporary bootstrap
   ]
   ```
2. Run:
   ```bash
   cd terraform/doks

   terraform plan      -var-file=../env/prod/pz.tfvars      -out=tfplan-pz

   terraform apply      tfplan-pz
   ```

---

## Verification (do not print secrets)
```bash
terraform output -json | jq 'keys'
terraform output -json db_pz | jq 'keys'
# Expected: host, private_host, port, database, username, password, uri, private_uri, ca_cert
```

---

## Success Criteria
- `digitalocean_database_cluster` created in **nyc3** with minimal tier.
- `digitalocean_database_db` and `digitalocean_database_user` created.
- `digitalocean_database_firewall` present with `k8s` rule → PZ cluster UUID.
- Sensitive outputs are available (but not printed to logs).

---

## Smoke Test (optional, once K8s PZ exists)
1. Create a `Secret` with values from `db_pz` (host/port/user/password/CA).
2. Deploy a `mysql:8.0` pod that runs `mysqladmin ping` with `--ssl-mode=VERIFY_CA`.
3. Expected log: **“mysqld is alive”**.

---

## Troubleshooting
- **401 doctl** → rotate PAT and `doctl auth init --access-token '...'`.
- **“Module not installed”** → `rm -rf .terraform* && terraform init -upgrade`.
- **Invalid variable `version`** → use `engine_version` instead.
- **Wrong provider (`hashicorp/digitalocean`)** → add module `versions.tf` with `source = "digitalocean/digitalocean"`.
- **Unsupported attributes (`mysql_uri`, `ca_certificate`)** → use `cluster.uri/private_uri` and `data.digitalocean_database_ca.certificate`.
- **“Insufficient rule blocks”** → firewall is only created when at least one rule exists; add `trusted_sources_pz_cluster_ids = ["UUID"]`.

---

## Rollback
- Remove **DB only** (keep cluster): set `enable_db_pz = false` and `apply` in `prod-pz`.
- **Do not** destroy production without explicit approval.
