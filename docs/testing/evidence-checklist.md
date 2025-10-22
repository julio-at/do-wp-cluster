# Evidence Checklist

Use this list to collect artifacts for audits and learning.

- [ ] Timeline with **UTC** timestamps (declaration, promotion/restore start/end, flip, validation, failback)
- [ ] Screenshots of Grafana (before/after flip)
- [ ] Prometheus snapshots or query exports (error ratio, p99 latency)
- [ ] `dig +short wp-active.guajiro.xyz` outputs during flip
- [ ] `curl -I` headers from both zones
- [ ] DB evidence: replication lag or backup timestamp
- [ ] Command logs (kubectl/helm/terraform/dns edits) stripped of secrets
- [ ] Postmortem summary with RTO/RPO
