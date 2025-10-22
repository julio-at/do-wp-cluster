# Runbook — DB in BZ (sfo3) Cold

## Objective
Keep BZ defined but **not created** until activation (DR). When required, enable it and optionally restore from snapshot/PITR.

---

## Validate without creating resources
```bash
cd terraform/doks

terraform workspace select prod-bz || terraform workspace new prod-bz

terraform plan   -var-file=../env/prod/bz.tfvars   -out=tfplan-bz

# With enable_db_bz = false nothing should be created.
```

---

## Activation (for DR or Game-Day)
1. Edit `terraform/env/prod/bz.tfvars`:
   ```hcl
   enable_db_bz = true

   trusted_sources_bz_cluster_ids = [
     "UUID_OF_BZ_CLUSTER"   # if BZ cluster exists
   ]

   trusted_sources_bz_cidrs = [
     # Keep empty unless temporary bootstrap is needed
   ]
   ```
2. Run:
   ```bash
   cd terraform/doks

   terraform plan      -var-file=../env/prod/bz.tfvars      -out=tfplan-bz

   terraform apply      tfplan-bz
   ```

---

## DR (Restore-on-activation)
- Restore in BZ from snapshot/PITR within DO retention window.
- Adjust DNS: `wp-active.guajiro.xyz` → `wp-bz.guajiro.xyz` (see DNS runbook).
- Later **failback** to PZ when incident ends; document the window.
