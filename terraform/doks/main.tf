# Descubre versiones válidas de K8s en DO
data "digitalocean_kubernetes_versions" "this" {}

locals {
  selected_k8s_version = var.kubernetes_version != "" ? var.kubernetes_version : (
    length([
      for v in data.digitalocean_kubernetes_versions.this.valid_versions :
      v if startswith(v, var.kubernetes_minor_prefix)
    ]) > 0 ?
    [
      for v in data.digitalocean_kubernetes_versions.this.valid_versions :
      v if startswith(v, var.kubernetes_minor_prefix)
    ][0] :
    data.digitalocean_kubernetes_versions.this.latest_version
  )
}

# VPC dedicada para el clúster (una por región)
resource "digitalocean_vpc" "this" {
  name     = "${var.cluster_name}-vpc"
  region   = var.region
  ip_range = var.vpc_cidr
}

# Cluster DOKS mínimo (sin LB, sin addon extra)
resource "digitalocean_kubernetes_cluster" "this" {
  name    = var.cluster_name
  region  = var.region
  version = local.selected_k8s_version

  vpc_uuid = digitalocean_vpc.this.id

  node_pool {
    name       = "default"
    size       = var.node_size
    node_count = var.node_count
    tags       = var.tags
  }

  tags = var.tags
}

