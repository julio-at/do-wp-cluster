# Stage 05 — Smoke & Functional Tests (PZ)

## Preconditions
- PZ kubeconfig ready, app deployed, TLS issued for `wp-active.guajiro.xyz`.

## Smoke tests
1. **Ingress/TLS**
   - `curl -I https://wp-active.guajiro.xyz` → `200/301` + valid cert
   - `kubectl -n app get ingress` shows correct host
2. **Pods**
   - `kubectl -n app get deploy/wp` → desired replicas available
   - No CrashLoopBackOff
3. **Observability**
   - Grafana via port-forward loads
   - Prometheus targets UP

## Functional tests
1. **Login** to `/wp-admin`
2. **Create post** and publish (text + image)
3. **Upload media** and verify it is in object storage
4. **View homepage** and check the post is visible

## Negative tests (light)
- Wrong DB password → app shows connection error; roll back secret.
- Remove CA file → TLS to DB fails; restore secret.

## Exit criteria
- All smoke & functional tests pass.
- Dashboards show normal error rate and acceptable p99 latency.
