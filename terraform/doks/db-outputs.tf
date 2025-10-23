############################################################
# Root: db-outputs.tf — Bubble up per-zone outputs
############################################################

output "db_pz" {
  description = "Managed DB outputs for PZ (nyc3)"
  value = {
    cluster_id   = module.db_pz.cluster_id
    host         = module.db_pz.host
    private_host = module.db_pz.private_host
    port         = module.db_pz.port
    database     = module.db_pz.database
    username     = module.db_pz.username
    password     = module.db_pz.password
    ca_cert      = module.db_pz.ca_cert
  }
  sensitive = true
}

output "db_bz" {
  description = "Managed DB outputs for BZ (sfo3)"
  value = {
    cluster_id   = module.db_bz.cluster_id
    host         = module.db_bz.host
    private_host = module.db_bz.private_host
    port         = module.db_bz.port
    database     = module.db_bz.database
    username     = module.db_bz.username
    password     = module.db_bz.password
    ca_cert      = module.db_bz.ca_cert
  }
  sensitive = true
}

