# App — Operational Checklists

> Quick lists to run before and after changes.

---

## Pre-deploy
- [ ] Secrets present (`wp-db`, `wp-s3`) and current
- [ ] ClusterIssuer `le-prod-cloudflare` ready
- [ ] Ingress controller LB healthy
- [ ] DNS `wp-active` → `wp-pz` (expected for PZ tests)
- [ ] Observability dashboards loading

## Post-deploy
- [ ] `kubectl -n app get deploy,po,svc,ing` healthy
- [ ] `kubectl -n app describe certificate wp-tls` → `Ready=True`
- [ ] `curl -I https://wp-active.guajiro.xyz` OK
- [ ] Media upload test succeeds
- [ ] Error rate and p99 latency acceptable

## Pre-DR flip
- [ ] Target zone app ready (pods, ingress, TLS)
- [ ] DB strategy executed (promoted/restored)
- [ ] TTL lowered per `docs/dns/ttl-policy.md`

## Post-DR flip
- [ ] `dig +short wp-active.guajiro.xyz` shows new CNAME target
- [ ] Synthetic checks passing
- [ ] Business flows (login/post/upload) OK
