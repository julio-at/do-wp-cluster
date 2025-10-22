# ADR-04 — ExternalDNS Scope

**Status:** Accepted  
**Date:** 2025-10-22

## Context
We want automation for per-zone records but must retain human control over traffic flips.

## Decision
Use ExternalDNS **only** for `wp-pz`/`wp-bz` automation (later). Keep `wp-active` **manual** (Terraform/UI/API) for explicit flips.

## Consequences
- Reduces toil when LB IPs rotate.
- Flip remains a conscious, audited operation.
