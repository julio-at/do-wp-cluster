# Runbook — Promote Replica to Writer (BZ)

**Purpose:** Promote the managed MySQL **read-replica** in **Backup Zone (BZ)** to **writer** during DR activation (Stage 07, Option A).

**Applies to:** DigitalOcean Managed MySQL (or equivalent) with an existing read-replica in BZ.

---

## Preconditions
- Incident declared by IC; decision to activate BZ.
- BZ cluster/platform ready (Stage 06).
- Replica **healthy** and replication **lag** within acceptable threshold (observe in DO UI/metrics).
- App in BZ either deployed with `replicas=0/1` and ready to scale.

---

## Inputs
- BZ DB identifier / connection string.
- App secrets/config names in namespace `app` (`wp-db`, `wp-s3`, etc.).
- Kube context for BZ: `export KUBECONFIG=$PWD/artifacts/kubeconfig-bz`.

---

## Steps

### 1) Verify replica health & capture lag
Record current lag (for RPO):
- DO dashboard or API.
- Note timestamp and seconds lag.

### 2) Promote the replica to writer
Use DO control panel or API/CLI:
- **Control panel:** Select the replica → **Promote**.
- **API/CLI:** Follow DO docs to _promote_ replica to standalone writer.

Wait until status is **online** and **writer**.

### 3) Update application DB secrets (if endpoint changes)
If promotion gives a new hostname/port, update secret in BZ:
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-bz
kubectl -n app create secret generic wp-db --dry-run=client -o yaml   --from-literal=DB_HOST='<bz-writer-host:port>'   --from-literal=DB_NAME='wordpress'   --from-literal=DB_USER='<db-user>'   --from-literal=DB_PASSWORD='<db-password>'   --from-file=DB_CA_CERT='./ca-certificate.crt' | kubectl apply -f -
```

### 4) Restart/scale the app in BZ
```bash
kubectl -n app rollout restart deploy/wp
kubectl -n app scale deploy/wp --replicas=3   # adjust as needed
kubectl -n app rollout status deploy/wp --timeout=180s
```

### 5) Expose BZ (if not already) and ensure TLS
- Ensure Ingress Controller LB exists in BZ (Stage 04 procedure).
- Ensure a valid cert exists for `wp-bz.guajiro.xyz`:
```bash
kubectl -n app get certificate wp-tls
```

### 6) Flip DNS (CNAME)
- Update `wp-active.guajiro.xyz` → `wp-bz.guajiro.xyz` (see DNS runbook).

### 7) Validate
- `curl -I https://wp-active.guajiro.xyz` → 200/301 + valid cert.
- Login to wp-admin, create post, upload media.
- Observe error rate & latency in dashboards.

---

## Rollback
- If promotion failed or app unhealthy, scale BZ back down and keep traffic on PZ.
- For long incidents, proceed with BZ while planning failback later (separate runbook).

---

## Notes
- Promotion may sever upstream replication. For failback, create a new replica in PZ sourced from BZ or restore fresh, per Stage 07.
