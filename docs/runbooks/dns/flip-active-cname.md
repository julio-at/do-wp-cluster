# Runbook — Flip Active CNAME (wp-active.guajiro.xyz)

**Purpose:** Safely switch production traffic between zones by changing a **single CNAME**: `wp-active.guajiro.xyz` → (`wp-pz.guajiro.xyz` | `wp-bz.guajiro.xyz`).

---

## Preconditions
- Target zone is healthy and ready to serve (Ingress LB up, cert valid).
- Change window approved; stakeholders notified.
- TTL policy understood (reduce TTL **before** the flip if needed).

---

## Inputs
- Cloudflare access (token/UI).
- Target: `wp-pz.guajiro.xyz` (normal) or `wp-bz.guajiro.xyz` (DR).

---

## Steps

### 1) (Optional) Reduce TTL ahead of change
- Set `wp-active.guajiro.xyz` TTL to **30–60s** at least a few minutes before flipping.

### 2) Update CNAME target
- In Cloudflare DNS:
  - Edit **CNAME** `wp-active.guajiro.xyz`
  - Set **Content** to the target (`wp-pz.guajiro.xyz` or `wp-bz.guajiro.xyz`)
  - Save changes.

### 3) Verify propagation
```bash
# Expect CNAME to point to the new target
dig +short wp-active.guajiro.xyz
# Follow chain:
dig +trace wp-active.guajiro.xyz | tail -n +1
```

### 4) Validate service
```bash
curl -I https://wp-active.guajiro.xyz
# Expect 200/301 and valid TLS chain
```

### 5) Restore TTL (post-change)
- Return TTL to **300s** (or your normal policy) after stability window.

---

## Rollback
- Re-edit the CNAME back to the previous target.
- Keep low TTL during the rollback window.

---

## Notes
- Do **not** touch per-zone records during flip; only the `wp-active` CNAME.
- If using Cloudflare proxy (orange cloud), consider cache/purge behaviors.
