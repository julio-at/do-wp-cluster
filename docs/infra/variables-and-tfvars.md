# Infra — Variables & tfvars

**Core variables (examples):**
- `region` (`nyc3` / `sfo3`)
- `cluster_name` (e.g., `wp-pz` / `wp-bz`)
- `node_count`, `node_size`
- `enable_autoscale`, `min_nodes`, `max_nodes`
- `tags` (list of strings)

> Secrets never live in tfvars.
