# Observability — Metrics Stack (Prometheus/Grafana/Alertmanager)

> Documentation-first. No public exposure. All services `ClusterIP` until Stage 04+.

---

## Components
- **kube-prometheus-stack** (Helm): Prometheus, Alertmanager, Grafana, exporters, kube-state-metrics, node-exporter.
- **NGINX Ingress metrics**: scrape via ServiceMonitor (enabled later).
- **App metrics**: start with HTTP-based SLOs (Ingress), add app-specific metrics if available.
- **DB metrics**: via provider console/alerts; optional exporters when feasible.

---

## Metrics Inventory (initial)
**Cluster (per zone):**
- Kubelet, kube-state-metrics (pods, deployments ready/unavailable)
- Node CPU/mem/pressure, pod restarts

**Ingress (per zone):**
- Requests: `controller_requests_total` (or chart's equivalent histogram)
- Latency histograms: p50/p90/p99
- 4xx/5xx ratios by host

**App (WordPress):**
- Readiness/Liveness probe success
- (Optional) php-fpm/nginx metrics if image exposes them

**DB:**
- (Option A) Replication `lag_seconds` (external source → metric via push or blackbox recorded value)
- (Option B) Backup `age_seconds` (from API → recording rule placeholder)

**Synthetics:**
- Probe success/latency for `wp-active`, `wp-pz`, `wp-bz` (blackbox exporter or external service)

---

## Recording Rules (examples to implement later)
- `:ingress:http_error_ratio:5m`  
- `:ingress:latency_p99:5m`  
- `:cluster:pod_restart_rate:10m`  
- `dr:replication_lag_seconds` / `dr:backup_age_seconds`

> Keep namespaced by purpose; use labels `zone`, `env`, `service`.

---

## Data Retention (starting point)
- Prometheus: 15 days
- Remote write: none (optional add later)
- Grafana: local sqlite/postgres (chart default ok for lab)

---

## Security
- Internal-only access (port-forward) pre-exposure.
- Read-only viewer role for dashboards (optional).

---

## Acceptance (Stage 03)
- Targets page shows **UP** for kube-state, node-exporter.
- Grafana reachable via port-forward; dashboards render data.
