# Platform — Ingress Controller Operations (English)

**Scope:** Operating the NGINX Ingress Controller on DOKS for PZ (nyc3) and BZ (sfo3). Covers deployment, verification, metrics, and safe maintenance.

---

## Objectives
- Expose WordPress through a `LoadBalancer` only when a zone is active.
- Issue TLS automatically with cert-manager (DNS-01/Cloudflare).
- Export metrics for SLOs (p99 latency, error ratio).
- Minimize changes during DR flips (CNAME strategy).

---

## Lifecycle

### Install (docs-first → implement later)
- Official `ingress-nginx` Helm chart in `namespace=platform`.
- Reference values: `docs/snippets/ingress-nginx-values.md`.
- Service `controller.service.type=LoadBalancer` (public exposure).

### Verify
```bash
kubectl -n platform get deploy,svc -l app.kubernetes.io/name=ingress-nginx
kubectl -n platform get svc/ingress-nginx-controller -o wide
kubectl -n platform logs deploy/ingress-nginx-controller --tail=200
```

### Metrics
- Enable `controller.metrics.enabled=true` and `serviceMonitor.enabled=true`.
- Validate in Prometheus (`/targets`) and Grafana dashboards.

### TLS
- Ingress annotation must include: `cert-manager.io/cluster-issuer=le-prod-cloudflare`.
- Certificate `wp-tls` should be `Ready=True` before exposing traffic.

---

## Day-2 Ops
- **Config changes:** use Helm values or the controller `ConfigMap`; avoid editing pods by hand.
- **LB IP rotation:** see `lb-ip-rotation-en.md`. With per-zone CNAMEs (`wp-pz`/`wp-bz`), updates only touch the per-zone record.
- **Scaling:** increase controller `replicaCount` only if saturated or latency rises.
- **Logs:** inspect access/error logs for spikes in 5xx.

---

## Best Practices
- Maintain a **single** Ingress class (`nginx`) for simplicity.
- Do not mix public/private Ingress with the same controller unless separated.
- Tune limits: `proxy-body-size`, keepalive, timeouts per WP/media plugin needs.
- Avoid circular exposure (don’t front Prometheus/Grafana publicly at first).

---

## Common Issues
- **LB Pending:** check provider quotas; recreate Service if needed.
- **5xx errors:** Service/port mismatch or pods not Ready.
- **TLS Pending:** DNS-01 failures; wrong Cloudflare token.

---

## Related Runbooks
- CNAME Flip — `docs/runbooks/dns/flip-active-cname.md`
- DR Game-Day — `docs/runbooks/dr-game-day-playbook.md`
