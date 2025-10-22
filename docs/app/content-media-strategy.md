# App — Content & Media Strategy

**Goal:** Ensure content is safe and portable across DR flips and zone failovers.

---

## Database
- **System of record** for posts, users, metadata.
- Hosted in DO Managed MySQL (PZ writer).

**During DR (Option A — Replica):**
- Promote BZ replica to writer; app points to it.
- RPO ~ replication lag at promotion.

**During DR (Option B — Restore):**
- Restore from latest backup/PITR in BZ.
- RPO = time since last backup; record timestamp.

---

## Media (Object Storage)
- Use S3-compatible (DO Spaces or R2). Bucket name: `wp-media` (example).
- Store credentials in secret `wp-s3`. Configure WordPress plugin to offload uploads.

**Replication Options:**
- **Single bucket (simplest):** both zones read/write the same bucket. Ensure network egress costs are acceptable.
- **Dual bucket with replication (advanced):** replicate objects PZ→BZ. More complexity, less risk of regional outages affecting media.

**URL Strategy:**
- Serve media under your domain or bucket URL. If using Cloudflare, consider CDN in front of the bucket later.

---

## Backups
- DB backups managed by provider; document schedule and retention.
- Optionally enable bucket lifecycle policies/versioning for media.

---

## Acceptance
- Upload in PZ appears in object storage immediately.
- After DR flip, media URLs still valid and accessible.
