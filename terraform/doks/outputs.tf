output "cluster_name" {
  value       = digitalocean_kubernetes_cluster.this.name
  description = "Kubernetes cluster name"
}

output "cluster_id" {
  value       = digitalocean_kubernetes_cluster.this.id
  description = "Kubernetes cluster ID"
}

output "region" {
  value       = var.region
  description = "Region for this cluster"
}

output "vpc_id" {
  description = "VPC ID used by the cluster (default-<region>)"
  value       = try(local.vpc_uuid, null)
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "VPC CIDR"
}

output "kubeconfig_raw" {
  value       = digitalocean_kubernetes_cluster.this.kube_config[0].raw_config
  description = "Raw kubeconfig content"
  sensitive   = true
}

output "kubernetes_version" {
  value       = digitalocean_kubernetes_cluster.this.version
  description = "Effective Kubernetes version"
}

