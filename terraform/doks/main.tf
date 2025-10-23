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

############################################################
# Use regional default VPC (no VPC creation)
############################################################

# Asume que ya tienes: variable "region" { ... } definida en variables.tf

# Default VPC name pattern in DO is "default-<region>"
locals {
  default_vpc_name = "default-${var.region}"
}

# Look up the default VPC by NAME
data "digitalocean_vpc" "default" {
  name = local.default_vpc_name
}

# Convenience local to pass into cluster resources
locals {
  vpc_uuid = data.digitalocean_vpc.default.id
}

# Cluster DOKS mínimo (sin LB, sin addon extra)
resource "digitalocean_kubernetes_cluster" "this" {
  name    = var.cluster_name
  region  = var.region
  version = local.selected_k8s_version

  vpc_uuid = local.vpc_uuid

  node_pool {
    name       = "default"
    size       = var.node_size
    node_count = var.node_count

    auto_scale = var.enable_autoscale
    min_nodes  = var.enable_autoscale ? var.min_nodes : null
    max_nodes  = var.enable_autoscale ? var.max_nodes : null

    tags = var.tags
  }

  tags = var.tags
}

