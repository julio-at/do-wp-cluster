# Stage 02 — Minimal Infrastructure (VPC + DOKS)

## Definition of Done (DoD)
- PZ cluster **up** in `nyc3`, BZ cluster **up** in `sfo3`.
- Unique VPC per cluster (non-overlapping CIDRs).
- Kubeconfigs exported and validated (`kubectl get nodes` works for each).
- Effective Kubernetes versions recorded.

## What We Create (and what we **don’t**)
- **Create:** DigitalOcean VPC, DigitalOcean Kubernetes Cluster (node pool) per zone.  
- **Do NOT create yet:** Load Balancers, Ingress, cert-manager, app workloads, or DNS.

## Inputs (per zone)
Example PZ (`terraform/env/prod/pz.tfvars`):
```hcl
region                   = "nyc3"
cluster_name             = "wp-pz-doks-nyc3"
kubernetes_version       = ""          # empty → select latest matching prefix
kubernetes_minor_prefix  = "1.30"
node_size                = "s-2vcpu-4gb"
node_count               = 3
vpc_cidr                 = "10.10.0.0/16"
tags = ["project:wp","env:prod","zone:pz","region:nyc3"]
```
Example BZ (`terraform/env/prod/bz.tfvars`):
```hcl
region                   = "sfo3"
cluster_name             = "wp-bz-doks-sfo3"
kubernetes_version       = ""
kubernetes_minor_prefix  = "1.30"
node_size                = "s-2vcpu-4gb"
node_count               = 3
vpc_cidr                 = "10.20.0.0/16"
tags = ["project:wp","env:prod","zone:bz","region:sfo3"]
```

## Commands (per zone)
From `terraform/doks/`:
```bash
terraform init -upgrade

# PZ (nyc3)
terraform workspace new prod-pz || terraform workspace select prod-pz
terraform plan  -var-file=../env/prod/pz.tfvars
terraform apply -var-file=../env/prod/pz.tfvars

# Save kubeconfig
terraform output -raw kubeconfig_raw > ../../artifacts/kubeconfig-pz
KUBECONFIG=$PWD/../../artifacts/kubeconfig-pz kubectl get nodes
KUBECONFIG=$PWD/../../artifacts/kubeconfig-pz kubectl cluster-info

# BZ (sfo3)
terraform workspace new prod-bz || terraform workspace select prod-bz
terraform plan  -var-file=../env/prod/bz.tfvars
terraform apply -var-file=../env/prod/bz.tfvars

# Save kubeconfig
terraform output -raw kubeconfig_raw > ../../artifacts/kubeconfig-bz
KUBECONFIG=$PWD/../../artifacts/kubeconfig-bz kubectl get nodes
KUBECONFIG=$PWD/../../artifacts/kubeconfig-bz kubectl cluster-info
```

## Validation Checklist
- `terraform output kubernetes_version` shows the effective version per zone.
- `kubectl get nodes -o wide` shows expected node size and count.
- `doctl kubernetes cluster list` (optional) lists both clusters in the right regions.
- VPCs exist and CIDRs do not overlap.

## Troubleshooting (quick)
- **Asks for `region`/`cluster_name`:** var-file not read or missing keys → double-check path and contents.  
- **VPC delete 409:** cluster (member) not deleted yet → destroy the cluster first, then VPC.  
- **Version mismatch:** set `kubernetes_version` explicitly to a valid slug (e.g., `1.30.6-do.0`).  
- **Provider auth:** ensure `DIGITALOCEAN_TOKEN` in shell or pass `-var do_token=...`.

## Artifacts to Capture
- `artifacts/kubeconfig-pz`, `artifacts/kubeconfig-bz`
- Output values: `cluster_name`, `cluster_id`, `region`, `vpc_id`, `vpc_cidr`, `kubernetes_version`
- Update `docs/stages/02-minimal-infrastructure.md` with observed versions and dates.

## Exit Criteria
- Both clusters reachable with `kubectl`.
- No pending Terraform changes (`terraform plan` returns no diff) for this stage.

## Next Stage (03 — Platform Baseline)
- Install namespaces, cert-manager (DNS-01 with Cloudflare), and observability stack.  
- Still **no** public exposure or LoadBalancer — that comes in Stage 04.
