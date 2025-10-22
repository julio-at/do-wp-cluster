# Runbook — Platform Bring-Up (Zone bootstrap)

**Purpose:** Bring up a fresh zone (PZ or BZ) from zero to a **ready-but-not-exposed** platform state: VPC/DOKS (if needed), namespaces, cert-manager (DNS-01 with Cloudflare), and kube-prometheus-stack. No public exposure yet.

---

## Preconditions
- Terraform var-file for the target zone ready (e.g., `terraform/env/prod/pz.tfvars` or `bz.tfvars`).
- Cloudflare API token with `Zone:Read` + `Zone:DNS:Edit` for `guajiro.xyz`.
- Local tools: `terraform ≥ 1.6`, `kubectl`, `helm` ≥ 3.12.

---

## Steps

### 1) (If needed) Create VPC + DOKS cluster
```bash
cd terraform/doks
terraform init -upgrade
terraform workspace new <zone-workspace> || terraform workspace select <zone-workspace>
terraform apply -var-file=../env/prod/<zone>.tfvars
# Outputs
terraform output -raw kubeconfig_raw > ../../artifacts/kubeconfig-<zone>
export KUBECONFIG=$PWD/../../artifacts/kubeconfig-<zone>
kubectl get nodes
```

### 2) Create namespaces
```bash
kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace app --dry-run=client -o yaml | kubectl apply -f -
```

### 3) Install cert-manager (CRDs enabled)
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager   --namespace platform   --set crds.enabled=true
kubectl -n platform rollout status deploy/cert-manager-webhook --timeout=180s
```

### 4) Store Cloudflare API token (secret)
```bash
kubectl -n platform create secret generic cloudflare-api-token-secret   --from-literal=api-token='<YOUR_CF_API_TOKEN>' --dry-run=client -o yaml | kubectl apply -f -
```

### 5) Create ClusterIssuers (staging + prod)
`docs/snippets/clusterissuers-cloudflare.yaml` from Stage 03:
```bash
kubectl apply -f docs/snippets/clusterissuers-cloudflare.yaml
kubectl get clusterissuer
```

### 6) Install kube-prometheus-stack (internal-only)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack   --namespace platform   --set grafana.service.type=ClusterIP   --set prometheus.service.type=ClusterIP   --set alertmanager.service.type=ClusterIP

kubectl -n platform rollout status deploy/monitoring-grafana --timeout=300s
kubectl -n platform rollout status statefulset/monitoring-kube-prometheus-prometheus --timeout=300s
kubectl -n platform rollout status statefulset/alertmanager-monitoring-kube-prometheus-alertmanager --timeout=300s
```

### 7) Validation
- Namespaces exist: `platform`, `app`
- cert-manager: webhook/CM/CA pods healthy
- ClusterIssuers present
- Prometheus/Grafana/Alertmanager running (ClusterIP only)

---

## Exit Criteria
- Zone is ready for application deployment (Stage 05) and later exposure (Stage 04) without public endpoints yet.
