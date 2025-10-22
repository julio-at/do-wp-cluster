# Stage 06 — BZ Readiness Tests

## Preconditions
- BZ platform installed (no public exposure), app present (replicas 0/1).

## Readiness checks
- Namespaces `platform`, `app` exist; pods healthy.
- cert-manager + ClusterIssuers present.
- Monitoring stack UP.
- (Option A) **Replica** exists; record current replication lag.
- (Option B) Restore playbook documented; backup timestamp known.

## Optional smoke (internal-only)
- `kubectl -n app port-forward svc/wp 8080:80` and hit `/` locally.
- DB connectivity probe via initContainer or ephemeral job.

## Exit criteria
- BZ can be activated within RTO budget once DR is declared.
