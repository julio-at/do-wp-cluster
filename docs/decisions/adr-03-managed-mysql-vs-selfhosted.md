# ADR-03 — Managed MySQL vs Self-Hosted in K8s

**Status:** Accepted  
**Date:** 2025-10-22

## Context
Running DBs inside K8s increases operational burden (backups, HA, tuning).

## Decision
Use **DigitalOcean Managed MySQL** for WordPress.

## Consequences
- Built-in backups/PITR, simpler operations and DR.
- Less control over engine tuning; cost tied to managed tiers.
