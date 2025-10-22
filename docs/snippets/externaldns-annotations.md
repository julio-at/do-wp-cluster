# Snippet — ExternalDNS Annotations (optional later)

**Purpose:** If/when you automate per-zone records (`wp-pz`, `wp-bz`) with ExternalDNS and Cloudflare.

## Ingress example
```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/target: "wp-pz.guajiro.xyz"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "false"
```

## Service example
```yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "wp-pz.guajiro.xyz"
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "false"
```

**Notes**
- Keep `wp-active.guajiro.xyz` **manual** to preserve explicit control for flips.
- Scope the ExternalDNS token to `Zone:DNS:Edit` and the specific zone only.
