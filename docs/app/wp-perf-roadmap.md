
# WordPress at Scale — Roadmap (Hybrid RWX `wp-content/` → Immutable Core)

## Goal
Support **thousands of visitors** reliably while allowing admins to **install/update plugins via the WP Admin**. Start with a **Hybrid** model (RWX only for `wp-content/`) and evolve toward **Immutable core** (plugins baked via CI) without downtime.

---

## Placement in repo
**Put this file at:** `docs/app/wp-perf-roadmap.md`

---

## Target Architecture (high level)
- **App pods (2+ replicas)** behind Ingress.
- **RWX storage ONLY for** `wp-content/` (plugins, themes; uploads should be S3/R2).
- **Object storage (Spaces/R2/S3)** for **uploads** (offload media).
- **CDN + Edge caching** in front of Ingress.
- **Redis** as **Persistent Object Cache**.
- **Managed MySQL (DO)** with TLS; firewall can be added later (VPC CIDR → k8s UUID).
- **OPcache** on PHP-FPM; tune validation per update model.
- **Observability** via kube-prometheus-stack (SLOs, error budget), logs, and synthetics.

> Why not full docroot on RWX? Performance and security: serving core PHP over NFS becomes a bottleneck; this roadmap avoids that.

---

## Phased Plan

### Phase 0 — Prerequisites
- Confirm **Managed MySQL** deployed (PZ) with outputs stored in vault.
- Create **object storage bucket** (Spaces/R2) and creds.
- Decide **domain/hostnames** in `tfvars` (already centralized).
- Ensure **Ingress** and **cert-manager** plan for Stage 03 aligns with hostnames.

**Success:** DB reachable with TLS; bucket + keys ready; domain values set.

---

### Phase 1 — Hybrid storage for `wp-content/` (RWX)
- Provision an **RWX StorageClass** (e.g., **NFS provisioner** backed by DO Volumes).
- Create a **PVC (RWX)** for `wp-content/`.
- Mount the PVC at:
  - `/var/www/html/wp-content/plugins`
  - `/var/www/html/wp-content/themes`
  - *(uploads will be offloaded to S3/R2; do not store large media here)*
- Add **initContainer** to `chown` the mount (`www-data:www-data`) and set proper perms.
- In `wp-config.php`:
  - `define('DISALLOW_FILE_EDIT', true);` (disable inline editor)
  - `define('WP_AUTO_UPDATE_CORE', false);` (no core auto updates)
  - Optionally `define('FS_METHOD', 'direct');` if needed for NFS writes.

**Success:** Admin can install/update plugins; changes persist and appear on all pods.

---

### Phase 2 — Media Offload + CDN
- Install/configure **Offload Media** to Spaces/R2; set bucket, region, endpoint, and ACLs.
- Ensure media URLs are rewritten to object storage; enable **delete from local**.
- Put a **CDN** in front (Cloudflare/CloudFront/Fastly). Cache static assets aggressively; cache HTML for anonymous users (respect cookies).

**Success:** Media no longer on pods; CDN hit rate high; origin load drops.

---

### Phase 3 — Caching & Runtime Tuning
- **Page cache**: choose one path
  - NGINX FastCGI cache at ingress **or**
  - A proven page-cache plugin (cache to memory/disk shared across pods if needed).
- **Redis** as **Persistent Object Cache**; enable the official plugin.
- **PHP-FPM/OPcache** tuning:
  - OPcache enabled; `opcache.memory_consumption` sized per image.
  - In Hybrid, keep `opcache.validate_timestamps=1` with a modest `opcache.revalidate_freq`.
  - After plugin upgrades, perform a **rolling restart** to refresh OPcache across pods.
- **DB**: tighten connection pool settings; keep TLS `VERIFY_CA`.

**Success:** P95 latency improves; DB queries/page drop; cache hit rates high.

---

### Phase 4 — Observability, SLOs & Load Tests
- kube-prometheus-stack: record **SLOs** for availability & latency; alert on error budget burn.
- Traces/logs: capture PHP/NGINX errors and slow queries.
- **Load test** with realistic traffic (read-heavy then mixed). Validate HPA triggers on CPU/RPS/latency.

**Success:** SLOs green under target load; autoscaling behaves; no NFS saturation.

---

### Phase 5 — Hardening
- Move admin access behind **WAF**/IP allow-lists if possible.
- Add **DB firewall** rule: start with **VPC CIDR**, later switch to **k8s UUID**.
- Regular **backups** of RWX volume (`wp-content/`) + database; test restore.
- Review secrets management (rotation schedule).

**Success:** Reduced attack surface; restore drills pass.

---

### Phase 6 — Evolve to Immutable Core (Optional, when ready)
- Introduce **staging** where admins can update plugins.
- Export locked plugin set (Composer/WPackagist or artifact).
- **CI builds** a new **immutable** image for production (core + plugins baked in).
- In prod, set `opcache.validate_timestamps=0` for max performance.

**Success:** Prod becomes fully immutable (best performance) while keeping admin UX in staging.

---

## Rollback Strategy
- **Plugins/themes**: keep a nightly snapshot of the RWX volume; rollback by restore.
- **App**: roll back Deployment to previous image tag.
- **CDN**: purge if stale pages appear after rollback.
- **DB**: PITR/snapshot restore if needed.

---

## Acceptance Criteria (go/no-go)
- Admin UI plugin updates work and persist across pods (Phase 1).
- Static assets served via CDN; media offloaded (Phase 2).
- Redis object cache active; page cache in place; P95 and P99 within targets (Phase 3).
- SLO dashboards and alerts configured; load tests pass without NFS bottlenecks (Phase 4).
- Backup/restore playbooks validated (Phase 5).
