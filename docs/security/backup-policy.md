# Security — Backups & Restore Policy

**Scope:** WordPress platform data for `guajiro.xyz`: **MySQL** (posts, users, config) and **media** in object storage. Applies to PZ (**nyc3**) and BZ (**sfo3**).

---

## Objectives
- **RPO target:** ≤ 15 minutes (lab default; adjust per cost).
- **RTO target (DR):** ≤ 30 minutes to service `200 OK` from BZ.
- **Verify** restores regularly; treat backups as *untested* until proven.
- **Least privilege:** backup access separate from app access.

---

## Data Domains
1. **Database (MySQL Managed)**
   - PZ **writer**; BZ **replica** (Option A) or **restore-on-activation** (Option B).
2. **Media (Object Storage)**
   - DO Spaces or Cloudflare R2. No pod-local writes.

---

## Retention & Schedules

### Database (Managed MySQL)
- **Automated snapshots:** daily, retained **7 days** (lab) or **14–30 days** (prod-like).
- **Point-in-time recovery (PITR):** enable if available; **window 24–72h**.
- **Manual pre-change snapshots:** taken before schema-altering releases.
- **Encryption:** provider-managed at rest; TLS in transit (CA bundle).

### Media (Object Storage)
- **Versioning:** enabled for the bucket (recommended).
- **Lifecycle:** expire old non-current versions after **30–90 days**.
- **Replication:** optional PZ→BZ if using dual-bucket strategy.

---

## Access & Separation
- **Backup operator identity** (CI or human) distinct from app credentials.
- Store backup/restore API credentials in **CI secret store** (scoped, rotated).
- Deny write/delete on backup artifacts to runtime identities.

---

## Restore Strategies

### Option A — **Replica First**
- **Normal ops:** keep **read-replica** in BZ replicating from PZ writer.
- **DR:** *Promote* BZ replica to **writer** (see runbook).
- **Failback:** re-seed PZ from BZ by creating a new replica in PZ, then promote.
- **Pros:** lower RPO (lag). **Cons:** steady cost + cross-region traffic.

### Option B — **Restore on Activation**
- **Normal ops:** no DB running in BZ.
- **DR:** restore latest **snapshot** or **PITR** into BZ and point WP to it.
- **Failback:** restore back to PZ or replicate from BZ to PZ.
- **Pros:** lower standing cost. **Cons:** higher RTO/RPO; restore time.

---

## Backup Validation (Testing)
- **Quarterly** DR rehearsal includes a **restore test**.
- **Checklist:**
  - [ ] Create DB from backup/PITR to an **isolated env** (non-production).
  - [ ] Run WP smoke tests (login/post/upload) against restored DB.
  - [ ] Verify **users/posts/media links**.
  - [ ] Document elapsed times (backup selection → ready to serve).
- **Evidence:** timestamps, screenshots, query logs, artifacts (per `docs/testing/`).

---

## Media Integrity Tests
- With versioning enabled:
  - [ ] Upload file, delete current version, recover previous version.
  - [ ] Validate URLs after DR flip still resolve and are authorized.
- If dual-bucket replication:
  - [ ] Confirm replication lag ≤ threshold.
  - [ ] Random sample object exists in both buckets (hash match).

---

## Change Windows & Pre-change Safeguards
- Before plugin/theme upgrades or schema changes:
  - [ ] Take **manual snapshot** (DB) and note snapshot ID.
  - [ ] Ensure media versioning is enabled.
  - [ ] Record **restore point** in change ticket.

---

## Roles & Ownership
- **DB Lead:** backup policy config, snapshot/PITR monitoring.
- **Platform Lead:** object storage lifecycle, replication policies.
- **IC (during DR):** go/no-go on restore vs. replica promotion.
- **Scribe:** evidence capture for RTO/RPO and restore correctness.

---

## Security Controls
- Enforce **TLS** from app to DB (CA in `wp-db` secret).
- Backup/restore credentials: **read/list/restore** only; avoid destructive scopes.
- **Audit**: retain API audit logs for backup/restore operations for **90 days**.

---

## Runbook Links
- Replica promotion: `docs/runbooks/db/promote-replica-to-writer.md`
- Restore writer in BZ: `docs/runbooks/db/restore-writer-in-bz.md`
- DR Playbook: `docs/runbooks/dr-game-day-playbook.md`

---

## Exit Criteria
- Documented RPO/RTO targets and **measured** in the last rehearsal.
- Last restore test **succeeded** within target RTO.
- Backup failure alerts enabled and monitored.
