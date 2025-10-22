# Security — Terraform State Backend

**Goal:** Keep Terraform state secure, consistent, and collaboratively accessible with locking and versioning.

---

## Requirements
- **Encryption at rest** and **in transit**.
- **State locking** to avoid concurrent mutation.
- **Versioning** and **history** for rollback/audit.
- **Scoped access**: least‑privilege credentials per workspace/environment.

---

## Recommended Backends
Choose one (document credentials and access separately):

1. **Terraform Cloud/Enterprise (preferred for teams)**
   - Remote execution optional.
   - Built‑in encryption, locking, versioning, RBAC, policy sets.

2. **Object storage + locking**
   - S3‑compatible bucket (e.g., DO Spaces with server‑side encryption) **+** DynamoDB‑equivalent locking (or Terraform Cloud for state only).
   - Enable bucket **versioning**, enforce TLS, block public access.
   - Separate buckets/prefixes per env: `prod/pz`, `prod/bz`.

> Local state is acceptable only for the lab **documentation phase**. For real runs, migrate to a remote backend before `apply`.

---

## Layout & Workspaces
- One workspace per zone: `prod-pz`, `prod-bz`.
- Separate state files and backends if needed to hard‑isolate permissions.
- Tag state with metadata: `project=wp`, `env=prod`, `zone=pz|bz`.

---

## Access Control
- Use CI runner identity with minimal scope for **read/write** to state.
- Human access: read-only unless doing break‑glass operations.
- Rotate backend credentials; store only in CI secret store / password manager.

---

## State Hygiene
- Never commit `terraform.tfstate*` or `.terraform/` to Git.
- Run `terraform plan` in read‑only contexts; restrict `apply` to protected pipelines.
- On destroy, confirm workspaces and var-file paths to avoid cross‑zone damage.

---

## Migration
- Use `terraform state pull/push` or backend config blocks to migrate.
- Validate after migration with `terraform state list` and `plan` (no drift).

---

## Incident Response
- If state is corrupted/leaked: lock down backend, rotate credentials, restore from previous version, review audit logs, and re‑plan.
