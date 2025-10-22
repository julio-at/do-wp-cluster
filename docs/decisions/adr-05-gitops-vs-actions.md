# ADR-05 — Direct CI (Actions) now, consider Argo CD later

**Status:** Accepted  
**Date:** 2025-10-22

## Context
We need a simple start for the lab and avoid extra moving parts.

## Decision
Start with **GitHub Actions** (or GitLab CI) to run Terraform/Helm directly. Revisit **Argo CD** once values/manifests stabilize.

## Consequences
- Faster bootstrap, fewer components.
- Less in-cluster reconciliation; drift detection handled via CI and periodic diffs.
