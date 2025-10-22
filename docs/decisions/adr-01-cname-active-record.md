# ADR-01 — Use `wp-active` CNAME for traffic switching

**Status:** Accepted  
**Date:** 2025-10-22

## Context
Ingress LB IPs/hostnames can change; we need clean, reversible flips between zones without modifying per-zone records during incidents.

## Decision
Create a stable logical hostname `wp-active.guajiro.xyz` (CNAME) that points to `wp-pz.guajiro.xyz` or `wp-bz.guajiro.xyz`. Only flip this CNAME during DR or failback.

## Consequences
- Simpler, auditable flips and rollbacks.
- Per-zone records managed separately (manual first, ExternalDNS later).
- Off-apex host preferred; apex requires flattening with extra caveats.
