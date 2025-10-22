# CI/CD — Pipelines & Gates

## Gates
- **Plan must exist** before `apply`.
- **Manual approvals** for:
  - Terraform `apply`
  - BZ creation/teardown
  - DR flip
- **Smoke tests** must pass after deploy before marking success.

## Smoke Tests (examples)
- `kubectl -n app get deploy/wp` ready
- `curl -I https://wp-active.guajiro.xyz` 200/301
- Certificate `wp-tls` Ready=True
