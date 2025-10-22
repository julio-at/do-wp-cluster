# Infra — DOKS Module Notes

- Use a single `digitalocean_kubernetes_cluster` with one primary node pool; add worker pools if needed.
- Set `auto_upgrade` as desired.
- If autoscaler is enabled, set sensible `min/max_nodes` (e.g., 2–5 for lab).

**Outputs:**
- `kubeconfig_raw` → write to `artifacts/kubeconfig-<zone>`
