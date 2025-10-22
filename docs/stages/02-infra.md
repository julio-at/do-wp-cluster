# Stage 02 — Infrastructure

## 02.B — DigitalOcean Managed MySQL (Addendum)

**Goal:** create DO Managed MySQL for PZ (`nyc3`), keep BZ (`sfo3`) cold.  
**Initial firewall:** optional; you may start **OFF** (TLS + strong credentials) and harden later.

- **One‑apply (same stack):** pass the cluster’s `id` directly to the DB module (`trusted_sources.cluster_ids`); Terraform handles ordering. Optionally add a short `time_sleep` before DB firewall creation if the DO API is eventually consistent.
- **Alternatives:** `terraform_remote_state` (separate stacks) or resolving the cluster by name via `data.digitalocean_kubernetes_cluster`.

> Full guide: [`../db/managed-mysql-do.md`](../db/managed-mysql-do.md)
