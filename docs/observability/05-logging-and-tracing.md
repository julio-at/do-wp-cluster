# Observability — Logging & Tracing (Optional)

> For the lab, we keep logs minimal and defer tracing unless needed. This document sets expectations if/when we add them.

---

## Logging
- Container stdout/err collected by Kubernetes (kubectl logs).
- (Optional) Lightweight aggregator: Loki + Promtail.
- Retention: small (e.g., 3–7 days) to control cost.
- Access: internal-only; no public endpoints.

## Tracing
- If we add APM/Tracing: OpenTelemetry Collector (Alloy/otelcol) exporting to a vendor or Jaeger/Tempo.
- Start with ingress and app HTTP spans only.

## Security
- Avoid PII in logs; mask secrets in Env/args.
- RBAC read-only for viewers.

## Acceptance
- Can retrieve app errors during tests; tracing optional.
