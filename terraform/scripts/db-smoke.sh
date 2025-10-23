#!/usr/bin/env bash
set -euo pipefail

# db-smoke.sh — Smoke test de conexión MySQL (TLS) desde cada clúster hacia su DB regional
# Uso:
#   scripts/db-smoke.sh --zone pz
#   scripts/db-smoke.sh --zone bz
#   scripts/db-smoke.sh --zone both
#   scripts/db-smoke.sh --zone pz --no-clean        # no elimina el pod al final
#
# Requisitos:
#   - Ejecutar desde: terraform/doks   (importante para leer state/outputs)
#   - binarios: terraform, jq, kubectl, doctl
#   - doctl autenticado (doctl auth init --access-token '...')
#
# Notas:
#   - Obtiene todo de `terraform output -json`. NO usa variables de entorno.
#   - Intenta primero outputs anidados tipo "db_pz.{host,private_host,port,...}".
#     Si no existen, intenta planos: "db_pz_host", "db_pz_private_host", etc.
#   - Requiere un output "cluster_name" por workspace.
#   - Usa el endpoint PRIVADO si existe; si no, cae al público.
#
# Salida esperada:
#   - "mysqld is alive"
#   - SELECT 1 con resultado "1"

ZONE="pz"
CLEANUP=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --zone)
      ZONE="${2:-}"; shift 2;;
    --no-clean)
      CLEANUP=0; shift;;
    -h|--help)
      echo "Usage: $0 --zone [pz|bz|both] [--no-clean]"; exit 0;;
    *)
      echo "Unknown arg: $1"; exit 1;;
  esac
done

require_bins() {
  for b in terraform jq kubectl doctl; do
    command -v "$b" >/dev/null 2>&1 || { echo "ERROR: missing binary: $b"; exit 1; }
  done
}
require_bins

run_zone() {
  local z="$1"   # pz | bz
  local ws="prod-$z"
  local pod="db-smoke"
  local ns="default"

  echo "==[ $z ]=============================================================="

  # 1) Seleccionar workspace
  terraform workspace select "$ws" >/dev/null 2>&1 || {
    echo "ERROR: workspace '$ws' no existe. Créalo/aplica Stage-02 primero."; exit 1;
  }

  # 2) Leer outputs JSON
  local TFOUT
  TFOUT="$(terraform output -json)"

  # 3) cluster_name (obligatorio)
  local CLUSTER_NAME
  CLUSTER_NAME="$(jq -r '.cluster_name.value // empty' <<<"$TFOUT")"
  if [[ -z "$CLUSTER_NAME" || "$CLUSTER_NAME" == "null" ]]; then
    echo "ERROR: output 'cluster_name' no encontrado en workspace $ws."
    echo "       Revisa tus outputs de Terraform."
    exit 1
  fi
  echo "Cluster: $CLUSTER_NAME"

  # 4) Resolver outputs de DB
  local DBKEY="db_${z}"

  jq_try() {
    local query_nested="$1"  # e.g. .[$k].value.host
    local query_flat="$2"    # e.g. .db_pz_host.value
    local val
    val="$(jq -r --arg k "$DBKEY" "$query_nested // empty" <<<"$TFOUT")"
    if [[ -z "$val" || "$val" == "null" ]]; then
      val="$(jq -r "$query_flat // empty" <<<"$TFOUT")"
    fi
    [[ "$val" == "null" ]] && val=""
    printf "%s" "$val"
  }

  local HOST PRIVATE_HOST PORT DB USER PASS CA
  HOST="$(          jq_try '.[$k].value.host'           ".${DBKEY}_host.value" )"
  PRIVATE_HOST="$(  jq_try '.[$k].value.private_host'   ".${DBKEY}_private_host.value" )"
  PORT="$(          jq_try '.[$k].value.port'           ".${DBKEY}_port.value" )"
  DB="$(            jq_try '.[$k].value.database'       ".${DBKEY}_database.value" )"
  USER="$(          jq_try '.[$k].value.username'       ".${DBKEY}_username.value" )"
  PASS="$(          jq_try '.[$k].value.password'       ".${DBKEY}_password.value" )"
  CA="$(            jq_try '.[$k].value.ca_cert'        ".${DBKEY}_ca_cert.value" )"

  local ENDPOINT="${PRIVATE_HOST:-$HOST}"

  for v in ENDPOINT PORT DB USER PASS CA; do
    if [[ -z "${!v:-}" ]]; then
      echo "ERROR: falta output DB para '$v' en workspace $ws (key base: $DBKEY)."
      echo "       Revisa 'terraform output' y ajusta nombres si cambian."
      exit 1
    fi
  done

  echo "DB endpoint: ${ENDPOINT}:${PORT}"
  echo "DB name:     ${DB}"
  echo "DB user:     ${USER}"

  # 5) Kubeconfig y contexto
  doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" >/dev/null
  kubectl config current-context | sed 's/^/kube-context: /'

  # 6) Borrar pod previo si existe
  kubectl -n "$ns" delete pod/"$pod" --ignore-not-found >/dev/null || true

  # 7) Pasar el CA como base64 en una env var (una sola línea)
  local CA_B64
  CA_B64="$(printf '%s' "$CA" | base64 -w0 2>/dev/null || printf '%s' "$CA" | base64 | tr -d '\n')"

  # 8) Crear pod y decodificar el CA dentro del contenedor
  kubectl -n "$ns" run "$pod" --image=mysql:8.0 --restart=Never \
    --env="DB_HOST=${ENDPOINT}" \
    --env="DB_PORT=${PORT}" \
    --env="DB_NAME=${DB}" \
    --env="DB_USER=${USER}" \
    --env="DB_PASS=${PASS}" \
    --env="DB_CA_B64=${CA_B64}" \
    -- bash -lc '
      set -euo pipefail
      apt-get update >/dev/null 2>&1 || true
      apt-get install -y ca-certificates coreutils >/dev/null 2>&1 || true

      printf "%s" "$DB_CA_B64" | base64 -d > /tmp/ca.pem

      echo "Pinging MySQL on ${DB_HOST}:${DB_PORT} ..."
      mysqladmin --ssl-mode=VERIFY_CA --ssl-ca=/tmp/ca.pem \
        -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" ping

      echo "Running SELECT 1 on ${DB_NAME} ..."
      mysql --ssl-mode=VERIFY_CA --ssl-ca=/tmp/ca.pem \
        -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" \
        -e "SELECT 1;" "${DB_NAME}"
    ' >/dev/null

  # 9) Esperar y mostrar logs
  kubectl -n "$ns" wait --for=condition=Ready pod/"$pod" --timeout=180s || true
  echo "---- logs ($z) ----"
  kubectl -n "$ns" logs "$pod" || true
  echo "-------------------"

  # 10) Limpieza
  if [[ "$CLEANUP" -eq 1 ]]; then
    kubectl -n "$ns" delete pod/"$pod" --ignore-not-found >/dev/null || true
    echo "[cleanup] pod ${pod} eliminado"
  else
    echo "[keep] pod ${pod} preservado (usa --no-clean para esto)"
  fi

  echo
}

case "$ZONE" in
  pz)   run_zone "pz" ;;
  bz)   run_zone "bz" ;;
  both) run_zone "pz"; run_zone "bz" ;;
  *)    echo "ERROR: --zone debe ser pz|bz|both"; exit 1;;
esac

