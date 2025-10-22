# Stage 05 — Minimal Application (WordPress, PZ only)

> **Goal:** Deploy a minimal, production-leaning WordPress on **PZ** with **replicas=1**, connected to **DigitalOcean Managed MySQL (writer in PZ)**, media on **object storage (S3-compatible)**, and fronted by the **Ingress Controller** from Stage 04 with **TLS via cert-manager**.  
> **Note:** We keep BZ off (on-demand). We do *not* enable autoscaling for the app yet; we focus on a clean, reproducible baseline.

---

## Prerequisites
- **Kube context:** PZ (`export KUBECONFIG=$PWD/artifacts/kubeconfig-pz`).
- **DNS:** From Stage 04 → `wp-active.guajiro.xyz` CNAME → `wp-pz.guajiro.xyz`.
- **TLS:** `ClusterIssuer le-prod-cloudflare` exists (Stage 03).
- **DB (PZ):** DigitalOcean Managed MySQL **writer** provisioned. You have:
  - `DB_HOST` (hostname and port), `DB_NAME`, `DB_USER`, `DB_PASSWORD`
  - **CA bundle** for TLS (DO provides this) — we will store it as a secret.
  - Optionally restrict “trusted sources” to VPC CIDR (configured on the DB side).
- **Object Storage:** S3-compatible bucket for media (e.g., DO Spaces, Cloudflare R2, etc.). You have:
  - `S3_ENDPOINT`, `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`

> We keep storage **stateless** at the pod level; media goes to object storage and DB holds content/meta only.

---

## Namespaces & labels
We’ll use the `app` namespace (created in Stage 03). Add helpful labels:
```bash
kubectl label ns app project=wp env=prod zone=pz --overwrite
```

---

## Secrets & Config (DB + TLS CA + S3)

### 1) Database credentials and TLS CA
Create a secret containing DB credentials and the CA bundle that WordPress/PHP will trust.

```bash
kubectl -n app create secret generic wp-db   --from-literal=DB_HOST='<db-host:port>'   --from-literal=DB_NAME='wordpress'   --from-literal=DB_USER='<db-user>'   --from-literal=DB_PASSWORD='<db-password>'   --from-file=DB_CA_CERT='./ca-certificate.crt'
```

> Use the CA file provided by DO Managed MySQL. If you rotate it later, update this secret and restart the pods.

### 2) S3/Spaces credentials for media
```bash
kubectl -n app create secret generic wp-s3   --from-literal=S3_ENDPOINT='https://<endpoint>'   --from-literal=S3_BUCKET='wp-media'   --from-literal=S3_REGION='auto'   --from-literal=S3_ACCESS_KEY_ID='<access-key>'   --from-literal=S3_SECRET_ACCESS_KEY='<secret-key>'
```

> We’ll wire these into the container as env vars (plugin config).

---

## Deploy WordPress (replicas=1)

You can use any of these approaches. Pick **one** for first run:

- **A. Helm chart (generic)** — fastest path, pass env for external DB and disable bundled MariaDB.
- **B. Kustomize / Raw manifests** — more explicit, good for long-term control.

Below we outline a **generic Helm approach** conceptually (no vendor-specific values assumed). Adjust the names/keys to match the chart you choose.

### Option A — Helm (conceptual values)
Key ideas:
- `replicaCount=1`
- **Disable internal DB** (if the chart ships MariaDB).
- Wire external DB host/user/password and **TLS** (CA mount + driver opts).
- Set `ingress.enabled=true`, host `wp-active.guajiro.xyz`, TLS with `le-prod-cloudflare`.
- Mount S3 creds as env vars; install an S3 media plugin in WordPress afterwards (UI).

Example *values blueprint* (for your chart of choice):
```yaml
replicaCount: 1

image:
  pullPolicy: IfNotPresent

podSecurityContext: {}
securityContext: {}

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: le-prod-cloudflare
  hosts:
    - host: wp-active.guajiro.xyz
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wp-tls
      hosts:
        - wp-active.guajiro.xyz

resources:
  requests:
    cpu: "100m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# External DB wiring (chart-specific keys)
externalDatabase:
  enabled: true
  host: "$(DB_HOST)"
  user: "$(DB_USER)"
  password: "$(DB_PASSWORD)"
  database: "$(DB_NAME)"
  # TLS depending on chart: sometimes a boolean flag + custom args for mysqli
  tls:
    caSecretName: wp-db
    caSecretKey: DB_CA_CERT

env:
  - name: DB_HOST
    valueFrom:
      secretKeyRef: { name: wp-db, key: DB_HOST }
  - name: DB_USER
    valueFrom:
      secretKeyRef: { name: wp-db, key: DB_USER }
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef: { name: wp-db, key: DB_PASSWORD }
  - name: DB_NAME
    valueFrom:
      secretKeyRef: { name: wp-db, key: DB_NAME }

  # S3 media integration (plugin config via env)
  - name: S3_ENDPOINT
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_ENDPOINT } }
  - name: S3_BUCKET
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_BUCKET } }
  - name: S3_REGION
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_REGION } }
  - name: S3_ACCESS_KEY_ID
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_ACCESS_KEY_ID } }
  - name: S3_SECRET_ACCESS_KEY
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_SECRET_ACCESS_KEY } }
```

> **Install:** `helm upgrade --install wp <chart-name> -n app -f values.yaml`  
> After first login, install/configure your S3 media plugin (e.g., “WP Offload Media” or similar) and point it at the env vars above.

### Option B — Raw manifests (outline)
- `Deployment` with 1 replica, liveness/readiness on `/wp-login.php` or a custom `/healthz` implemented by a tiny PHP probe script.
- `Service` ClusterIP on 80.
- `Ingress` with class `nginx`, host `wp-active.guajiro.xyz`, TLS annotation for `le-prod-cloudflare` and `secretName: wp-tls`.
- `ConfigMap`/`Secret` for DB and S3 as in the previous section.
- Add an initContainer (optional) that verifies DB connectivity with TLS before starting WordPress.

---

## Verification checklist

1) **Pods running**
```bash
kubectl -n app get deploy,po,svc | grep wp
```
2) **Ingress & TLS**
```bash
kubectl -n app get ingress
kubectl -n app describe certificate wp-tls
```
- Certificate should reach `Ready=True`.
- `curl -I https://wp-active.guajiro.xyz` returns `200/301` with a valid cert.

3) **WordPress first-run**
- Visit `https://wp-active.guajiro.xyz`, complete initial setup (admin user).

4) **Media test**
- Install your S3 media plugin, configure keys/endpoint/bucket.
- Upload an image; confirm it lands in the bucket and URLs are CDN-able.

5) **Observability**
- Prometheus shows targets for kubelet, kube-state, and your app’s namespace.
- Optionally add a ServiceMonitor for NGINX Ingress metrics (later).

---

## Troubleshooting

- **TLS pending:** cert-manager logs; ensure `ClusterIssuer` name matches and DNS-01 can write `_acme-challenge` records.
- **502/404 at Ingress:** controller not ready or Service/Endpoints mismatch → `kubectl -n platform get svc ingress-nginx-controller -o wide` and `kubectl -n app describe ing ...`
- **DB connection errors:** verify `DB_HOST` includes port, the CA is mounted, and the DB allows connections from the cluster VPC.
- **S3 plugin not storing objects:** check bucket policy/permissions and whether the plugin honors the env var names; adjust accordingly.

---

## Rollback / Cleanup
```bash
# If using Helm:
helm -n app uninstall wp || true
kubectl -n app delete secret wp-db wp-s3 || true
kubectl -n app delete certificate wp-tls || true
```
> Leave the Ingress Controller from Stage 04 intact. The DNS CNAME chain remains the same.

---

## Exit Criteria
- WordPress reachable at `https://wp-active.guajiro.xyz` with a valid TLS cert.
- Can log in and **upload media** that lands in object storage.
- Observability shows healthy app and no persistent 5xx.

---

## Next Stage (06 — Backup Zone On‑Demand)
- Mirror the platform/app baseline in BZ (with `replicas=0` or 1).
- Decide DR path: **read-replica** in BZ (low RPO) or **restore** on activation (lower cost).
- Keep DNS strategy: only flip `wp-active` when promoting BZ.
