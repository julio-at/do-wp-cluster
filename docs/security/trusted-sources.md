# Security — Trusted Sources (Network Allow Lists)

**Goal:** Define deterministic **allow lists** for components that must accept inbound connections, minimizing public exposure.

---

## Principles
- Prefer **private networking** (VPC) between cluster nodes and managed services.
- When public ingress is required, restrict by **CIDR** and protect with **TLS** and (if applicable) Cloudflare proxy/WAF.
- Keep allow lists at the **broadest stable scope** (VPC CIDR) rather than ephemeral pod/node IPs.

---

## DigitalOcean Managed MySQL
- Configure **Trusted Sources** to the **VPC CIDR** of each zone:
  - PZ VPC CIDR: e.g., `10.10.0.0/16`
  - BZ VPC CIDR: e.g., `10.20.0.0/16`
- Avoid per‑node IPs; nodes are ephemeral.
- Enforce **TLS** from the application (mount CA bundle in `wp-db` secret).
- During DR: add BZ CIDR before promotion/restore; remove after failback if desired.

---

## Cloudflare
- Use **DNS‑01** challenges for ACME; cert‑manager updates `_acme-challenge` via API token (no IP allow list needed).
- For public site traffic, decide on **proxy** (orange cloud) and WAF rules separately (not required for lab).

---

## Ingress (public)
- NGINX Ingress Controller Service is `LoadBalancer`. Public by design.
- Restrict sources at the LB (if provider supports it) or via Cloudflare when proxied.
- Keep admin paths behind auth or IP restrictions where possible.

---

## CI/CD
- Allow CI runners to the state backend and APIs only (DO API, Cloudflare API). Avoid inbound to clusters from CI; use GitOps or limited kubeconfig with RBAC.

---

## Documentation & Change Control
- Record all allow list changes with: date, requestor, rationale, CIDR(s), rollback plan.
- Review allow lists during DR rehearsals; ensure BZ paths are documented.
