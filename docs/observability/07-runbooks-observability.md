# Observability — Runbooks

Linking to operational procedures related to signals and alerts.

- Flip CNAME: `docs/runbooks/dns/flip-active-cname.md`
- Promote replica: `docs/runbooks/db/promote-replica-to-writer.md`
- Restore writer: `docs/runbooks/db/restore-writer-in-bz.md`
- Failback to PZ: `docs/runbooks/platform/failback-to-primary-zone.md`

---

## Common Checks
- `kubectl -n platform get pods`
- `kubectl -n platform port-forward svc/monitoring-grafana 3000:80`
- `kubectl -n platform port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090`

## After any alert
- Confirm impact from Grafana (availability, error rate, latency).
- Check recent deploys/changes.
- If PZ down and BZ green → consider DR runbooks.
