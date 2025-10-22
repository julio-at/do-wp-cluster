# Testing — Overview

**Goal:** Validate platform and app behavior before any real traffic, and prove DR readiness. This folder defines tests for Stages 05–07 and how we capture evidence.

## Scope
- Stage 05: Minimal Application (PZ)
- Stage 06: Backup Zone On-Demand (BZ)
- Stage 07: DR Game-Day

## Testing layers
- **Smoke tests:** quick health checks after deploy.
- **Functional:** business flows (login, post, upload, fetch).
- **Resilience:** kill pods, node drain, restart components.
- **DR drills:** promotion/restore + DNS flip + failback.
- **Performance (light):** p95/p99 latency spot checks.

## Evidence
- Use `evidence-checklist.md` and `rto-rpo-method.md` to capture results.
