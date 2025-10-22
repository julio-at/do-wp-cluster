# Infra — Terraform Layout

```text
terraform/
  doks/
    main.tf
    variables.tf
    outputs.tf
  env/
    prod/
      pz.tfvars
      bz.tfvars
artifacts/
  kubeconfig-pz
  kubeconfig-bz
```

- Keep variables **declared once** in `variables.tf`; override via `*.tfvars` only.
- Tag resources consistently (`project=wp`, `env=prod`, `zone=pz|bz`).
