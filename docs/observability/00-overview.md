# Observability — Overview

**Goal:** Provide actionable visibility for the WordPress platform across zones (PZ nyc3, BZ sfo3) to support reliability targets and Disaster Recovery (DR) workflows.

We follow the sequence: **documentation → implementation → tests**. This folder captures the *why/what* and concrete acceptance criteria before deploying anything.

---

## Scope (Stage alignment)
- Stage 03: Metrics baseline (kube-prometheus-stack), internal-only.
- Stage 04: Still internal-only; validate controller metrics.
- Stage 05: App signals (WP liveness/readiness, HTTP SLOs).
- Stage 06: BZ parity (same stack), replication-lag monitoring (if replica).
- Stage 07: DR Game-Day metrics, timelines, evidence gathering.

---

## Pillars
- **Metrics** (Prometheus): cluster, ingress, app, DB, synthetic.
- **Dashboards** (Grafana): Golden Signals + DR view.
- **Alerting** (Alertmanager): tiered severities, paging flow.
- **Synthetics**: external probes to `wp-active`, `wp-pz`, `wp-bz`.
- **(Optional) Logs/Tracing**: lightweight logging and OTel if needed later.

---

## Golden Signals (per zone)
- **Availability**: HTTP 2xx ratio (ingress), readiness status.
- **Latency**: p50/p90/p99 for `/` and `/wp-admin`.
- **Traffic**: requests/s by host/path.
- **Errors**: 4xx/5xx rate, backend failures, TLS/ACME errors.
- **Resource**: CPU, memory, filesystem, pod restarts.

---

## Service-Level Objectives (initial)
- **Availability** (30d): 99.5% on `wp-active.guajiro.xyz`.
- **Latency** (p99, steady state): < 2.0s homepage, < 3.0s admin.
- **Error Budget**: 0.5% unavailability.
- **Alerting policy**: alert on burn rates (e.g., 14.4x / 6x) and on fast p99 regressions.

> Final SLOs may evolve after baseline traffic observations.

---

## DR Observability
- **Cutover readiness** (BZ): green status for app pods, ingress, TLS, and DB status.
- **DNS flip**: measure propagation and success via synthetics.
- **DB strategy**: replication **lag** (Option A) vs. backup **age** (Option B).
- **Timeline capture**: timestamps for RTO/RPO calculations.

---

## Deliverables (docs-first)
- Metric inventory (what/where).
- Alert catalog with thresholds and owners.
- Dashboard list and wireframes.
- Synthetic checks matrix.
- Test plans for Stage 03/04/05/07.
