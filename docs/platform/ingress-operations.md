# Platform — Ingress Controller Operations

**Scope:** Operación del NGINX Ingress Controller en DOKS para PZ (nyc3) y BZ (sfo3). Incluye despliegue, verificación, métricas y mantenimiento seguro.

---

## Objetivos
- Exponer WordPress vía `LoadBalancer` solo cuando la zona esté activa.
- Emitir TLS automáticamente con cert-manager (DNS-01/Cloudflare).
- Exportar métricas para SLOs (latencia p99, error ratio).
- Minimizar cambios durante DR flips (CNAME strategy).

---

## Ciclo de Vida

### Instalación (docs-first → implementar después)
- Helm chart oficial `ingress-nginx` en `namespace=platform`.
- Valores de referencia en `docs/snippets/ingress-nginx-values.md`.
- Servicio `controller.service.type=LoadBalancer` (exposición pública).

### Verificación
```bash
kubectl -n platform get deploy,svc -l app.kubernetes.io/name=ingress-nginx
kubectl -n platform get svc/ingress-nginx-controller -o wide
kubectl -n platform logs deploy/ingress-nginx-controller --tail=200
```

### Métricas
- Habilitar `controller.metrics.enabled=true` y `serviceMonitor.enabled=true`.
- Validar en Prometheus (`/targets`) y paneles de Grafana.

### TLS
- Ingress debe tener la anotación: `cert-manager.io/cluster-issuer=le-prod-cloudflare`.
- Certificado `wp-tls` debe quedar en `Ready=True` antes de exponer tráfico.

---

## Operación Diaria
- **Cambios de configuración**: usar Helm (valores) o `ConfigMap` del controller; evitar ediciones manuales en pods.
- **Rotación de IP del LB**: ver `lb-ip-rotation.md`. Con CNAME per-zone (`wp-pz`/`wp-bz`) es transparente mientras se actualice el A/AAAA o CNAME del per-zone.
- **Escalado**: aumentar `replicaCount` del controller solo si hay saturación o latencia elevada.
- **Logs**: revisar access y error logs para outliers (picos 5xx).

---

## Buenas Prácticas
- Mantener **una sola clase** de Ingress (`nginx`) para simplificar.
- No mezclar Ingress públicos y privados sin separar controladores.
- Validar límites: `proxy-body-size`, `keepalive`, `timeouts` según WP y plugin de media.
- Evitar dependencias circulares (no exponga Prometheus/Grafana públicamente por el mismo Ingress al inicio).

---

## Problemas Comunes
- **LB Pending**: revisar cuotas en DO; forzar recreación del Service.
- **Errores 5xx**: mismatch Service/port o pods no Ready.
- **TLS Pending**: fallas DNS-01; token Cloudflare incorrecto.

---

## Runbooks Relacionados
- Flip de CNAME — `docs/runbooks/dns/flip-active-cname.md`
- DR Game-Day — `docs/runbooks/dr-game-day-playbook.md`
