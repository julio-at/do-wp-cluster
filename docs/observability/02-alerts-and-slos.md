# Observability — Alerts & SLOs

> Alerts should be **actionable**, map to owners, and reference runbooks. Start lean; iterate after first test runs.

---

## Alert Philosophy
- **Tiered severities**: page on customer-impacting symptoms; notify (non-paging) for early signals.
- **Multi-signal**: combine error ratio + latency + saturation to reduce noise.
- **DR-aware**: distinct policies for PZ vs BZ activation.

---

## Initial Alert Catalog

### Paging (SEV-1/SEV-2)
1. **`wp-active` Availability breach**  
   - Condition: error ratio > 5% for 5m **or** p99 latency > 4s for 5m  
   - Source: Ingress metrics on host = `wp-active.guajiro.xyz`  
   - Action: Follow `docs/runbooks/dns/flip-active-cname.md` if PZ down.
2. **DB Critical**  
   - Option A: replication `lag_seconds` > 60s for 5m (if replica exists).  
   - Option B: backup `age_seconds` exceeds policy (e.g., 24h).  
   - Action: DB runbook (promote/restore).

### Non-Paging (SEV-3)
3. **Ingress 5xx warning**: 5xx > 1% for 5m on `wp-*` hosts.
4. **Node Pressure**: memory/CPU pressure > 5m; watch autoscaler events.
5. **Pod CrashLoop**: restart rate > threshold in `app` namespace.

---

## Alertmanager Routing (conceptual)
- Route by `severity` and `zone` labels.  
- Page PZ channel when `zone=pz` and `severity=critical`.  
- BZ alerts non-paging until DR activation (then switch/pager enable).

---

## SLOs (draft)
- Availability 30d: 99.5%
- Error budget: 0.5%
- Latency p99 targets: homepage 2s, admin 3s

**Burn-rate alerts** (examples; to implement as recording rules):
- Fast: 14.4x over 5m/1h
- Slow: 6x over 30m/6h

---

## Runbook Links
- Flip DNS: `docs/runbooks/dns/flip-active-cname.md`
- Promote replica: `docs/runbooks/db/promote-replica-to-writer.md`
- Restore writer: `docs/runbooks/db/restore-writer-in-bz.md`
- Failback: `docs/runbooks/platform/failback-to-primary-zone.md`
