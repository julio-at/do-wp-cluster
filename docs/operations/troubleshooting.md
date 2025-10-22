# Operations — Troubleshooting Catalog

**Purpose:** Quick diagnosis → fixes for common issues in our WordPress on DOKS stack (PZ nyc3 / BZ sfo3). Keep this terse, actionable, and linked to runbooks.

---

## How to use this guide
1) Identify the symptom quickly.
2) Run the **minimum** diagnostics below (copy/paste friendly).
3) Apply the fix or jump to the linked runbook.
4) Capture evidence in `docs/testing/evidence-checklist.md` if incident-level.

---

## 1) Ingress returns 5xx / site down

**Symptoms**
- `curl -I https://wp-active.guajiro.xyz` → 5xx / timeout
- Grafana shows error ratio spike on ingress

**Diagnostics**
```bash
kubectl -n app get ingress,svc,deploy,pods
kubectl -n app describe ingress
kubectl -n app logs deploy/wp -c <app-container> --tail=200
kubectl -n platform get svc -l app.kubernetes.io/name=ingress-nginx
kubectl -n platform logs deploy/ingress-nginx-controller --tail=200
```

**Likely causes**
- App pods not Ready / CrashLoop
- Service/port mismatch
- TLS secret missing/invalid
- Ingress Controller LB not provisioned

**Fixes**
- Restart deployment: `kubectl -n app rollout restart deploy/wp`
- Correct Service ports/path and re-apply
- Ensure cert exists: `kubectl -n app get certificate wp-tls` (see §2)
- If LB pending >10m: recycle ingress controller or check cloud quota

**When to escalate**
- Persistent LB provisioning errors → cloud support
- Widespread 5xx after change → roll back (see Change Management)

---

## 2) TLS/Certificate issues (cert-manager)

**Symptoms**
- Browser shows certificate error
- `kubectl -n app describe certificate wp-tls` shows `Ready=False`
- Events mention DNS-01 challenge failures

**Diagnostics**
```bash
kubectl -n platform get pods | grep cert-manager
kubectl get clusterissuer le-prod-cloudflare -o yaml | sed -n '1,60p'
kubectl -n app describe certificate wp-tls
kubectl -n app describe challenge | tail -n +1
```

**Likely causes**
- Missing/incorrect Cloudflare token secret
- Wrong DNS zone or record not propagating
- Issuer name/annotation mismatch on Ingress

**Fixes**
- Ensure secret exists: `kubectl -n platform get secret cloudflare-api-token-secret`
- Re-apply ClusterIssuers from docs/snippets (as MD reference)
- Confirm Ingress annotation: `cert-manager.io/cluster-issuer=le-prod-cloudflare`
- For retries: delete failed `Challenge`/`Order`; reapply Ingress/Certificate

**When to escalate**
- Rate limits from ACME: back off; use staging issuer temporarily

---

## 3) DNS flip not taking effect

**Symptoms**
- After changing `wp-active` CNAME, some users still hit old zone

**Diagnostics**
```bash
dig +short wp-active.guajiro.xyz
dig +trace wp-active.guajiro.xyz | tail -n +1
# From multiple networks if possible
```

**Likely causes**
- TTL not reduced before flip
- CDN/proxy cache holding old target
- Local resolver caching

**Fixes**
- Reduce TTL per `docs/dns/ttl-policy.md`, wait buffer
- Purge CDN/Cloudflare (if proxied)
- Validate synthetics; wait for convergence window
- If wrong target: edit CNAME and re-validate

**Runbook**
- `docs/runbooks/dns/flip-active-cname.md`

---

## 4) DB connection / TLS errors

**Symptoms**
- WordPress shows error: can't connect to database
- Pod logs mention TLS/CA errors

**Diagnostics**
```bash
kubectl -n app get secret wp-db -o yaml | grep -E 'DB_HOST|DB_NAME|DB_USER' -n
kubectl -n app get secret wp-db -o yaml | grep DB_CA_CERT -n
kubectl -n app logs deploy/wp --tail=200
```

**Likely causes**
- Wrong host/port or credentials
- CA bundle missing/not mounted
- DB trusted sources not including VPC CIDR

**Fixes**
- Recreate secret with correct values (docs/runbooks have commands)
- Mount CA file key `DB_CA_CERT` and configure chart to use it
- Add VPC CIDR(s) to **Trusted Sources** (see `docs/security/trusted-sources.md`)

**When to escalate**
- Provider-side DB outage; switch to DR path if PZ writer is down

---

## 5) Terraform destroy fails: VPC with members (409)

**Symptoms**
- Error: `409 Can not delete VPC with members`

**Diagnostics & Fix**
```bash
cd terraform/doks
terraform destroy -target=digitalocean_kubernetes_cluster.this -var-file=../env/prod/<zone>.tfvars
terraform destroy -var-file=../env/prod/<zone>.tfvars
```
- Destroy cluster **before** VPC. Verify no LBs/volumes remain.

---

## 6) Node pressure / Pending pods

**Symptoms**
- Pods Pending / OOMKilled / Evicted; HPA scaling stalls

**Diagnostics**
```bash
kubectl describe node | egrep -i 'pressure|memory'
kubectl -n app describe po <pod>
kubectl get hpa -A
```

**Likely causes**
- Insufficient node resources or taints
- Autoscaler bounds too tight

**Fixes**
- Increase node pool size or enable autoscaling (min/max bounds)
- Adjust requests/limits; reduce replicas temporarily

---

## 7) ImagePullBackOff / registry issues

**Diagnostics**
```bash
kubectl -n app describe po <pod> | sed -n '1,120p'
```

**Likely causes**
- Wrong image tag / private registry creds missing

**Fixes**
- Correct tag; add imagePullSecret if private registry

---

## 8) Prometheus targets DOWN / No metrics

**Diagnostics**
```bash
kubectl -n platform get pod -l app.kubernetes.io/name=kube-prometheus-stack
kubectl -n platform port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
# Check /targets
```

**Fixes**
- Restart components; verify ServiceMonitors; ensure RBAC/permissions
- Keep services ClusterIP until we choose to expose

---

## 9) cert-manager ACME rate-limited

**Symptoms**
- Events show rate-limit exceeded

**Fixes**
- Switch temporary to **staging** issuer; retry later with prod
- Reuse existing valid cert (`wp-tls`) rather than forcing re-issue

---

## 10) Cloudflare proxy quirks

**Symptoms**
- Different behavior when orange-cloud enabled

**Fixes**
- For labs/DR drills, disable proxy first → validate DNS-only path
- If using proxy, remember to **purge** cache post-flip

---

## 11) kubeconfig / wrong context

**Symptoms**
- Commands hitting the wrong zone

**Fix**
```bash
export KUBECONFIG=$PWD/artifacts/kubeconfig-<zone>
kubectl config get-contexts
```

---

## 12) Helm release stuck

**Diagnostics**
```bash
helm -n <ns> history <release>
helm -n <ns> rollback <release> <REV>
```

**Fixes**
- Rollback to last known good; inspect diff; re-apply values

---

## Links
- DNS Flip: `docs/runbooks/dns/flip-active-cname.md`
- DR Playbook: `docs/runbooks/dr-game-day-playbook.md`
- Backup Policy: `docs/security/backup-policy.md`
- Trusted Sources: `docs/security/trusted-sources.md`
