# App — Overview (WordPress on DOKS)

**Goal:** Capture the application-specific decisions for WordPress running on DOKS with Managed MySQL and object storage, aligned to our staging plan (docs-first → implement → test).

---

## Scope
- **Runtime:** Kubernetes (DOKS), namespace `app`
- **DB:** DigitalOcean Managed MySQL (writer in PZ; replica/restore in BZ)
- **Media:** S3-compatible object storage (DO Spaces or R2)
- **Ingress/TLS:** NGINX Ingress + cert-manager (DNS-01 via Cloudflare)
- **DNS:** `wp-active.guajiro.xyz` → (`wp-pz` | `wp-bz`) CNAME strategy

---

## Non-Goals
- No custom WordPress code/plugins here; only platform-relevant configuration.
- No build pipeline yet (will be added after docs).

---

## Key Decisions
- **Stateless pods:** no persistent volumes for uploads; use object storage.
- **External DB only:** chart internal DB **disabled**.
- **TLS for DB connections:** trust DO CA via mounted secret.
- **Minimal replica count initially:** `replicas=1` (scale later).
- **Config via Secrets/Env:** no config baked into images.

---

## References
- Stage 05 — Minimal Application
- Stage 06 — Backup Zone On-Demand
- Stage 07 — DR Game-Day
- Runbooks: app deploy, DNS flip, promote/restore, failback
