# Infra — Overview

**Goal:** Terraform-managed, reproducible infra for two independent zones: **PZ (nyc3)** and **BZ (sfo3)**, created/destroyed on demand.

- Modules: DOKS cluster, node pools, VPC, optional DO LB naming.
- Inputs via `*.tfvars`: region, names, tags, autoscaler bounds.
- Workspaces: `prod-pz`, `prod-bz`.
