# Platform — LoadBalancer IP Rotation

**Contexto:** La IP del LoadBalancer del Ingress Controller puede **cambiar** (recreación del Service/cluster, fallo del proveedor). Debemos minimizar el impacto.

---

## Enfoque Arquitectónico
- Nunca apuntamos a la IP directamente desde `wp-active`.
- Per-zone (`wp-pz`/`wp-bz`) es un **A/AAAA o CNAME** hacia el LB correspondiente.
- `wp-active` es un **CNAME lógico** que solo cambia de **target** en flips.

---

## Procedimiento cuando la IP cambia
1. Detectar nueva IP/hostname del Service:
   ```bash
   kubectl -n platform get svc/ingress-nginx-controller -o wide
   ```
2. Actualizar **solo** el registro per-zone:
   - `wp-pz.guajiro.xyz` → nueva IP/hostname en PZ
   - `wp-bz.guajiro.xyz` → nueva IP/hostname en BZ (si existe)
3. **No** tocar `wp-active.guajiro.xyz` durante esta operación.
4. Validar:
   ```bash
   dig +short wp-pz.guajiro.xyz
   curl -I https://wp-pz.guajiro.xyz
   ```

---

## Automatización (opcional futura)
- **ExternalDNS** para sincronizar per-zone con el Service/Ingress.
- Mantener `wp-active` manual para flips controlados.

---

## Evidencia
- Registrar timestamp, IP antigua/nueva y verificación `curl`.
