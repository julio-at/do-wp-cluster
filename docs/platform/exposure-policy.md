# Platform — Exposure Policy

**Objetivo:** Controlar cuándo y cómo exponemos servicios públicos; evitar endpoints abiertos cuando una zona está en frío (BZ inactiva).

---

## Lineamientos
- PZ: Ingress Controller con `LoadBalancer` **activo**.
- BZ (fría): mantener controller instalado pero **Service sin exposición** (opcional) o LB activo pero **DNS no apuntando**.
- Evitar múltiples Ingress públicos con distintas clases para la misma app sin un motivo claro.

---

## Alternativas según costo
1) **LB activo en ambas zonas**, DNS decide el tráfico (más costo, RTO bajo).
2) **LB solo en PZ**, BZ crea LB **on-demand** durante DR (menos costo, RTO mayor).
   - Documentar tiempo promedio de provisioning del LB en BZ.

---

## Checklist de Exposición
- [ ] Cert-Manager y `ClusterIssuer` listos.
- [ ] Ingress con anotación del issuer y host correcto.
- [ ] `wp-<zone>.guajiro.xyz` resuelve al LB correcto.
- [ ] TLS **Ready=True** en `wp-tls` antes de recibir tráfico.

---

## Validación
```bash
kubectl -n platform get svc/ingress-nginx-controller -o wide
dig +short wp-pz.guajiro.xyz
curl -I https://wp-pz.guajiro.xyz
```

---

## Reversión
- Remover/apagar el Service `LoadBalancer` si se requiere cerrar exposición temporalmente.
- Mantener documentación del tiempo de recreación posterior.
