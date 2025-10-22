# Operations — Change Management & Rollbacks

**Scope:** All planned changes to the WordPress platform for `guajiro.xyz` across infra (Terraform), platform (K8s add-ons), application (WP), and DNS. Applies to **PZ** and **BZ**.

---

## Principles
- **Safety first:** prefer reversible, incremental changes with clear stop/rollback points.
- **Docs-first:** every change references a doc/runbook and has an owner.
- **Review & approvals:** PR + peer review; production applies require manual approval.
- **Evidence:** capture timestamps and results for audits and learning.
- **Separation of duties:** proposer ≠ approver for production changes.

---

## Change Types
| Type | Examples | Approvals | Window |
|---|---|---|---|
| Standard | routine Helm upgrade of monitoring, WP minor update | 1 approver | business or low-risk hours |
| Normal | Terraform updates (node size/count), Ingress upgrades | 1–2 approvers | maintenance window |
| Major | DB plan change, cert-manager migration, DR drills | 2 approvers (IC named) | scheduled DR window |
| Emergency | Hotfix to restore service | IC approval (retro doc) | immediate |

---

## Roles
- **Requester/Owner:** drafts plan, risk, and rollback; executes or coordinates.
- **Approver(s):** validates risk/rollback adequacy.
- **Incident Commander (IC):** for major/emergency windows; timebox + go/no-go.
- **Scribe:** captures evidence (logs, screenshots, timestamps).

---

## Change Workflow (Template)
1. **Plan Doc** (link in ticket/PR):
   - *What/Why/Where (PZ|BZ)*
   - *Risk*, *Impact*, *Rollback* (≤ 5 steps, ≤ 15 min)
   - *Runbooks* referenced
   - *Comms plan* (who to notify)
   - *Pre-checks* and *Post-checks*
2. **Review & Approvals**
   - PR review, CI passes (`plan`/`diff` artifacts). Approvers sign.
3. **Pre-Change**
   - Lower TTL if DNS involved; take DB snapshot if schema-affecting; ensure dashboards healthy.
4. **Execute**
   - Timeboxed; announce start. Follow runbooks/commands in plan.
5. **Validate**
   - Smoke tests + business checks + dashboards. Decide go/rollback.
6. **Close & Evidence**
   - Annotate outcomes, attach artifacts, record RTO/RPO if relevant.

---

## Pre-Checks (Common)
- [ ] `terraform plan` clean (no surprises) when infra involved
- [ ] `helm diff` clean; values reviewed
- [ ] Secrets current (DB, S3, Cloudflare)
- [ ] cert-manager issuers Ready; Ingress controller healthy
- [ ] Backup snapshot/restore point recorded (if DB)
- [ ] Observability dashboards green; alert noise low
- [ ] TTL policy applied if `wp-active` flip is in-scope

## Post-Checks (Common)
- [ ] `curl -I https://wp-active.guajiro.xyz` 200/301
- [ ] Admin login + post + media upload OK
- [ ] Error rate & p99 latency within thresholds
- [ ] No CrashLoops; HPA/autoscaler stable (if enabled)
- [ ] Rollback not required (or successful if executed)

---

## Rollback Strategy
- **Infra (Terraform):** revert PR → apply previous plan; avoid mid-flight state drift; use workspaces per zone to contain blast radius.
- **Platform (Helm):** `helm rollback <release> <rev>` or re-apply last known-good values.
- **Application (WP):** rollback container tag/values; ensure DB schema backwards compatible.
- **DNS:** revert CNAME target; keep TTL low during rollback window.
- **DB:** if promotion/restore failed, keep PZ serving (don’t half-flip); follow DR runbooks.

**Rollback Guardrails**
- Keep **last known-good** artifacts (charts/values/plan) attached to the ticket.
- Define **abort criteria** (e.g., >2% 5xx for 5 min or p99 > 4s) to trigger rollback quickly.
- Maintain **operator checklist** with timestamps for each step.

---

## Maintenance Windows & Freezes
- Routine changes during business hours only if *fully reversible in ≤ 15 min*.
- DR drills: dedicated windows with IC + Scribe.
- Freeze periods: during critical business events; emergency-only changes with IC.

---

## Communication
- Pre-change notice in team channel with ETA and scope.
- During change: status updates at start, key milestones, end.
- Post-change: success/rollback summary + links to evidence and updated docs.

---

## Risk Matrix (Quick Guide)
- **Low:** no DB/TLS/DNS involvement; simple chart bump → standard change.
- **Medium:** Ingress controller, cert-manager, node pool resize → normal change.
- **High:** DB promotion/restore, DR flips, state backend change → major change.

---

## Links & References
- DNS flip runbook — `docs/runbooks/dns/flip-active-cname.md`
- DR Game-Day — `docs/runbooks/dr-game-day-playbook.md`
- Backup Policy — `docs/security/backup-policy.md`
- TTL policy — `docs/dns/ttl-policy.md`

---

## Templates
**Change Plan (copy/paste into ticket):**
- **Title:** <component> — <zone> — <summary>
- **When:** <UTC window>
- **Owner/IC/Scribe:** <names>
- **Scope:** <infra|platform|app|dns>
- **Risk:** <low|medium|high> — rationale
- **Runbooks:** <links>
- **Pre-checks:** <list>
- **Steps:** <1..N>
- **Rollback:** <≤ 5 steps>
- **Post-checks:** <list>
- **Evidence:** <what & where>
