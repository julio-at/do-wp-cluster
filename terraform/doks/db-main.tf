############################################################
# Root: db-main.tf — Instantiate DB module per zone
# - VPC lookup by NAME "default-<region>" (no tfvars for VPC)
# - No firewall resources here
############################################################

# ---------------------------
# Primary Zone (PZ) — nyc3
# ---------------------------
# Lookup default VPC for PZ region
data "digitalocean_vpc" "pz_default" {
  count = var.enable_db_pz ? 1 : 0
  name  = "default-${var.db_pz.region}"
}

module "db_pz" {
  source  = "./modules/db"
  enabled = var.enable_db_pz

  name           = var.db_pz.name
  region         = var.db_pz.region
  size           = var.db_pz.size
  engine_version = var.db_pz.engine_version
  node_count     = var.db_pz.node_count
  vpc_uuid       = var.enable_db_pz ? data.digitalocean_vpc.pz_default[0].id : ""

  db_name = var.db_pz.db_name
  db_user = var.db_pz.db_user
}

# ---------------------------
# Backup Zone (BZ) — sfo3
# ---------------------------
# Lookup default VPC for BZ region
data "digitalocean_vpc" "bz_default" {
  count = var.enable_db_bz ? 1 : 0
  name  = "default-${var.db_bz.region}"
}

module "db_bz" {
  source  = "./modules/db"
  enabled = var.enable_db_bz

  name           = var.db_bz.name
  region         = var.db_bz.region
  size           = var.db_bz.size
  engine_version = var.db_bz.engine_version
  node_count     = var.db_bz.node_count
  vpc_uuid       = var.enable_db_bz ? data.digitalocean_vpc.bz_default[0].id : ""

  db_name = var.db_bz.db_name
  db_user = var.db_bz.db_user
}

