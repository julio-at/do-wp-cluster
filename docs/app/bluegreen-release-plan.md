# App — Blue/Green Release Plan (within a zone)

> This is **intra-zone** blue/green (e.g., in PZ), separate from multi-zone DR flips. We’ll integrate with Argo CD/GitHub Actions later.

---

## Model
- **Blue** = live `wp` deployment
- **Green** = candidate `wp-green` (same namespace), isolated Service & Ingress host (e.g., `green.wp-active.guajiro.xyz` temporarily)
- Cutover by switching Ingress host/service selector, then scale down Blue.

---

## Steps (documentation-first)
1. Deploy `wp-green` with the same external DB and S3 secrets.
2. Smoke test on `green.wp-active.guajiro.xyz` (temporary DNS or host routing).
3. Cutover:
   - Update production Ingress to route to `wp-green` Service.
   - Monitor 5–15 min; if stable, scale down `wp` (blue).
4. Rollback: switch Ingress back to `wp` and scale down `wp-green`.

---

## Guardrails
- Keep DB schema backward compatible during releases.
- Avoid plugin/theme changes that require manual steps mid-cutover.
- Use maintenance mode briefly only if absolutely necessary.

---

## Observability
- Compare error rate/latency between Blue and Green during the ramp.
- Annotate change times in Grafana.

---

## Acceptance
- Zero-downtime cutover; quick rollback procedure validated.
