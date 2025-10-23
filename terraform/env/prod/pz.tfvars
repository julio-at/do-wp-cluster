############################################################
# PRIMARY ZONE (PZ) — NYC3
############################################################

# --- Kubernetes (deja tus valores actuales) ---
cluster_name     = "wp-pz-doks-nyc3"
region           = "nyc3"
enable_autoscale = true
min_nodes        = 1
max_nodes        = 3
# node_count     = 1
node_size        = "s-2vcpu-4gb"
tags             = ["env:prod", "zone:pz", "app:wp"]

# --- Managed MySQL (PZ) — no firewall, VPC default-nyc3 (implícito) ---
enable_db_pz = true
db_pz = {
  region         = "nyc3"
  name           = "wp-pz-db"
  size           = "db-s-1vcpu-1gb"
  engine_version = "8"
  node_count     = 1
  db_name        = "wp_prod"
  db_user        = "wp_app"
}

