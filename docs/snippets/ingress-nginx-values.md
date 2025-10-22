# Snippet — Ingress-NGINX Values (reference)

**Purpose:** Suggested Helm values for the ingress controller in this lab. Keep services **ClusterIP** unless you intend to expose; in our plan we do expose via `LoadBalancer` when ready.

```yaml
controller:
  replicaCount: 1
  service:
    type: LoadBalancer
    annotations: {}
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
  config:
    use-forwarded-headers: "true"
    enable-brotli: "true"
    proxy-body-size: 32m
  admissionWebhooks:
    enabled: true
defaultBackend:
  enabled: true
```

**Notes**
- `service.type=LoadBalancer` will allocate a public LB; ensure you want exposure (Stage 04).
- Metrics enablement allows Prometheus to scrape via ServiceMonitor (kube-prometheus-stack).

**Verification**
- `kubectl -n platform get svc -l app.kubernetes.io/name=ingress-nginx`
- `kubectl -n platform get endpoints -l app.kubernetes.io/name=ingress-nginx`
