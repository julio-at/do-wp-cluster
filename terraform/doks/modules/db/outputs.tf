############################################################
# Module: modules/db — outputs
############################################################

output "cluster_id" {
  value       = try(digitalocean_database_cluster.this[0].id, null)
  description = "DB cluster ID"
}

output "host" {
  value       = try(digitalocean_database_cluster.this[0].host, null)
  description = "Public host"
}

output "private_host" {
  value       = try(digitalocean_database_cluster.this[0].private_host, null)
  description = "Private host (VPC)"
}

output "port" {
  value       = try(digitalocean_database_cluster.this[0].port, null)
  description = "Port"
}

output "database" {
  value       = try(digitalocean_database_db.this[0].name, null)
  description = "Database name"
}

output "username" {
  value       = try(digitalocean_database_user.app[0].name, null)
  description = "Application user"
}

output "password" {
  value       = try(digitalocean_database_user.app[0].password, null)
  description = "Application user password"
  sensitive   = true
}

output "ca_cert" {
  value       = try(data.digitalocean_database_ca.ca[0].certificate, null)
  description = "PEM CA certificate (TLS)"
  sensitive   = true
}

