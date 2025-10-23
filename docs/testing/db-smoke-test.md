# Stage 02 — Managed MySQL Connectivity Smoke Test (PZ & BZ)

**Purpose:** Validate that each Kubernetes cluster (PZ & BZ) can reach its own **DigitalOcean Managed MySQL** over the **private VPC** endpoint using TLS (VERIFY_CA), before proceeding to Stage 03.

**Place this file at:** `docs/testing/db-smoke-test.md`

---

## Prerequisites

- `DIGITALOCEAN_TOKEN` exported and `doctl` authenticated.
- Clusters created and running: `wp-pz-doks-nyc3`, `wp-bz-doks-sfo3`.
- Managed DBs created via Terraform (PZ: enabled; BZ: enabled only if you want to test).
- Terraform states/workspaces:
  - `prod-pz` for Primary Zone
  - `prod-bz` for Backup Zone

> This test uses the **private VPC hostname** (`private_host`) and validates TLS with the cluster CA.

---

## Kubeconfig Setup (Choose one)

### Option A — Using Snap (recommended)
```bash
# grant kubeconfig permission to doctl (snap)
sudo snap connect doctl:kube-config

# save kubeconfig for each cluster
doctl kubernetes cluster kubeconfig save wp-pz-doks-nyc3
doctl kubernetes cluster kubeconfig save wp-bz-doks-sfo3

kubectl config get-contexts
```

### Option B — Without touching ~/.kube/config
```bash
doctl kubernetes cluster kubeconfig show wp-pz-doks-nyc3 > ~/kubeconfig-pz
doctl kubernetes cluster kubeconfig show wp-bz-doks-sfo3 > ~/kubeconfig-bz
chmod 600 ~/kubeconfig-*
# use one at a time
export KUBECONFIG=~/kubeconfig-pz   # or ~/kubeconfig-bz
kubectl get nodes
```

---

## Part 1 — Primary Zone (PZ) Smoke Test

### 1) Export DB outputs from Terraform (workspace: prod-pz)
```bash
cd terraform/doks
terraform workspace select prod-pz

TFJ="$(terraform output -json)"
echo "$TFJ" | jq '.db_pz.value'    # sanity check

export DB_HOST=$(echo "$TFJ" | jq -r '.db_pz.value.private_host')
export DB_USER=$(echo "$TFJ" | jq -r '.db_pz.value.username')
export DB_PASS=$(echo "$TFJ" | jq -r '.db_pz.value.password')
export DB_NAME=$(echo "$TFJ" | jq -r '.db_pz.value.database')
export DB_PORT=$(echo "$TFJ" | jq -r '.db_pz.value.port | tostring')
export DB_PORT="${DB_PORT:-3306}"
echo "$TFJ" | jq -r '.db_pz.value.ca_cert' > /tmp/ca-pz.pem
```

### 2) Create Secret in PZ
```bash
kubectl delete secret db-smoke --ignore-not-found
kubectl create secret generic db-smoke   --from-literal=DB_HOST="$DB_HOST"   --from-literal=DB_USER="$DB_USER"   --from-literal=DB_PASS="$DB_PASS"   --from-literal=DB_NAME="$DB_NAME"   --from-literal=DB_PORT="$DB_PORT"   --from-file=ca.pem=/tmp/ca-pz.pem
```

### 3) Run Job in PZ
```bash
kubectl delete job db-smoke --ignore-not-found

cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: db-smoke
spec:
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: mysql-client
          image: mysql:8
          command: ["bash","-lc"]
          args:
            - |
              set -euo pipefail
              : "${DB_PORT:=3306}"

              echo "Waiting for DNS..."
              for i in {1..20}; do getent hosts "$DB_HOST" && break || sleep 3; done

              echo "Probing TCP..."
              for i in {1..20}; do (echo >/dev/tcp/$DB_HOST/$DB_PORT) >/dev/null 2>&1 && break || sleep 3; done

              echo "Pinging MySQL on $DB_HOST:$DB_PORT ..."
              mysqladmin ping                 -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS"                 --ssl-mode=VERIFY_CA --ssl-ca=/etc/db/ca.pem

              echo "SELECT 1..."
              mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS"                 --ssl-mode=VERIFY_CA --ssl-ca=/etc/db/ca.pem                 -e 'SELECT 1' "$DB_NAME"

              echo "OK"
          env:
            - name: DB_HOST
              valueFrom: { secretKeyRef: { name: db-smoke, key: DB_HOST } }
            - name: DB_USER
              valueFrom: { secretKeyRef: { name: db-smoke, key: DB_USER } }
            - name: DB_PASS
              valueFrom: { secretKeyRef: { name: db-smoke, key: DB_PASS } }
            - name: DB_NAME
              valueFrom: { secretKeyRef: { name: db-smoke, key: DB_NAME } }
            - name: DB_PORT
              valueFrom: { secretKeyRef: { name: db-smoke, key: DB_PORT } }
          volumeMounts:
            - name: db-ca
              mountPath: /etc/db
              readOnly: true
      volumes:
        - name: db-ca
          secret:
            secretName: db-smoke
            items:
              - key: ca.pem
                path: ca.pem
EOF

kubectl wait --for=condition=Complete job/db-smoke --timeout=5m
kubectl logs job/db-smoke
```

**Expected:**
```
mysqld is alive
+---+
| 1 |
+---+
| 1 |
+---+
OK
```

### 4) Cleanup (PZ)
```bash
kubectl delete job db-smoke --ignore-not-found
kubectl delete secret db-smoke --ignore-not-found
```

---

## Part 2 — Backup Zone (BZ) Smoke Test

> Only if you created the BZ DB for testing. Switch kubeconfig/context to BZ.

### 1) Export DB outputs from Terraform (workspace: prod-bz)
```bash
cd terraform/doks
terraform workspace select prod-bz

TFJ="$(terraform output -json)"
echo "$TFJ" | jq '.db_bz.value'    # sanity check

export DB_HOST=$(echo "$TFJ" | jq -r '.db_bz.value.private_host')
export DB_USER=$(echo "$TFJ" | jq -r '.db_bz.value.username')
export DB_PASS=$(echo "$TFJ" | jq -r '.db_bz.value.password')
export DB_NAME=$(echo "$TFJ" | jq -r '.db_bz.value.database')
export DB_PORT=$(echo "$TFJ" | jq -r '.db_bz.value.port | tostring')
export DB_PORT="${DB_PORT:-3306}"
echo "$TFJ" | jq -r '.db_bz.value.ca_cert' > /tmp/ca-bz.pem
```

### 2) Create Secret in BZ
```bash
kubectl delete secret db-smoke --ignore-not-found
kubectl create secret generic db-smoke   --from-literal=DB_HOST="$DB_HOST"   --from-literal=DB_USER="$DB_USER"   --from-literal=DB_PASS="$DB_PASS"   --from-literal=DB_NAME="$DB_NAME"   --from-literal=DB_PORT="$DB_PORT"   --from-file=ca.pem=/tmp/ca-bz.pem
```

### 3) Run Job in BZ
# Reuse the same manifest from PZ
```bash
kubectl wait --for=condition=Complete job/db-smoke --timeout=5m
kubectl logs job/db-smoke
```

### 4) Cleanup (BZ)
```bash
kubectl delete job db-smoke --ignore-not-found
kubectl delete secret db-smoke --ignore-not-found
```

---

## Optional — Destroy BZ after test (keep PZ running)
```bash
cd terraform/doks
terraform workspace select prod-bz
terraform destroy -var-file=../env/prod/bz.tfvars
```

---

## Troubleshooting

- **`Empty value for 'port' specified`**
  - Ensure `DB_PORT` is exported properly (`| tostring`) and present in Secret; pod defaults to `3306` as fallback.

- **Pod Pending / timing issues**
  - The Job includes DNS/TCP waits and `backoffLimit`. Re-run if needed.

- **Wrong cluster context**
  - `kubectl config current-context` before Secret/Job.

- **TLS issues**
  - Ensure `ca.pem` is the CA from Terraform outputs; `--ssl-mode=VERIFY_CA` must be used.

- **Connectivity from inside pod**
  ```bash
  kubectl exec -it job/db-smoke -- bash -lc '
    getent hosts "$DB_HOST" || nslookup "$DB_HOST" || true
    nc -vz "$DB_HOST" "$DB_PORT" || true
  '
  ```

---

## Success Criteria

- Job completes with logs indicating:
  - `mysqld is alive`
  - `SELECT 1` returns `1`
  - `OK` at the end

Proceed to **Stage 03** once both zones (as applicable) pass.
