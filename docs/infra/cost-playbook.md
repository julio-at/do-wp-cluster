# Infra — Cost & Hygiene Playbook (Extended)

**Goal:** Keep the multi‑zone lab affordable while enabling DR drills. This complements `cost-controls.md` with concrete scenarios, checklists, and evidence to track $ impact.

---

## Cost Principles
- **Cold BZ by default:** create BZ only for drills or incidents.
- **Right-size everything:** smallest node sizes that meet SLOs; prefer horizontal over vertical first.
- **Kill zombies:** no dangling LBs, PVs, or clusters.
- **Evidence over guesswork:** log start/stop times and resource counts per drill.

---

## Cost Drivers (DigitalOcean focus)
- **DOKS worker nodes:** per‑node hourly (size × count).
- **Load Balancers:** hourly per LB (Ingress controller).
- **Managed MySQL:** plan/hour + storage.
- **Object Storage (Spaces/R2):** GB and egress.
- **Public egress:** media from bucket/CDN.
- **Persistent Volumes:** (we avoid for WP app; use object storage).

---

## Scenarios & Actions

### 1) Normal steady state (PZ only)
- PZ: DOKS minimal node count, Ingress LB **active**.
- BZ: **destroyed** (no cluster, no DB), or platform installed with LB **off**.
- Actions:
  - Verify no BZ charges: `terraform state list` (bz workspace should be empty).
  - Confirm only one LB exists (PZ).

### 2) DR rehearsal (short window)
- Bring up BZ platform **on demand**.
- Option A: promote replica (costly if kept warm) — prefer **Option B** for lab.
- Option B: restore DB in BZ; create LB only when needed.
- Actions:
  - Record timestamps: BZ `apply` start → DNS flip → failback → teardown.
  - Tear down BZ immediately after success.

### 3) Blue/Green within PZ
- Temporary duplicate Deployment/Service in **PZ** only; same LB.
- Actions:
  - Keep green traffic on separate host; cutover fast; scale down blue.
  - Avoid creating extra LBs.

---

## Hygiene Checklists

### Daily/After Exercises
- [ ] `kubectl get svc -A | grep -i LoadBalancer` → expected count only
- [ ] `doctl kubernetes cluster list` → only desired clusters
- [ ] Managed MySQL: only **PZ writer** running
- [ ] `terraform state list` clean for destroyed workspaces
- [ ] Object storage: lifecycle & versioning policies applied

### Pre‑Teardown (BZ)
- [ ] Traffic is **not** routed to BZ (`wp-active` → `wp-pz`)
- [ ] Scale down app in BZ to 0 (if still up)
- [ ] Delete BZ Ingress LB (if any)
- [ ] `terraform destroy` cluster first, then VPC (avoid 409s)
- [ ] Confirm state is empty

---

## Size & Autoscaling Guidelines
- Start with **2 nodes** × smallest size (e.g., `s-2vcpu-4gb`) in PZ; 0 in BZ.
- Enable cluster autoscaler only after baselining; bounds e.g., min=2 max=5.
- Watch p99 latency/error ratio; scale replicas before node size.

---

## Evidence Template (copy/paste)
```
# Drill Cost Evidence — <YYYY-MM-DD>
Start UTC: <time>
End   UTC: <time>

Resources created:
  - DOKS (BZ): <size> × <count> for <hours>
  - LB (BZ): <count> for <hours>
  - MySQL (BZ): plan=<plan>, hours=<h>
  - Notes: <any extra>

Teardown validations:
  - Clusters remaining: <list>
  - LBs remaining: <list>
  - State workspaces empty: <yes/no>
```

---

## FAQs
- **Why not keep BZ warm with a replica?** Higher steady cost; lab goal is **on‑demand** DR. Use restore‑on‑activation (Option B) and practice it to reduce RTO.
- **How to reduce LB costs further?** Keep BZ without LB; create it only during drills, accepting a few extra minutes in RTO.
- **Can I pause MySQL?** Managed services generally bill while provisioned; destroy when not strictly needed.

---

## Exit Criteria
- Written evidence for last DR drill with resource hours.
- No dangling LBs/clusters after teardown.
- BZ off by default; clear, fast procedure to recreate.
