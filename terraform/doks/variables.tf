variable "do_token" {
  description = "DigitalOcean API token (optional if DIGITALOCEAN_TOKEN env var is set)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region for the cluster (e.g., nyc3, sfo3)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Exact Kubernetes version slug (e.g., 1.30.6-do.0). If empty, the latest that matches kubernetes_minor_prefix will be used."
  type        = string
  default     = ""
}

variable "kubernetes_minor_prefix" {
  description = "Minor version prefix to select latest (e.g., 1.30). Ignored if kubernetes_version is set."
  type        = string
  default     = "1.30"
}

variable "node_size" {
  description = "Droplet size for worker nodes (e.g., s-2vcpu-4gb)"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of worker nodes (fixed; no autoscaling in this minimal stage)"
  type        = number
  default     = 3
}

variable "vpc_cidr" {
  description = "VPC CIDR for the cluster region (e.g., 10.10.0.0/16)"
  type        = string
  default     = "10.10.0.0/16"
}

variable "tags" {
  description = "Flat list of tags to apply"
  type        = list(string)
  default     = []
}

