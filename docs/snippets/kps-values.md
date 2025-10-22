# Snippet — kube-prometheus-stack Values (reference)

**Purpose:** Minimal values for an internal-only monitoring stack.

```yaml
grafana:
  service:
    type: ClusterIP
  defaultDashboardsEnabled: true

prometheus:
  prometheusSpec:
    retention: 15d
    resources:
      requests:
        cpu: 200m
        memory: 1Gi

alertmanager:
  service:
    type: ClusterIP

kubeStateMetrics:
  enabled: true
nodeExporter:
  enabled: true
```

**Labels/Relabeling**
- Add `externalLabels` like `zone: pz|bz`, `env: prod` if desired:
```yaml
prometheus:
  prometheusSpec:
    externalLabels:
      project: wp
      env: prod
      zone: pz
```

**Access (pre-exposure)**
- `kubectl -n platform port-forward svc/monitoring-grafana 3000:80`
- `kubectl -n platform port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090`
