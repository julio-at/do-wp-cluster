# Platform — Exposure Policy (English)

**Goal:** Control when/how we expose public endpoints; avoid open endpoints when a zone is cold (inactive BZ).

---

## Guidelines
- PZ: Ingress Controller with `LoadBalancer` **active**.
- BZ (cold): keep controller installed but either **no public Service** or LB active with **DNS not pointing** to it.
- Avoid multiple public Ingress controllers for the same app unless justified.

---

## Cost-based Options
1) **LB active in both zones**, DNS decides traffic (higher cost, lower RTO).
2) **LB only in PZ**, create LB in BZ **on-demand** during DR (lower cost, higher RTO).
   - Document average provisioning time for BZ LB.

---

## Exposure Checklist
- [ ] cert-manager + `ClusterIssuer` ready
- [ ] Ingress with issuer annotation and correct host
- [ ] `wp-<zone>.guajiro.xyz` resolves to the right LB
- [ ] TLS `wp-tls` **Ready=True** before receiving traffic

---

## Validation
```bash
kubectl -n platform get svc/ingress-nginx-controller -o wide
dig +short wp-pz.guajiro.xyz
curl -I https://wp-pz.guajiro.xyz
```

---

## Reversal
- Remove/disable the `LoadBalancer` Service if you need to temporarily close exposure.
- Document the time to recreate it afterwards.
