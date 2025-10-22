# Runbook — Platform Teardown (Zone safe shutdown)

**Purpose:** Safely tear down a zone to save costs, ensuring dependencies are removed in the right order to avoid provider errors (e.g., VPC with members).

---

## Preconditions
- Confirm the zone is **not serving traffic** (check DNS `wp-active.guajiro.xyz` target).
- Obtain approval/change window if required.
- Kube context for the zone available (kubeconfig file).

---

## Steps

### 1) Remove application layer
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-<zone>
# If Helm was used:
helm -n app uninstall wp || true
# Clean secrets/certs if desired:
kubectl -n app delete secret wp-db wp-s3 || true
kubectl -n app delete certificate wp-tls || true
```

### 2) Remove platform addons (optional)
```bash
# Observability stack
helm -n platform uninstall monitoring || true

# cert-manager (leave if you plan to reuse soon)
helm -n platform uninstall cert-manager || true

# Ingress controller (if it exists)
helm -n platform uninstall ingress-nginx || true
```

### 3) Verify no LoadBalancers remain
```bash
kubectl -n platform get svc | grep -i loadbalancer || true
kubectl get svc -A | grep -i loadbalancer || true
```

### 4) Destroy cluster (before VPC)
```bash
cd terraform/doks
terraform workspace select <zone-workspace>
terraform destroy -target=digitalocean_kubernetes_cluster.this -var-file=../env/prod/<zone>.tfvars
# wait until fully deleted
terraform destroy -var-file=../env/prod/<zone>.tfvars
```

> Destroying the cluster first avoids `409 Can not delete VPC with members` errors.

### 5) Confirm cleanup
- `doctl` (optional): no clusters, LBs, DBs, or volumes are attached.
- `terraform state` has no remaining resources for that workspace.

---

## Exit Criteria
- No resources left in the zone (VPC and cluster removed cleanly).
- No public endpoints or dangling load balancers.
