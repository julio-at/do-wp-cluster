# Infra — Environments & Workspaces

- Workspace names: `prod-pz`, `prod-bz`.
- Commands:
  ```bash
  terraform workspace new prod-pz || terraform workspace select prod-pz
  terraform plan -var-file=../env/prod/pz.tfvars
  terraform apply -var-file=../env/prod/pz.tfvars
  ```
