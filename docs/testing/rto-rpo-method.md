# RTO / RPO Measurement Method

## RTO (Recovery Time Objective)
- **Start:** Incident declared / DR activation decision.
- **End:** First confirmed `200 OK` on `https://wp-active.guajiro.xyz` served by **BZ**.
- **Capture:** Chat timestamps + synthetic checks + `curl -I` with timestamp.

## RPO (Recovery Point Objective)
- **Replica (A):** last-known **replication lag** at the moment of promotion.
- **Restore (B):** **backup timestamp** used for restore vs. time of DR declaration.

## DNS Convergence
- Track time from CNAME edit to synthetics success majority.
- Note TTL used and any CDN/cache purges.

## Reporting
- Include RTO/RPO in postmortem; compare against targets; list improvements.
