# Security — Secrets Policy

**Scope:** Tokens, passwords, keys, certificates and kubeconfigs used across Terraform, DOKS, Cloudflare, cert‑manager, WordPress, and DO Managed MySQL for `guajiro.xyz`.

---

## Principles
- **Least privilege:** Scope tokens narrowly (per‑zone, per‑service) and avoid account‑wide/global keys.
- **No secrets in Git:** Never commit secrets or kubeconfigs. Use environment variables and CI secret stores.
- **Short‑lived where possible:** Prefer tokens that can be rotated independently; document rotation.
- **Encrypt at rest and in transit:** Use provider vaults/secret stores; enforce TLS for DB connections and ACME.
- **Separation of duties:** Different tokens for Terraform (infra) vs. runtime (Kubernetes apps).

---

## Secret Classes & Owners
| Class | Examples | Owner | Store (authoring) | Store (runtime) |
|---|---|---|---|---|
| Infra provider | `DIGITALOCEAN_TOKEN` | Infra | CI secret store | N/A |
| DNS provider | Cloudflare API token (Zone:DNS:Edit) | Platform | CI secret store | K8s secret `cloudflare-api-token-secret` (namespace `platform`) |
| DB credentials | `DB_USER`, `DB_PASSWORD`, `DB_HOST`, CA bundle | Platform/DB | Password manager / CI | K8s secret `wp-db` (namespace `app`) |
| App storage | S3/R2 keys for media | App | Password manager / CI | K8s secret `wp-s3` (namespace `app`) |
| TLS/ACME | ACME account keys (managed by cert‑manager) | Platform | K8s secrets | K8s secrets in `platform` |

> CI secret store = your CI (GitHub/GitLab) encrypted variables, restricted to protected branches only.

---

## Handling Secrets in Kubernetes
- **Namespace scoping:** `platform` for platform secrets, `app` for application secrets.
- **RBAC:** Read access only for service accounts that require the secret. No cross‑namespace mounts.
- **Mount vs env:** Prefer `envFrom` for simple key/values; mount files only for CA bundles or large blobs.
- **Rotation:** Update secret → roll pods, verify app health. Maintain runbooks for DB password rotation.

---

## Creation & Rotation
- Create via `kubectl create secret ... --dry-run=client -o yaml | kubectl apply -f -` (keeps secrets out of shell history).
- Record: creator, date, purpose, expiration/rotation cadence.
- **Rotation triggers:** personnel change, CI scope change, incident, or scheduled cadence (quarterly recommended).

---

## CI/CD Usage
- CI retrieves tokens from its secret store at runtime; never echoes values.
- Use scoped tokens per pipeline (e.g., `deploy-pz`, `deploy-bz`). Disable on branch deletion.
- Mask secrets in logs; fail pipelines that attempt to print secret values.

---

## Incident Handling
- If a secret is suspected leaked: **revoke/rotate immediately**, audit access, invalidate sessions, review logs, update runbooks/postmortem.

---

## Do / Don’t
**Do**
- Use per‑environment tokens (`prod-pz`, `prod-bz`).
- Limit Cloudflare token to **Zone:Read + Zone:DNS:Edit** only.
- Store DB CA cert as a separate key in the secret, mount as file.

**Don’t**
- Don’t commit `.kube/config` or Terraform state containing secrets.
- Don’t reuse the same token across Terraform and Kubernetes app runtime.
- Don’t share secrets through chat/email; link to password manager items instead.
