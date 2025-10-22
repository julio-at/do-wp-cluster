# Runbook — Restore Writer in BZ (Backup/Restore Strategy)

**Purpose:** Activate **Backup Zone (BZ)** by **restoring** a MySQL writer from backups/PITR (Stage 07, Option B).

---

## Preconditions
- Incident declared; DR activation approved.
- Backup source verified (latest snapshot/PITR time).
- BZ cluster/platform ready (Stage 06).

---

## Inputs
- Backup timestamp/identifier (or PITR target).
- Desired DB name, size, and region `sfo3` (BZ).
- Kube context: `export KUBECONFIG=$PWD/artifacts/kubeconfig-bz`.

---

## Steps

### 1) Restore DB in BZ
- Use provider UI/API to restore a new **writer** in `sfo3` from the chosen backup/PITR.
- Record: restore start time, finish time, and final endpoint.

### 2) Prepare app secrets for BZ
```bash
kubectl -n app create secret generic wp-db --dry-run=client -o yaml   --from-literal=DB_HOST='<bz-writer-host:port>'   --from-literal=DB_NAME='wordpress'   --from-literal=DB_USER='<db-user>'   --from-literal=DB_PASSWORD='<db-password>'   --from-file=DB_CA_CERT='./ca-certificate.crt' | kubectl apply -f -
```

### 3) Deploy/scale WordPress
```bash
kubectl -n app scale deploy/wp --replicas=3   # or 1 initially, then up
kubectl -n app rollout status deploy/wp --timeout=180s
```

### 4) Expose BZ and ensure TLS
- Ensure Ingress Controller LB exists in BZ.
- Ensure certificate `wp-tls` is issued for `wp-bz.guajiro.xyz`:
```bash
kubectl -n app get certificate wp-tls
```

### 5) Flip DNS
- Update `wp-active.guajiro.xyz` CNAME → `wp-bz.guajiro.xyz` (see DNS runbook).

### 6) Validate
- Synthetic (curl) + business flows (login/post/media).

---

## Rollback
- If restore or app fails, keep traffic on PZ and reattempt or switch to alternative restore point.
- For failback: restore to PZ from BZ’s latest data or set up replication back, per Stage 07.

---

## Notes
- RPO is defined by backup recency; record the backup timestamp and compute delta.
