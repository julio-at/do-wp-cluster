# DB — Connectivity & TLS Tests

**Objective:** Prove that WordPress pods connect to MySQL over TLS using the CA bundle mounted from `wp-db` secret.

---

## Pre-reqs
- Secret `wp-db` in namespace `app` with keys: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and file key `DB_CA_CERT`.
- Trusted Sources include the cluster's VPC CIDR.

## Test 1 — Ephemeral MySQL client pod
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-<zone>
kubectl -n app run mysql-client --rm -it --image=mysql:8 -- bash -lc '
  apt-get update && apt-get install -y ca-certificates >/dev/null 2>&1 || true
  printenv | grep -E "DB_HOST|DB_NAME|DB_USER" || true
  # write CA from secret (mounted via projected volume in a real Job; doc-first uses inline example)
  # mysql --ssl-mode=VERIFY_CA --ssl-ca=/mnt/ca.crt -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT NOW();"
'
```
*Implementation note:* when we implement, we will mount the CA file from the secret into `/mnt/ca.crt` and use `--ssl-mode=VERIFY_CA`.

## Test 2 — App pod logs
- Induce a wrong password briefly; confirm connection fails with TLS path still attempted.
- Restore secret and confirm normal operation.

## Expected
- Successful TLS handshake; queries execute.
