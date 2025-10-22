# Stage 04 — DNS & Exposure (domain: guajiro.xyz)

> **Goal:** Expose WordPress *later* via HTTPS on `wp-active.guajiro.xyz`, using a CNAME chain that lets us flip between zones (PZ/BZ) without caring about changing LoadBalancer IPs.

- **We still deploy only in PZ first.** BZ remains off (created on-demand in Stage 06/07).
- **We will not apply anything right now**; this is documentation-first. Use it as a runbook when you decide to test.

---

## Naming (DNS)

We will use a stable logical CNAME and two per–zone hostnames:

```
wp-active.guajiro.xyz   (stable logical CNAME)
    └─→  wp-pz.guajiro.xyz     (CNAME during normal ops)
         or wp-bz.guajiro.xyz  (CNAME during DR flip)

wp-pz.guajiro.xyz  ── A/AAAA → PZ ingress LB public IP/hostname
wp-bz.guajiro.xyz  ── A/AAAA → BZ ingress LB public IP/hostname
```

**Why:** You only change `wp-active` when flipping zones; per–zone records are “owned” by the cluster runtime (manually or via ExternalDNS).

> **Note:** We keep to subdomains (no apex). If later you need `guajiro.xyz` at apex, use Cloudflare **CNAME flattening** (not part of this stage).

---

## Components in this stage

1) **Ingress Controller (NGINX)** in each zone (we’ll install on PZ when testing).
2) **A public Service: LoadBalancer** for the controller (this creates the external entrypoint).
3) **TLS** via cert-manager ClusterIssuer (`le-prod-cloudflare`) defined in Stage 03.
4) **DNS records** in Cloudflare for `wp-pz.guajiro.xyz`, `wp-bz.guajiro.xyz`, and the stable `wp-active.guajiro.xyz` CNAME.

We document two DNS update patterns:
- **Option A (simple):** Manually create/update DNS records in Cloudflare.
- **Option B (Kubernetes-native):** Use **ExternalDNS** to update `wp-pz`/`wp-bz` automatically.

> Choose **A** first for simplicity; switch to **B** when you want auto-updates on LB IP changes.

---

## Ingress Controller (NGINX) — what we will apply later

> Install **only** in PZ for first test. Keep BZ for Stage 06.

Helm chart (no public manifest here; commands are for later execution):

```bash
# PZ context
export KUBECONFIG=$PWD/artifacts/kubeconfig-pz

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx   --namespace platform   --create-namespace   --set controller.ingressClassResource.name=nginx   --set controller.ingressClassByName=true   --set controller.ingressClass=nginx   --set controller.service.type=LoadBalancer
```

Wait for external address:

```bash
kubectl -n platform get svc ingress-nginx-controller -w
# Note the EXTERNAL-IP or external hostname
```

> Optional: give the DO Load Balancer a deterministic name via annotations if you want to reduce churn; not required for the CNAME strategy.

---

## TLS (cert-manager ACME DNS-01, Cloudflare)

- We already created `ClusterIssuer le-prod-cloudflare` in Stage 03.
- In Stage 05 (app), your Ingress will reference it to issue certs for `wp-active.guajiro.xyz` (and/or per-zone hostnames).

Example Ingress TLS annotation you’ll use later (documentation only):

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: le-prod-cloudflare
spec:
  tls:
  - hosts: [ "wp-active.guajiro.xyz" ]
    secretName: wp-tls
```

> For first exposure tests, you can request a cert on `wp-pz.guajiro.xyz` too, then switch the logical CNAME later.

---

## DNS Records in Cloudflare (documentation-first)

### Option A — Manual DNS
1) Create **A/AAAA** (or CNAME to the LB hostname) for **PZ**:
   - **Name:** `wp-pz`  
   - **Type:** A (or AAAA) **or** CNAME to your cloud LB hostname  
   - **Content:** *PZ ingress LB external IP / hostname*  
   - **Proxy:** (on/off) per your WAF/Proxy decision  
   - **TTL:** 300s (reduce to 30–60s only during flips)

2) (Later) Create the same for **BZ** (`wp-bz`) when BZ exists.

3) Create **CNAME** for the logical stable record:
   - **Name:** `wp-active`
   - **Type:** CNAME
   - **Content:** `wp-pz.guajiro.xyz` (normal) **or** `wp-bz.guajiro.xyz` (during DR)

> **Flip procedure:** change only the **target** of `wp-active`.

### Option B — ExternalDNS (optional)
- Install ExternalDNS in each zone with provider **cloudflare**.
- Configure a token with **Zone:DNS:Edit** scoped to `guajiro.xyz`.
- Annotate the Ingress/Service so ExternalDNS keeps `wp-pz` (and later `wp-bz`) up-to-date with the running LB IP/hostname.
- Keep `wp-active` as a Terraform/Manual CNAME so you retain explicit control over flips.

---

## Validation plan (when you decide to test)

1) **Ingress LB online (PZ):**  
   `kubectl -n platform get svc ingress-nginx-controller` → has EXTERNAL-IP/hostname.

2) **DNS resolves:**  
   `dig +short wp-pz.guajiro.xyz` → returns the LB IP/hostname.  
   `dig +short wp-active.guajiro.xyz` → returns `wp-pz.guajiro.xyz` (CNAME) and then the LB.

3) **TLS issuance (after app Ingress in Stage 05):**  
   - Ingress references `le-prod-cloudflare`.  
   - `kubectl describe certificate wp-tls` shows `Ready=True`.

4) **No exposure in BZ yet** (by design).

---

## Troubleshooting (quick)

- **No EXTERNAL-IP on Service:** wait a few minutes; verify cloud events. Check `kubectl -n platform describe svc ingress-nginx-controller`.
- **Cloudflare not resolving:** record not created or cached → verify DNS zone, record names (`wp-pz`, `wp-active`), TTL, and proxy status.
- **ACME DNS-01 pending:** cert-manager logs + Cloudflare DNS `_acme-challenge` updates; re-check the API token scope.
- **Wrong target after flip:** remember the only flip is `wp-active` → (`wp-pz` | `wp-bz`). Per–zone records should stay pointed to their current LB.

---

## Exit Criteria for Stage 04 (when executed)
- PZ has a working **Ingress Controller** with a public entrypoint.
- Cloudflare has `wp-pz.guajiro.xyz` and `wp-active.guajiro.xyz` set up.
- You can curl the PZ entrypoint (won’t serve app content yet).
- No BZ exposure until Stage 06/07.

---

## Next Stage (05 — Minimal Application)
- Deploy WordPress (replicas=1) pointing to DO Managed MySQL (PZ).
- Create the application Ingress, reference `le-prod-cloudflare`, validate TLS on `wp-active.guajiro.xyz`.
- Keep `wp-bz` reserved for DR runbooks; don’t expose it until Stage 06/07.
