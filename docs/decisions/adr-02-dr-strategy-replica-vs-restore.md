# ADR-02 — DR Strategy: Replica (A) vs Restore (B)

**Status:** Accepted  
**Date:** 2025-10-22

## Context
We need DR readiness without high steady costs. Two options: keep a read-replica in BZ (A) or restore-on-activation (B).

## Decision
Default to **Option B (Restore on Activation)** for the lab to minimize cost. Keep Option A documented for scenarios requiring lower RPO.

## Consequences
- Lower steady cost; slightly higher RTO/RPO during activation.
- Requires regular restore drills to maintain confidence.
- Failback requires restore or reverse replication to PZ.
