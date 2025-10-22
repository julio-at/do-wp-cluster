# Runbook — Failback to Primary Zone (PZ)

**Purpose:** Return production traffic to **Primary Zone (PZ)** after DR activation on BZ, restoring symmetry and normal operations.

---

## Preconditions
- PZ is healthy and has a **writer** DB:
  - If Strategy A (Replica): create a **new replica** in PZ sourced from **BZ writer**, then promote to writer.
  - If Strategy B (Restore): restore PZ writer from the freshest backup (or replicate from BZ).
- PZ Ingress/TLS are validated.
- Stakeholders notified; change window approved.

---

## Steps

### 1) Prepare PZ application
- Ensure app secrets point to **PZ writer** (update if needed):
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-pz
kubectl -n app create secret generic wp-db --dry-run=client -o yaml   --from-literal=DB_HOST='<pz-writer-host:port>'   --from-literal=DB_NAME='wordpress'   --from-literal=DB_USER='<db-user>'   --from-literal=DB_PASSWORD='<db-password>'   --from-file=DB_CA_CERT='./ca-certificate.crt' | kubectl apply -f -

kubectl -n app rollout restart deploy/wp
kubectl -n app rollout status deploy/wp --timeout=180s
```

### 2) Verify PZ exposure and TLS
```bash
kubectl -n app get ingress
kubectl -n app get certificate wp-tls
curl -I https://wp-pz.guajiro.xyz
```

### 3) Flip CNAME back to PZ
- Change `wp-active.guajiro.xyz` → `wp-pz.guajiro.xyz` (see flip runbook).
- Keep TTL low during the flip; restore after stability.

### 4) Validate
- Synthetic and business checks on `https://wp-active.guajiro.xyz` now served by PZ.
- Observe error rate & latency for stability window (e.g., 30–60 min).

### 5) Stand down BZ
- Scale down WP in BZ (or destroy BZ infra if DR on-demand):
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-bz
kubectl -n app scale deploy/wp --replicas=0
```
- Optionally, keep BZ platform running or tear down per cost policy.

---

## Notes
- Capture timestamps for each step; update runbooks with lessons learned.
- Ensure data consistency before tearing down/altering replication directions.
