# App — WordPress Configuration

> Documentation-first for settings we will apply through Helm/manifests and post-install UI steps.

---

## Kubernetes Resources
- **Deployment** `wp`
  - `replicas=1` (PZ), `0/1` (BZ)
  - Readiness/liveness probes
  - Resource requests: CPU 100m, Memory 256Mi (adjust later)
- **Service** `ClusterIP` (port 80)
- **Ingress** (class `nginx`) with TLS `wp-tls` and issuer `le-prod-cloudflare`
- **Secrets**
  - `wp-db`: DB host/user/password + `DB_CA_CERT` file
  - `wp-s3`: S3 endpoint/bucket/region/key/secret
- **ConfigMap** (optional): extra PHP/NGINX tuning if chart supports

---

## WordPress Settings (UI)
- **Site URL / Home:** `https://wp-active.guajiro.xyz`
- **Media Offload Plugin:** configure to use env vars (endpoint, bucket, creds)
- **Permalinks:** post-name (or as required)
- **Uploads:** ensure plugin intercepts to object storage; no local writes
- **Time zone/locale:** match audience (optional)

---

## Security & Hardening
- **Admin user:** strong, unique password; consider 2FA plugin
- **Limit login attempts / WAF rules** (if Cloudflare proxy later)
- **Disable file editing from WP admin** (define `DISALLOW_FILE_EDIT` if chart supports env injection)
- **PHP limits:** set upload max size, memory limit via env/config

---

## Observability Hooks
- Expose readiness endpoint (e.g., `/wp-login.php` or custom `/healthz` script)
- Consider NGINX access log sampling for latency/error insights
- Add dashboard panels for WordPress namespace and Ingress host

---

## Acceptance
- Fresh install completes over HTTPS
- Media uploads land in object storage and serve correctly
- Readiness/Ingress SLOs visible in Grafana
