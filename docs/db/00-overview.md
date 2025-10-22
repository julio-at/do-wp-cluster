# DB — Overview (Managed MySQL on DigitalOcean)

**Goal:** Operational guidance for the WordPress database layer across zones: PZ (writer in nyc3) and BZ (replica or restore in sfo3).

## Responsibilities
- **Availability & access:** Trusted Sources (VPC CIDRs), TLS required.
- **Credentials:** rotation policy, least-privilege app user.
- **Backups/Restore:** per `docs/security/backup-policy.md`.
- **DR:** promotion (A) or restore (B) as documented in runbooks.
