# Observability — Multi-Zone & DR Considerations

> Ensure observability supports the **decision to flip** and the **validation after flip**.

---

## Key Signals for DR
- **PZ health**: app + ingress + DB status (red when deciding to flip).
- **BZ readiness**: same signals green before flip.
- **DB strategy**:
  - **Replica (A)**: replication lag within policy; promotion time measured.
  - **Restore (B)**: backup age, restore duration, and post-restore checks.

## DNS Flip Telemetry
- Synthetics report success/latency before and after flip.
- Track time from CNAME change to majority success.

## Evidence
- Keep a **timeline** with absolute timestamps and screenshots.
- Attach RTO/RPO calculations post-event.

## Cost & Hygiene
- Disable nonessential collectors in BZ when cold.
- Keep dashboards resilient when a zone is absent.
