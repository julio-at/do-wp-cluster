# CI/CD — Promotion Strategy

- **Docs-first** → then enable `app-deploy.yml` to PZ only.
- Introduce **Blue/Green** within PZ using two Deployments/Services and a controlled Ingress switch.
- DR flips live in a **separate, manual** workflow (`dr-flip.yml`) with approvals.
