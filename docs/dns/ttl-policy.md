# DNS — TTL Policy (guajiro.xyz)

**Objective:** Define consistent TTLs to balance steady‑state caching and fast **DR flips** for `wp-active.guajiro.xyz`.

---

## Defaults (steady state)

| Record | TTL | Rationale |
|---|---:|---|
| `wp-active.guajiro.xyz` (CNAME) | **300s** | Reasonable cache; not too sticky |
| `wp-pz.guajiro.xyz` (A/AAAA or CNAME) | **300s** | LB addresses change rarely; moderate cache |
| `wp-bz.guajiro.xyz` (A/AAAA or CNAME) | **300s** | Same as above; may be absent when BZ is cold |

> Keep the same TTLs across environments unless there’s a compelling reason. During normal ops, **avoid very low TTLs** to reduce resolver load.

---

## During Flips / DR Tests

1. **Pre‑window (5–10 min before):**
   - Set `wp-active.guajiro.xyz` TTL to **60s** (or 30s if your provider allows).
2. **Execute flip:** change CNAME target to the destination zone.
3. **Observe:** wait 1–5 minutes; validate with `dig` and synthetic checks.
4. **Stabilization (after 10–30 min healthy):**
   - Restore TTL to **300s** (steady state).

> If using a CDN/proxy (e.g., Cloudflare orange cloud), DNS TTL may not directly control client behavior; you may also need to **purge cache** or rely on short **HTTP cache** headers during the window.

---

## Notes on Propagation

- **Resolver caches vary:** some ISPs honor TTL; some cache a floor (e.g., 60s). Plan buffers accordingly.
- **Client OS caching:** browsers/OS may cache independently; synthetic probes help measure “effective” convergence.
- **SOA/negative TTL:** NXDOMAIN and failures can be cached too; avoid deleting records during tests.

---

## Monitoring & Evidence

- Track time from edit → first successful probe on new target → majority success (RTO adjunct).
- Grafana annotation at flip time.
- Keep a **flip log** with timestamps, the old/new target, and TTL changes.

---

## Rollback

- Keep `wp-active` TTL **low** during rollback window.
- Repoint CNAME back to the previous zone, validate, then restore TTLs.
