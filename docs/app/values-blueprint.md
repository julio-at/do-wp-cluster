# App — Values Blueprint (documentation)

> Conceptual **Helm values** we intend to pass when we implement. These are **examples**, not final values. We keep secrets out of Git; use Kubernetes Secrets.

```yaml
replicaCount: 1

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: le-prod-cloudflare
  hosts:
    - host: wp-active.guajiro.xyz
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wp-tls
      hosts: [ wp-active.guajiro.xyz ]

# Disable internal DB if chart includes one
mariadb:
  enabled: false

# External DB wiring (chart-specific keys may vary)
externalDatabase:
  enabled: true
  host: "$(DB_HOST)"
  user: "$(DB_USER)"
  password: "$(DB_PASSWORD)"
  database: "$(DB_NAME)"
  tls:
    caSecretName: wp-db
    caSecretKey: DB_CA_CERT

# Environment from secrets (example syntax — depends on chart)
env:
  - name: DB_HOST
    valueFrom: { secretKeyRef: { name: wp-db, key: DB_HOST } }
  - name: DB_USER
    valueFrom: { secretKeyRef: { name: wp-db, key: DB_USER } }
  - name: DB_PASSWORD
    valueFrom: { secretKeyRef: { name: wp-db, key: DB_PASSWORD } }
  - name: DB_NAME
    valueFrom: { secretKeyRef: { name: wp-db, key: DB_NAME } }
  - name: S3_ENDPOINT
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_ENDPOINT } }
  - name: S3_BUCKET
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_BUCKET } }
  - name: S3_REGION
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_REGION } }
  - name: S3_ACCESS_KEY_ID
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_ACCESS_KEY_ID } }
  - name: S3_SECRET_ACCESS_KEY
    valueFrom: { secretKeyRef: { name: wp-s3, key: S3_SECRET_ACCESS_KEY } }

resources:
  requests: { cpu: 100m, memory: 256Mi }
  limits:   { cpu: 500m, memory: 512Mi }
```

**Notes**
- Final keys depend on the chosen chart; adjust accordingly.
- Secrets `wp-db` and `wp-s3` are created **before** install.
- Certificate `wp-tls` is auto-issued by cert-manager via annotation.
