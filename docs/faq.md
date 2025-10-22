# FAQ — WordPress on DOKS (PZ/BZ)

## Why use a CNAME (`wp-active`) instead of switching A records?
Because the Ingress LB IP can change. A logical CNAME lets us flip between `wp-pz` and `wp-bz` without touching per-zone records or chasing IPs.

## Can we put `wp-active` at the apex (`guajiro.xyz`)?
Possible with Cloudflare CNAME flattening, but we prefer an off-apex host (e.g., `wp-active.guajiro.xyz`) to keep the chain simple during DR drills.

## Do we need a load balancer in BZ all the time?
No. For the lab we prefer **on-demand** LB in BZ to save costs. This increases RTO slightly; we document the provisioning time.

## Why Managed MySQL instead of running our own in the cluster?
Lower operational risk and simpler backups/PITR. We trade some flexibility for reliability and speed of recovery.

## How do we measure success in a DR drill?
Collect RTO (time to serve `200 OK` from BZ), RPO (replication lag or backup age), DNS convergence time, and business-flow success (login, post, upload). See `docs/testing/`.

## What if cert issuance fails during a flip?
Use staging issuer to debug, confirm the Cloudflare token and zone, and only then switch back to prod issuer. Do not flip traffic until `wp-tls` is `Ready=True` in the target zone.

## Do we use ExternalDNS?
Not initially. Manual per-zone records first (learn the flow). Later, ExternalDNS can automate `wp-pz/wp-bz` updates; `wp-active` stays manual for controlled flips.

## Is Blue/Green the same as multi-zone DR?
No. Blue/Green is **within a zone** for releases. DR is **between zones** for outages or drills.

## Can we keep BZ “warm” with a replica?
Yes (Option A), at higher steady cost and cross-region traffic. The lab defaults to **restore-on-activation** (Option B).

## How do we control costs?
See `docs/infra/cost-controls.md` and `docs/infra/cost-playbook.md`. Keep BZ off by default, avoid dangling LBs, and right-size nodes.
