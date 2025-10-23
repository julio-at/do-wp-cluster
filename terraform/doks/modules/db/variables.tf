############################################################
# Module: modules/db — variables
############################################################

variable "enabled" {
  description = "Create the database resources when true"
  type        = bool
  default     = true
}

variable "name" {
  description = "DigitalOcean Managed DB cluster name"
  type        = string
}

variable "region" {
  description = "DigitalOcean region (e.g., nyc3, sfo3)"
  type        = string
}

variable "size" {
  description = "DB size slug (e.g., db-s-1vcpu-1gb)"
  type        = string
}

variable "engine_version" {
  description = "MySQL major version"
  type        = string
  default     = "8"
}

variable "node_count" {
  description = "Number of nodes for the DB cluster"
  type        = number
  default     = 1
}

variable "vpc_uuid" {
  description = "VPC UUID to attach the DB to (enables private networking)"
  type        = string
}

variable "db_name" {
  description = "Application database name to create"
  type        = string
}

variable "db_user" {
  description = "Application database user to create"
  type        = string
}

