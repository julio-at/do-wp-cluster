# Stage 07 — Disaster Recovery Game-Day

> **Goal:** Perform a **full DR rehearsal** end-to-end: activate Backup Zone (BZ), serve production traffic via `wp-active.guajiro.xyz`, and then **fail back** to Primary Zone (PZ). Measure **RTO/RPO**, identify gaps, and update runbooks.
>
> **Important:** This stage describes both DB strategies:
> - **Option A — Replica:** Promote BZ read-replica to writer.
> - **Option B — Restore:** Create a new writer in BZ from backup / PITR.
>
> No *new* manifests are introduced here; we execute the runbooks defined in earlier stages.

---

## Roles & Responsibilities (suggested)
- **Incident Commander (IC):** timekeeping, decisions (go/no-go), comms.
- **DB Lead:** promotion/restore, data validation, replication/failback.
- **Kubernetes Lead:** scaling app, Ingress/TLS, health checks.
- **DNS/Edge Lead:** Cloudflare records and verification.
- **Observer/Scribe:** capture timestamps, metrics, screenshots, and issues.

---

## Preconditions
- PZ up (live), BZ created per Stage 06 (cold/warm).
- Cloudflare DNS configured: `wp-active.guajiro.xyz` (logical CNAME), `wp-pz.guajiro.xyz`, `wp-bz.guajiro.xyz`.
- cert-manager Issuers ready in **both** zones; Ingress controller present in PZ, and prepared in BZ (can be installed during DR activation if cold).
- Clear decision on DB strategy: **Replica (A)** or **Restore (B)**.
- Observability active: dashboards for golden signals, DB health, synthetic checks.
- Communication channel open (bridge/chat) and change window approved.

---

## Metrics to Capture
- **RTO:** time from DR declaration → `200 OK` on `https://wp-active.guajiro.xyz` served by **BZ**.
- **RPO:** time difference between last consistent data point before incident and state after DR switch (or measured replication lag at promotion).
- **DNS Convergence:** time from flip of `wp-active` → majority of clients hitting BZ.
- **Service SLOs:** error rate, p90/p99 latency, 5xx at Ingress, DB errors.

> Use a shared timeline doc/spreadsheet. Record absolute timestamps (UTC) for each step.

---

## Runbook A — DB **Replica** in BZ (promotion flow)

### A1) Declare incident & freeze writes (optional)
- IC confirms incident and DR activation.
- If application allows, consider **temporary write freeze** (maintenance mode) to minimize race conditions during promotion (optional).

### A2) Promote BZ database
- DB Lead promotes the **read-replica** in BZ to **writer**.
- Validate:
  - New **writer endpoint** reachable over TLS.
  - Admin/replication status clean; note the **last known lag** (for RPO).

### A3) Activate application in BZ
- K8s Lead:
  - Scale WordPress **up** (if cold) to the agreed replica count.
  - Ensure **DB secrets** point to the **BZ writer** (update if necessary) and restart pods.
  - Ensure Ingress Controller exists and a public Service:LoadBalancer is created (if not present).

### A4) TLS for BZ
- If BZ did not yet have a cert for `wp-bz.guajiro.xyz`, request it via cert-manager (DNS-01). Wait for `Ready=True`.
- (Optional) Also ensure a certificate is ready to serve `wp-active.guajiro.xyz` from BZ (after the DNS flip).

### A5) Flip DNS
- DNS Lead updates **only** the CNAME target of `wp-active.guajiro.xyz` → `wp-bz.guajiro.xyz`.
- Temporarily reduce TTL to **30–60s** during the change window.

### A6) Validation
- Synthetic: `curl -I https://wp-active.guajiro.xyz` returns **200/301**; cert valid.
- Business tests: login to wp-admin, create a post, upload media.
- Observability: error rate low, latency within bounds, DB errors absent.

### A7) Communicate “DR active”
- IC announces DR activation time, observed RTO/RPO, and any degraded modes.

---

## Runbook B — DB **Restore** in BZ (activation flow)

### B1) Declare incident & freeze source
- IC confirms DR activation. Freeze writes in PZ if possible to produce a clean backup/pivot.

### B2) Restore DB to BZ
- DB Lead triggers **restore** (latest full backup or PITR) into BZ.
- Validate:
  - BZ writer is reachable over TLS; schema and credentials correct.
  - Record **backup timestamp** (for RPO).

### B3) Activate application in BZ
- K8s Lead:
  - Deploy or scale WordPress (replicas=1 initial, then scale up).
  - Point secrets/env to **BZ writer**; restart pods.
  - Ensure Ingress Controller and public Service:LoadBalancer exist.

### B4) TLS for BZ
- Obtain certificates for `wp-bz.guajiro.xyz` (and plan for `wp-active.guajiro.xyz` post-flip).

### B5) Flip DNS
- Update `wp-active.guajiro.xyz` CNAME → `wp-bz.guajiro.xyz`. Reduce TTL as above.

### B6) Validation & Comms
- Same as A6/A7: synthetic + business tests + SLOs. Announce DR active.

---

## Failback to PZ (common to A and B)

### F1) Re-seed PZ
- After PZ is healthy again:
  - **If A (Replica):** create a **new replica** in PZ sourced from **BZ writer**, then promote PZ when caught up.
  - **If B (Restore):** restore most recent data to PZ from backups or set up replication from BZ → PZ and wait until caught up.

### F2) Prepare application in PZ
- Point PZ app to the restored/promoted **PZ writer** (secrets).
- Ensure PZ Ingress/TLS are healthy.

### F3) Flip DNS back
- Change `wp-active.guajiro.xyz` CNAME → `wp-pz.guajiro.xyz`. Keep low TTL during change window.

### F4) Validation
- Repeat synthetic + business tests on PZ.
- Observe SLOs for a stability window (e.g., 30–60 min).

### F5) Stand down BZ
- Scale down app (or destroy BZ if DR on-demand), return TTLs to normal.

---

## Safety Checks & Tips
- **Do not modify per-zone records** (`wp-pz`, `wp-bz`) during a flip; change **only** the `wp-active` CNAME target.
- Keep **cert-manager** DNS-01 working in both zones; test a dummy certificate before Game-Day.
- Ensure **object storage** (media) is accessible from both zones; if you need replication, plan it beforehand.
- Avoid changing Terraform state mid-incident. Use existing workspaces and var-files.
- Record each step’s timestamp; if a step exceeds a time budget, IC calls go/no-go.

---

## Troubleshooting
- **Clients still hit old zone:** caches/TTL; check recursive resolvers and CDN caching. Consider purges.
- **TLS fails post-flip:** confirm Ingress is serving `wp-active.guajiro.xyz` and cert exists/valid.
- **DB auth errors:** wrong secret/username/host; verify CA bundle and “trusted sources” (VPC CIDR).
- **High error rate after flip:** scale app, check node pressure, inspect NGINX/Pods logs.

---

## Postmortem Template (fill right after)
- **Date/Time (UTC):**  
- **Scope:** (what was included/excluded)  
- **RTO observed:**  
- **RPO observed:** (replication lag or backup timestamp delta)  
- **Steps timeline:** (timestamped)  
- **Issues found:** (root causes, contributing factors)  
- **Fixes & improvements:** (runbook, automation, alerts)  
- **Action items:** owner + due date

---

## Exit Criteria
- Successful DR activation to BZ and failback to PZ with measured **RTO/RPO**.
- All steps documented with timestamps; dashboards/alerts verified.
- Runbooks and docs updated with lessons learned.

---

## Next (Beyond Stage 07)
- Automate manual steps: ExternalDNS, scripted DB promotion/restore, and Infra-as-Code hooks.
- Move to **Blue/Green** promotions within a zone (Argo CD or CI) and **edge-weighted** flips across zones.
