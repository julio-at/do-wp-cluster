# Stage 03 — Platform Baseline (no public exposure)

## Purpose
Prepare each cluster (PZ/BZ) to host applications safely and observably **without** exposing services yet. We set up:
- Namespaces & base RBAC
- `cert-manager` with **DNS-01 via Cloudflare** (staging + prod Issuers)
- Observability baseline: **kube-prometheus-stack** (Prometheus, Alertmanager, Grafana) with internal-only services

## Scope
- Applies independently to each zone (run on PZ first, then BZ when needed).
- No LoadBalancers, no Ingress Controller yet (that is Stage 04).

---

## Prerequisites
- Working kubeconfig for the target zone:
  - PZ: `artifacts/kubeconfig-pz`
  - BZ: `artifacts/kubeconfig-bz`
- Cloudflare API token with permissions for DNS-01 (Zone:DNS:Edit, Zone:Read).
- `helm` ≥ 3.12, `kubectl`.

Set your context (example PZ):
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-pz
kubectl get nodes
```

---

## Namespaces & base layout
We’ll standardize two namespaces:
- `platform` – platform components (cert-manager, monitoring stack)
- `app` – application workloads (WordPress later)

```bash
kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
```

(Optional) A simple read-only ClusterRole for on-call dashboards:
```yaml
# docs/snippets/clusterrole-readonly.yaml (optional)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: { name: view-readonly }
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get","list","watch"]
```
> Apply later if you need limited view-only access.

---

## cert-manager (DNS-01 with Cloudflare)

### 1) Install cert-manager (CRDs enabled)
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager   --namespace platform   --set crds.enabled=true
kubectl -n platform rollout status deploy/cert-manager-webhook --timeout=180s
```

### 2) Store the Cloudflare API token (secret)
Use a **scoped** API token (Zone:DNS:Edit + Zone:Read), not a global key.

```bash
kubectl -n platform create secret generic cloudflare-api-token-secret   --from-literal=api-token='<YOUR_CF_API_TOKEN>'
```

### 3) Create ClusterIssuers (Let’s Encrypt staging & prod)
Copy/paste and apply:

```yaml
# docs/snippets/clusterissuers-cloudflare.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: le-staging-cloudflare
spec:
  acme:
    email: your-email@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef: { name: le-staging-account-key }
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: le-prod-cloudflare
spec:
  acme:
    email: your-email@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef: { name: le-prod-account-key }
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

Apply:
```bash
kubectl apply -f docs/snippets/clusterissuers-cloudflare.yaml
kubectl get clusterissuers
```

> **Note:** We’ll reference `le-prod-cloudflare` (or `le-staging-cloudflare`) in Ingress TLS annotations during Stage 04.

---

## Observability baseline (kube-prometheus-stack)

### 1) Install the stack (internal-only)
We keep services `ClusterIP` (no LoadBalancer/Ingress) in this stage.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack   --namespace platform   --set grafana.service.type=ClusterIP   --set prometheus.service.type=ClusterIP   --set alertmanager.service.type=ClusterIP
```

Wait for readiness:
```bash
kubectl -n platform rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager --timeout=300s
kubectl -n platform rollout status statefulset/monitoring-kube-prometheus-prometheus --timeout=300s
kubectl -n platform rollout status deploy/monitoring-grafana --timeout=300s
```

### 2) Quick sanity checks
```bash
# Prometheus targets
kubectl -n platform port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
# visit http://localhost:9090/targets

# Grafana (temporary, local)
kubectl -n platform port-forward svc/monitoring-grafana 3000:80
# visit http://localhost:3000  (admin/admin by default unless chart changes)
```
> We won’t expose Grafana publicly until Stage 04 (via Ingress/TLS).

---

## Validation Checklist
- `platform` and `app` namespaces exist.
- `cert-manager` pods healthy in `platform`.  
  `kubectl -n platform get pods -l app.kubernetes.io/instance=cert-manager`
- ClusterIssuers created: `le-staging-cloudflare`, `le-prod-cloudflare`.
- kube-prometheus-stack components healthy:
  - Prometheus, Alertmanager, Grafana pods are `Running`
  - Prometheus shows **Targets** for kube-state-metrics and node-exporter as **UP**
- No LoadBalancer services created yet.

---

## Troubleshooting
- **cert-manager pending challenges (DNS-01):** verify the CF token scope, DNS zone, and that cert-manager can update `_acme-challenge` records (check Cloudflare dashboard).  
- **Grafana/Prometheus unreachable:** ensure you’re using **port-forward** (ClusterIP only at this stage).  
- **Helm CRD errors:** make sure `--set crds.enabled=true` was used on first install of cert-manager.

---

## Artifacts to Capture
- Screenshot of Prometheus **Targets** page (all core targets UP).
- Screenshot of Grafana home (to confirm the instance is alive).
- `kubectl get clusterissuer -o yaml` outputs filed for audit.

---

## Exit Criteria
- Both components (cert-manager + kube-prometheus-stack) are **installed, healthy, and internal-only**.
- ClusterIssuers ready to be referenced by future Ingresses.
- No public endpoints created.

---

## Next Stage (04 — DNS & Exposure)
- Install **Ingress NGINX** (controller) and configure TLS via `cert-manager` (DNS-01).
- Decide initial DNS pattern:
  - **CNAME chain** (`wp-active → wp-pz|wp-bz`) with per-zone hostnames
  - (Later) Cloudflare Load Balancer with pools/weights.
- Keep everything minimal and reversible for DR tests.
