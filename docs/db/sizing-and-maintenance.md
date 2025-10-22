# DB — Sizing & Maintenance Guide

**Objective:** Right-size the DB plan and schedule maintenance without surprising the app.

---

## Sizing Signals
- **CPU**: sustained > 60% → consider next plan.
- **Memory**: pressure or swap behavior in provider graphs.
- **Storage**: > 70% used → resize storage or cleanup.
- **Connections**: near plan limit → connection pooling or scale plan.

## Maintenance Windows
- Engine patching and minor version updates in **approved windows**.
- Announce read-only windows if needed (rare for WP).

## Indexes & Schema
- Use plugin/theme guidance; avoid heavy schema changes without testing.
- Take **manual snapshot** before schema-altering releases.

## DR Considerations
- Option A: keep replica in BZ; monitor **replication lag**.
- Option B: measure **restore duration** regularly to validate RTO.
