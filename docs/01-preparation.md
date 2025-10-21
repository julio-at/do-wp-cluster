# Stage 01 — Preparation

## Purpose
Establish shared conventions and a lightweight working model so Primary Zone (PZ) and Backup Zone (BZ) can be created/destroyed independently and reproducibly.

## Scope
- New repo: `do-wp-cluster`
- Terraform for DOKS only (VPC + cluster). No LB, no platform, no app yet.
- Two zones (PZ/BZ) managed via **workspaces** and **tfvars**.

## Preconditions
- DigitalOcean account with API token (write permissions).
- Local tooling: `terraform ≥ 1.6`, `kubectl`, `doctl` (optional), Git.
- You can authenticate with DO via `DIGITALOCEAN_TOKEN` or `-var do_token=...`.

## Repository Layout (baseline)
```
do-wp-cluster/
├─ terraform/
│  ├─ doks/                   # DOKS infra (VPC + cluster)
│  └─ env/
│     ├─ prod/
│     │  ├─ pz.tfvars         # PZ config (nyc3)
│     │  └─ bz.tfvars         # BZ config (sfo3)
│     └─ examples/
│        ├─ pz.tfvars.example
│        └─ bz.tfvars.example
├─ k8s/
│  ├─ platform/               # (later) ingress, cert-manager, observability
│  └─ app/                    # (later) wordpress
└─ docs/…                     # stages, runbooks, observability, dns, security
```

## Naming & Tagging Conventions
- Cluster names:  
  - PZ: `wp-pz-doks-<region>` → e.g., `wp-pz-doks-nyc3`  
  - BZ: `wp-bz-doks-<region>` → e.g., `wp-bz-doks-sfo3`
- Tags (flat list of strings):  
  `["project:wp","env:prod","zone:pz|bz","region:<region>"]`

## Workspaces (state isolation)
- `prod-pz` → state for PZ
- `prod-bz` → state for BZ  
This lets us create/destroy each zone without touching the other.

## Variables (minimum)
- Required: `region`, `cluster_name`
- Recommended defaults present for: `kubernetes_minor_prefix`, `node_size`, `node_count`, `vpc_cidr`, `tags`
- Optional: `kubernetes_version` (empty → pick latest matching `kubernetes_minor_prefix`)
- Autoscaling (enabled later): `enable_autoscale`, `min_nodes`, `max_nodes`

## State Backend (decision)
- Local ok for lab; prefer a **remote backend with locking** for team use (e.g., Terraform Cloud, S3+DynDB equivalent). Document backend in `docs/security/state-backend.md`.

## Security Notes
- Never commit tokens or kubeconfigs.  
- Add `/artifacts/*` to `.gitignore`; store ephemeral outputs there.
- Use **VPC CIDR** (not per-node IPs) for “trusted sources” when we later configure DO Managed MySQL.

## Risks & Mitigations
- **Undeclared variables / type mismatches:** use the example tfvars as contract.  
- **Accidental VPC destroy with members:** destroy the cluster first or set `prevent_destroy` guardrails if needed.  
- **Region/CIDR overlap:** ensure unique CIDRs per zone.

## Deliverables
- `terraform/env/prod/pz.tfvars` and `bz.tfvars` filled.
- Workspaces created: `prod-pz`, `prod-bz`.
- This document committed.
