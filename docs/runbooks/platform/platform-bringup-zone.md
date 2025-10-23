# Runbook — Platform Bring-up per Zone (Stage 03)

**Goal:** Install **cert-manager** and **NGINX Ingress** per zone following the repo structure. Use **DNS-01 (Cloudflare)**. No public exposure yet.

> Run these steps in **PZ** first. For **BZ**, only do cert-manager + issuers; keep ingress cold.

---

## 0) Select Zone & Kubecontext
- Ensure kubecontext for the target zone is active:
```bash
# PZ (example)
doctl kubernetes cluster kubeconfig save wp-pz-doks-nyc3
kubectl config current-context

# BZ (when prepping)
doctl kubernetes cluster kubeconfig save wp-bz-doks-sfo3
kubectl config current-context
```

---

## 1) Namespaces + Cloudflare Token Secret
Create namespaces and store the Cloudflare token (scope: zone `guajiro.xyz`).

```bash
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Secret must be in cert-manager namespace, key must be 'api-token'
kubectl -n cert-manager create secret generic cloudflare-api-token   --from-literal=api-token='REPLACE_WITH_CLOUDFLARE_API_TOKEN'   --dry-run=client -o yaml | kubectl apply -f -
```

**Notes**
- Use a **scoped** token (Zone DNS edit + Zone read) for `guajiro.xyz`.
- Prefer not to commit the token; inject via env/automation or secrets manager.

---

## 2) Install cert-manager (Helm)
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager   --namespace cert-manager   --version v1.15.3   --set installCRDs=true

kubectl -n cert-manager get pods
```

Expected: all cert-manager pods **Running**.

---

## 3) Apply ClusterIssuers (Cloudflare DNS-01)
Reference: `docs/snippets/clusterissuers-cloudflare.md`

Apply per zone (PZ first):
```bash
# PZ
kubectl apply -f k8s/platform/pz/cert-manager/clusterissuers.yaml
kubectl get clusterissuers

# BZ (prep)
kubectl apply -f k8s/platform/bz/cert-manager/clusterissuers.yaml
kubectl get clusterissuers
```

**Optional:** Pre-provision a staging `Certificate` for known hostnames (no DNS A/AAAA required for DNS-01).

---

## 4) Install NGINX Ingress Controller
**PZ (active):**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx   --namespace ingress-nginx   -f k8s/platform/pz/ingress-nginx/values.yaml

kubectl -n ingress-nginx get svc ingress-nginx-controller
```

**BZ (keep cold):** either skip or keep `replicaCount: 0` in values.yaml and install the chart, so it’s ready to scale.

---

## 5) Optional: HTTP Smoke (PZ)
```bash
kubectl apply -f k8s/platform/pz/ingress-nginx/echo.yaml
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
EXTERNAL_IP="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
curl -s "http://${EXTERNAL_IP}/" | head
```

Cleanup (optional):
```bash
kubectl delete -f k8s/platform/pz/ingress-nginx/echo.yaml
```

---

## 6) Outputs / Evidence
- `ClusterIssuer` resources show **Ready**.
- `ingress-nginx-controller` has **EXTERNAL-IP**.
- (Optional) Echo returns an HTTP response at the controller’s EXTERNAL-IP.

---

## 7) Next (Stage-04)
- Create DNS records pointing to PZ LB (and BZ when needed).  
- Switch `Certificate` IssuerRef to **prod** and re-issue.  
- Prepare Ingress for WordPress (TLS, security headers, allowed paths).

---

## Rollback
- Uninstall ingress-nginx (PZ):  
  `helm -n ingress-nginx uninstall ingress-nginx`
- Leave cert-manager and issuers in place; they’re safe to keep for Stage-04.
