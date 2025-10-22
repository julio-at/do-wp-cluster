# Infra — Networking & VPC

- Unique VPC per zone to simplify **Trusted Sources** on DO MySQL.
- Avoid overlapping CIDRs between zones.
- Keep cluster and DB in the **same VPC** when possible.
