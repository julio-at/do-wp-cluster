# Platform — LoadBalancer IP Rotation (English)

**Context:** The Ingress Controller's LoadBalancer IP/hostname may change (service/cluster recreation or provider events). Minimize impact.

---

## Architectural Approach
- Never point `wp-active` directly to an IP.
- Per-zone records (`wp-pz`/`wp-bz`) are **A/AAAA or CNAME** to the corresponding LB.
- `wp-active` is a **logical CNAME** that only changes **target** during flips.

---

## When the IP changes
1. Detect new IP/hostname:
   ```bash
   kubectl -n platform get svc/ingress-nginx-controller -o wide
   ```
2. Update **only** the per-zone DNS record:
   - `wp-pz.guajiro.xyz` → new IP/hostname in PZ
   - `wp-bz.guajiro.xyz` → new IP/hostname in BZ (if present)
3. **Do not** touch `wp-active.guajiro.xyz` during this operation.
4. Validate:
   ```bash
   dig +short wp-pz.guajiro.xyz
   curl -I https://wp-pz.guajiro.xyz
   ```

---

## Automation (optional, later)
- **ExternalDNS** to sync per-zone records from Service/Ingress.
- Keep `wp-active` manual to preserve controlled flips.

---

## Evidence
- Record timestamp, old/new IP, and `curl` verification.
