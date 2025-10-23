############################################################
# BACKUP ZONE (BZ) — SFO3
############################################################

# --- Kubernetes (deja tus valores actuales) ---
cluster_name     = "wp-bz-doks-sfo3"
region           = "sfo3"
enable_autoscale = true
min_nodes        = 1
max_nodes        = 3
# node_count     = 1
node_size        = "s-2vcpu-4gb"
tags             = ["env:prod", "zone:bz", "app:wp"]

# --- Managed MySQL (BZ) — para pruebas puedes habilitar; luego OFF ---
enable_db_bz = true 
db_bz = {
  region         = "sfo3"
  name           = "wp-bz-db"
  size           = "db-s-1vcpu-1gb"
  engine_version = "8"
  node_count     = 1
  db_name        = "wp_prod"
  db_user        = "wp_app"
}

