# CI/CD — GitOps (Argo CD) vs Direct Actions

**Option 1: Argo CD (GitOps)**
- Pros: drift detection, declarative sync, rollback, multi-app views.
- Cons: extra component to manage; bootstrap complexity.

**Option 2: Direct Actions (Helm in CI)**
- Pros: simple, fewer moving parts.
- Cons: less in-cluster reconciliation, harder drift detection.

**Recommendation:** Start with **Direct Actions** for the lab. Revisit **Argo CD** when we stabilize values/manifests.
