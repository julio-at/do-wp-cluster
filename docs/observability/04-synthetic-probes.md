# Observability — Synthetic Probes

> External checks validate what real users see, independent of cluster health. We keep it simple first; expand later.

---

## Targets
- `https://wp-active.guajiro.xyz` — primary SLO endpoint
- `https://wp-pz.guajiro.xyz` — zone-specific
- `https://wp-bz.guajiro.xyz` — zone-specific (when exposed)

---

## Signals
- HTTP status (expect 200/301)
- TLS validity
- TTFB / total latency
- DNS resolution time (for flip monitoring)

---

## Implementation Options
- **Blackbox exporter** (ICMP/HTTP/TLS modules) + Prometheus.  
- **External managed**: Cloudflare Health Checks, UptimeRobot, etc.

---

## Alerting
- Page on consecutive probe failures for `wp-active` (e.g., 3/5 failures).
- Notify (non-paging) on per-zone probe issues when zone is idle.

---

## Acceptance
- Probes visible in Prometheus (if blackbox) or provider dashboard.
- Alert fires on forced outage in lab tests.
