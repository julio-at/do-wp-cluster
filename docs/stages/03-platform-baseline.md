# Stage 03 — Platform Baseline (cert-manager + Ingress)

**Objective:** Prepare TLS and ingress for the platform in **Primary Zone (PZ)**, and pre-stage **Backup Zone (BZ)**. No app exposure or DNS flip yet (that’s Stage-04).

## Scope
- **cert-manager** installed and configured with **DNS-01 (Cloudflare)**.
- **ClusterIssuers** for **staging** and **production**.
- **NGINX Ingress Controller** in **PZ** only (LoadBalancer).
- **BZ**: only prepare cert-manager (issuers). Keep ingress **cold** for now.

> We keep the repo’s existing structure. All manifests and runbooks referenced here live under the current folders in the `dodb` branch. No file moves.

---

## Prerequisites
- Cloudflare account managing `guajiro.xyz`.
- **Cloudflare API Token** (scoped to `guajiro.xyz`) with:
  - Permissions: `Zone.Zone:Read`, `Zone.DNS:Edit`
- Contact email for Let’s Encrypt (e.g., `ops@guajiro.xyz`).
- Kubeconfig/context set to **PZ** for PZ steps; **BZ** for BZ steps.
- Clusters and (if needed) DBs are already provisioned in Stage-02.

---

## Deliverables (this stage)
- Snippet: `docs/snippets/clusterissuers-cloudflare.md` (reference for Issuers)
- Runbook: `docs/runbooks/platform/platform-bringup-zone.md` (step-by-step)
- Prepared (empty or to-be-filled later) k8s structure under:
  - `k8s/platform/pz/cert-manager/clusterissuers.yaml`
  - `k8s/platform/pz/ingress-nginx/values.yaml`
  - `k8s/platform/pz/ingress-nginx/echo.yaml` (optional smoke)
  - `k8s/platform/bz/cert-manager/clusterissuers.yaml`
  - `k8s/platform/bz/ingress-nginx/values.yaml` (replicaCount: 0 recommended)

> This stage focuses on **readiness**. Certificates can be issued via DNS-01 without pointing DNS to the LoadBalancer yet.

---

## High-level Plan

1) **Namespaces + Secret (Cloudflare token)**  
   - Create `cert-manager` and `ingress-nginx` namespaces.  
   - Store token as `Secret` → `cert-manager/cloudflare-api-token` (key: `api-token`).

2) **Install cert-manager (Helm)**  
   - Install CRDs and controller in `cert-manager` namespace.

3) **ClusterIssuers**  
   - Apply `ClusterIssuer` for **staging** and **prod** using Cloudflare DNS-01 solver.  
   - Optional: pre-provision `Certificate` for `wp-pz.guajiro.xyz` and `wp-active.guajiro.xyz` (staging first).

4) **NGINX Ingress Controller (PZ)**  
   - Deploy with `LoadBalancer` service.
   - Optional: `echo` app + Ingress to smoke HTTP via EXTERNAL-IP.

5) **BZ pre-stage**  
   - Repeat **Namespaces + Secret + Issuers** in BZ.  
   - Keep ingress disabled or `replicaCount: 0`.

---

## Success Criteria
- `cert-manager` pods **Running**.
- `ClusterIssuer` resources **Ready** (staging & prod).
- `ingress-nginx-controller` `Service` in **PZ** has **EXTERNAL-IP**.
- Optional HTTP smoke returns a response from the echo service.
- No DNS changes performed yet.

---

## What’s Next (Stage-04)
- Create DNS A/AAAA pointing to PZ LB (and BZ when active).  
- Issue production certs and wire `wp-active.guajiro.xyz` **CNAME** to the active zone.
- Define exposure policy & security headers before opening to traffic.
