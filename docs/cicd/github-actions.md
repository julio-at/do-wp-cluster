# CI/CD — GitHub Actions (design)

> If choosing GitHub: this file defines proposed workflows and secrets. Equivalent can be ported to GitLab/Jenkins.

---

## Workflows

### 1) terraform-prod-pz.yml
- Triggers: PR to `main` touching `terraform/` or `env/prod/pz.tfvars`
- Jobs:
  - `validate`: `terraform fmt -check`, `tflint`
  - `plan`: `terraform plan -var-file=env/prod/pz.tfvars` (outputs artifact)
  - `apply`: **manual `workflow_dispatch`**; downloads plan and applies
- Secrets:
  - `DIGITALOCEAN_TOKEN`, backend creds (if not Terraform Cloud)

### 2) terraform-prod-bz.yml
- Same as above but `bz.tfvars` and workspace `prod-bz`

### 3) platform-sync.yml
- Purpose: install/upgrade platform components (cert-manager, monitoring, ingress)
- Steps: `helm upgrade --install ...` (PZ/BZ by input)
- Manual approval for BZ

### 4) app-deploy.yml
- Purpose: deploy/upgrade WP with values files
- Inputs: `env` (pz/bz), image tag (if custom), values file
- Post-checks: curl `wp-active`/`wp-pz`

### 5) dr-flip.yml
- Purpose: **edit Cloudflare CNAME** for `wp-active`
- Input: target (`wp-pz` | `wp-bz`)
- Safety: confirmation prompt + TTL lowering + post-validate

---

## Secrets (GitHub)
- `CLOUDFLARE_API_TOKEN` (Zone:DNS:Edit)
- `DIGITALOCEAN_TOKEN`
- Optional: K8s kubeconfigs as OpenID-issued short-lived tokens or stored as encrypted secrets (avoid long-lived if possible).

---

## Runners
- Use GitHub-hosted first; self-hosted optional for private networking needs.
