# ClusterIssuers — Cloudflare DNS-01 (cert-manager)

**Namespace (Secret):** `cert-manager`  
**Secret name:** `cloudflare-api-token`  
**Secret key:** `api-token` (required)

Use these as a reference to compose `k8s/platform/<zone>/cert-manager/clusterissuers.yaml`.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: ops@guajiro.xyz                # REPLACE if needed
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: le-account-key-staging
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token  # must exist in cert-manager ns
              key: api-token
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: ops@guajiro.xyz                # REPLACE if needed
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: le-account-key-prod
    solvers:
      - dns01:
          cloudflare:
            apiTokenSecretRef:
              name: cloudflare-api-token
              key: api-token
```
