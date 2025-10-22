# Runbook — DR Game-Day Playbook (Minute-by-minute)

**Purpose:** A timeboxed script to execute Stage 07: promote/restore, flip DNS, validate, and fail back. Use alongside detailed runbooks for each step.

---

## Roles
- **IC (Incident Commander):** owns timeline & decisions
- **DB Lead:** DB promotion/restore/failback
- **Kubernetes Lead:** scaling app, Ingress/TLS
- **DNS/Edge Lead:** Cloudflare changes/validation
- **Scribe:** timestamps, metrics, screenshots, issues

---

## Timeline (example — adjust to your org)

**T-30 min: Prep**
- IC opens bridge, reviews scope, assigns roles, sets success criteria and timebox.
- Reduce TTL of `wp-active.guajiro.xyz` to 60s.
- Verify BZ platform health (pods, issuers, monitoring).

**T-10 min: Readiness checks**
- DB: replica healthy & lag noted (Option A) OR backup timestamp verified (Option B).
- K8s: Ingress controller ready in BZ; no pending LB issues.
- DNS: confirm current `wp-active` → `wp-pz`.

**T0: DR Activation — Choose A or B**

**A) Replica path**
1. Promote BZ replica to writer. Record promotion time & last lag.
2. Update app secrets to BZ writer if endpoint changed; restart pods.
3. Ensure TLS ready for `wp-bz.guajiro.xyz`.

**B) Restore path**
1. Restore backup/PITR to BZ writer. Record backup timestamp & restore end.
2. Wire app secrets to BZ writer; deploy/scale app.
3. Ensure TLS for `wp-bz.guajiro.xyz`.

**T+? min: DNS Flip**
- Change `wp-active.guajiro.xyz` CNAME → `wp-bz.guajiro.xyz`.
- Validate with `dig +short` and `curl -I https://wp-active.guajiro.xyz`.

**T+10 min: Business validation**
- Login wp-admin, create post, upload media.
- Observe error rate & p90/p99 latency.

**T+30–60 min: Stabilization window**
- Monitor dashboards; address any regressions.
- IC confirms DR state as stable; capture provisional RTO/RPO.

**Failback window (later)**
- Re-seed/restore PZ, validate.
- Flip `wp-active` back to `wp-pz` and validate again.

---

## Metrics to capture
- **RTO:** time from DR declaration to 200 OK on `wp-active` served by BZ.
- **RPO:** replication lag at promotion (A) or backup age delta (B).
- **DNS convergence:** time to majority client cutover.
- **SLOs:** error rate, p90/p99 latency, 5xx, DB errors.

---

## Checklists

**Go/No-Go preconditions**
- [ ] BZ writer ready (A: promoted / B: restored)
- [ ] App scaled/running in BZ
- [ ] TLS valid for `wp-bz.guajiro.xyz`
- [ ] Monitoring green / known risks accepted
- [ ] Comms ready; rollback plan known

**Post-flip**
- [ ] `dig` shows new CNAME target
- [ ] `curl -I https://wp-active.guajiro.xyz` OK
- [ ] Admin login & media upload OK
- [ ] Error rate within thresholds

**Failback**
- [ ] PZ writer ready
- [ ] App secrets updated to PZ
- [ ] TLS valid in PZ
- [ ] DNS flipped back and validated

---

## Artifacts
- Timeline with timestamps (UTC)
- Screenshots of dashboards before/after
- Command logs for DNS, K8s, and DB actions
- RTO/RPO calculations

---

## Exit Criteria
- Successful DR activation and failback with measured RTO/RPO.
- Issues documented with owners and due dates.
