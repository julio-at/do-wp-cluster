# Observability — Grafana Dashboards

> Goal: One **Operations** dashboard per zone + one **DR Overview** dashboard. Keep them lightweight and decision-oriented.

---

## Dashboards

### 1) **Ops — Zone (PZ/BZ)**
Panels:
- **Status row**: Prometheus up, cert-manager webhooks up, kube-state collector up
- **App health**: WP pods ready, restarts (rate), liveness/readiness
- **Ingress**: req/s, 4xx/5xx %, p50/p90/p99 latency by host
- **Nodes**: CPU, memory, pressure, disk
- **K8s objects**: Deployments unavailable replicas, HPA status (when enabled)

Variables: `zone`, `namespace`, `host`.

### 2) **DR Overview**
Panels:
- **`wp-active` availability & latency** (stacked by target zone if possible)
- **DNS flip tracker**: annotation stream (manual add at flip time)
- **DB**: replication lag (A) or backup age (B)
- **Synthetics**: probe success and latency for `wp-active`, `wp-pz`, `wp-bz`
- **Error budget**: remaining budget over period

---

## Annotations & Labels
- Mark DR declaration time, flip start, flip end, failback.
- Label metrics with `zone`, `env`, `service`, `host` for filtering.

---

## Acceptance
- Dashboards load with data via port-forward.
- Filters work; panels not broken when a zone is off (BZ cold).

