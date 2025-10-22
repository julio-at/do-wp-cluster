# Snippet — ClusterIssuers (Cloudflare DNS-01)

**Purpose:** Issue TLS certs via Let's Encrypt using Cloudflare DNS-01 for `guajiro.xyz`.  
**Docs-first:** This is reference YAML shown here for clarity; the actual YAML will live in your repo when you implement.

## Prereqs
- Secret `cloudflare-api-token-secret` in `platform` namespace with key `api-token`.
- Token scopes: `Zone:Read` + `Zone:DNS:Edit` for the `guajiro.xyz` zone only.

## YAML (reference)
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: le-staging-cloudflare
spec:
  acme:
    email: you@guajiro.xyz
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-staging-account-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: le-prod-cloudflare
spec:
  acme:
    email: you@guajiro.xyz
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: acme-prod-account-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

## Usage
- Add annotation to Ingress: `cert-manager.io/cluster-issuer: le-prod-cloudflare`
- Certificate status: `kubectl -n app describe certificate wp-tls`

## Common Issues
- Wrong token name/key → Challenges stay in **Pending**.
- Zone mismatch → ACME cannot create `_acme-challenge` record.
