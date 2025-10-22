# DB — Operations

**Scope:** Day-2 operations for DigitalOcean Managed MySQL powering WordPress.

---

## Access & Networking
- Enforce **Trusted Sources** to the **VPC CIDR** of each zone (PZ/BZ). See `docs/security/trusted-sources.md`.
- Prefer private networking paths; app connects over TLS with CA bundle.

## Users & Privileges
- App user: least privilege (`SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `INDEX` as needed for WP). Avoid superuser privileges.
- Separate **admin** user for maintenance tasks; never embed admin creds in app.

## Monitoring
- Watch provider metrics (connections, CPU, disk IO, slow queries).
- Capture **availability symptoms** via ingress SLOs (error ratio, latency).
- Track **replication lag** (Option A) or **restore times** (Option B) for DR readiness.

## Maintenance
- Apply minor engine upgrades in maintenance windows.
- Resize plan based on sustained CPU >60% or storage >70%.
- Keep PITR window sized to RPO target.

## Runbooks
- Promote replica to writer — `docs/runbooks/db/promote-replica-to-writer.md`
- Restore writer in BZ — `docs/runbooks/db/restore-writer-in-bz.md`
