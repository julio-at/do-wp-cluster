# DNS — CNAME Strategy (guajiro.xyz)

**Objective:** Route end-user traffic through a **stable logical name** and flip between zones without touching per‑zone records or caring about changing LoadBalancer IPs.

---

## Naming Model

```
wp-active.guajiro.xyz   (logical, stable)  ← CNAME →   wp-pz.guajiro.xyz  (normal)
                                                 or →   wp-bz.guajiro.xyz  (DR)

wp-pz.guajiro.xyz  →  A/AAAA to PZ Ingress LB (or CNAME to cloud LB hostname)
wp-bz.guajiro.xyz  →  A/AAAA to BZ Ingress LB (or CNAME to cloud LB hostname)
```

- **Flip = change only the CNAME target of `wp-active.guajiro.xyz`**
- Per‑zone records (`wp-pz`, `wp-bz`) are **owned by the cluster/runtime** (manually at first; later via ExternalDNS).

> We avoid apex (`guajiro.xyz`) to keep CNAME chaining simple. If apex is ever required, use **CNAME flattening** at the DNS provider and follow a stricter change process.

---

## Record Types & Ownership

| Record | Type | Target | Owner | Notes |
|---|---|---|---|---|
| `wp-active.guajiro.xyz` | CNAME | `wp-pz.guajiro.xyz` (normal) or `wp-bz.guajiro.xyz` (DR) | **DNS** (manual/Terraform) | Only this changes during flips |
| `wp-pz.guajiro.xyz` | A/AAAA or CNAME | PZ ingress LB IP/hostname | **Platform** (manual → ExternalDNS later) | Created when PZ exposes ingress |
| `wp-bz.guajiro.xyz` | A/AAAA or CNAME | BZ ingress LB IP/hostname | **Platform** (manual → ExternalDNS later) | Created only when BZ is activated |

**Manual first:** keep control and learn the flow. **ExternalDNS later:** automate `wp-pz`/`wp-bz` updates when LB IPs churn.

---

## Cloudflare Considerations

- **Proxy (orange cloud):** optional. When enabled, Cloudflare terminates TLS and may cache. For DR drills, consider **off** initially to reduce variables.
- **CNAME at apex:** not supported traditionally; Cloudflare can **flatten**. We keep our logical name **off‑apex** (`wp-active.guajiro.xyz`).
- **Health checks:** optional Cloudflare Health Checks can monitor `wp-active`/per‑zone names; keep them informational at first.
- **Purge:** after flips, if using proxy/cache, purge specific hostnames to accelerate consistency.

---

## ExternalDNS (optional, later)

If you install **ExternalDNS** in each zone:
- Provider: **cloudflare**
- Scope token: Zone:DNS:Edit for `guajiro.xyz`
- Annotate `Service`/`Ingress` so `wp-pz`/`wp-bz` are created/updated automatically
- Keep `wp-active` as **manual/Terraform** to preserve explicit human control over flips

---

## Flip Procedure (Summary)

1. Ensure target zone is **ready**: ingress LB online, cert valid, app healthy.
2. **Reduce TTL** for `wp-active` (see `ttl-policy.md`) ahead of the window.
3. Edit `wp-active.guajiro.xyz` → set CNAME **target** to `wp-bz.guajiro.xyz` (or back to `wp-pz`).
4. Validate: `dig +short wp-active.guajiro.xyz` then `curl -I https://wp-active.guajiro.xyz`.
5. After stabilization, **restore TTL** to normal.

See detailed runbook: `docs/runbooks/dns/flip-active-cname.md`.

---

## Validation & Monitoring

- **DNS:** `dig +short wp-active.guajiro.xyz` should resolve to the new target quickly.
- **TLS:** certificate must be valid and match the host on the target zone.
- **Synthetics:** probe `wp-active`, `wp-pz`, `wp-bz`; watch success rate and latency.
- **Dashboards:** annotate flip time; track error rate and p99 latency.

---

## Common Pitfalls

- Changing per‑zone records during a flip (don’t). Only update `wp-active` CNAME.
- Forgetting to reduce TTL before the flip → longer convergence.
- Missing certificate for the target host → TLS error after flip.
- Using apex records without flattening plan → broken CNAME chain.
