# Runbook — WordPress Minimal Deploy (PZ)

**Purpose:** Deploy a minimal WordPress in **Primary Zone (PZ)** with external DB (DO Managed MySQL), S3-compatible media, and TLS via cert-manager. Mirrors Stage 05 steps as a concise runbook.

---

## Preconditions
- PZ kubeconfig: `artifacts/kubeconfig-pz`
- DB writer in PZ: host/port/db/user/password + CA file
- S3-compatible bucket and credentials
- Ingress Controller installed (Stage 04)
- `wp-active.guajiro.xyz` → `wp-pz.guajiro.xyz` CNAME set (Stage 04)

---

## Steps

### 1) Context and namespaces
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-pz
kubectl create ns app --dry-run=client -o yaml | kubectl apply -f -
```

### 2) Secrets (DB + CA + S3)
```bash
kubectl -n app create secret generic wp-db --dry-run=client -o yaml   --from-literal=DB_HOST='<db-host:port>'   --from-literal=DB_NAME='wordpress'   --from-literal=DB_USER='<db-user>'   --from-literal=DB_PASSWORD='<db-password>'   --from-file=DB_CA_CERT='./ca-certificate.crt' | kubectl apply -f -

kubectl -n app create secret generic wp-s3 --dry-run=client -o yaml   --from-literal=S3_ENDPOINT='https://<endpoint>'   --from-literal=S3_BUCKET='wp-media'   --from-literal=S3_REGION='auto'   --from-literal=S3_ACCESS_KEY_ID='<access-key>'   --from-literal=S3_SECRET_ACCESS_KEY='<secret-key>' | kubectl apply -f -
```

### 3) Deploy WordPress (Helm example, conceptual values)
```bash
helm upgrade --install wp <chart-name> -n app   --set replicaCount=1   --set ingress.enabled=true   --set ingress.className=nginx   --set ingress.annotations."cert-manager\.io/cluster-issuer"=le-prod-cloudflare   --set ingress.tls[0].secretName=wp-tls   --set ingress.tls[0].hosts[0]=wp-active.guajiro.xyz   --set ingress.hosts[0].host=wp-active.guajiro.xyz   --set ingress.hosts[0].paths[0].path=/   --set ingress.hosts[0].paths[0].pathType=Prefix
```

> Add chart-specific values to point at external DB and mount the CA from `wp-db`. Configure S3 plugin after first login.

### 4) Validate
```bash
kubectl -n app get deploy,po,svc,ing
kubectl -n app describe certificate wp-tls
curl -I https://wp-active.guajiro.xyz
```

### 5) First-run (UI)
- Complete WordPress setup.
- Install and configure the S3 media plugin; upload test image.

---

## Exit Criteria
- HTTPS works for `wp-active.guajiro.xyz` with a valid cert.
- Admin login and media upload succeed.
