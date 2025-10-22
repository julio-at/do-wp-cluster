# Stage 07 — DR Rehearsal Tests

Use together with runbooks in `docs/runbooks/`.

## Steps
1. **Decision & timebox** — IC opens bridge, assigns roles.
2. **DB path:** promote replica (A) or restore to BZ (B).
3. **App activation:** scale `wp` in BZ, wire secrets, ensure TLS.
4. **Flip CNAME:** `wp-active` → `wp-bz` (reduce TTL before).
5. **Validation:** synthetic checks, business flows, dashboards.
6. **Failback:** re-seed/restore PZ and flip back.

## Measurements
- RTO (declaration → 200 OK on `wp-active` served by BZ)
- RPO (lag at promotion or backup age at restore)
- DNS convergence time (dig/synthetics)

## Exit criteria
- Successful activation and failback with recorded metrics.
- Issues captured and action items assigned.
