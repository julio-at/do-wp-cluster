############################################################
# Module: modules/db — resources
############################################################

resource "digitalocean_database_cluster" "this" {
  count = var.enabled ? 1 : 0

  name                 = var.name
  engine               = "mysql"
  version              = var.engine_version
  region               = var.region
  size                 = var.size
  node_count           = var.node_count
  private_network_uuid = var.vpc_uuid
}

resource "digitalocean_database_db" "this" {
  count      = var.enabled ? 1 : 0
  cluster_id = digitalocean_database_cluster.this[0].id
  name       = var.db_name
}

resource "digitalocean_database_user" "app" {
  count      = var.enabled ? 1 : 0
  cluster_id = digitalocean_database_cluster.this[0].id
  name       = var.db_user
}

data "digitalocean_database_ca" "ca" {
  count      = var.enabled ? 1 : 0
  cluster_id = digitalocean_database_cluster.this[0].id
}

