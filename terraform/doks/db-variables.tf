############################################################
# Root: db-variables.tf — DB toggles and per-zone params
############################################################

variable "enable_db_pz" {
  description = "Create Managed MySQL in Primary Zone (nyc3)"
  type        = bool
  default     = false
}

variable "enable_db_bz" {
  description = "Create Managed MySQL in Backup Zone (sfo3)"
  type        = bool
  default     = false
}

variable "db_pz" {
  description = "DB config for Primary Zone (PZ)"
  type = object({
    region         = string
    name           = string
    size           = string
    engine_version = string
    node_count     = number
    db_name        = string
    db_user        = string
  })
  default = {
    region         = "nyc3"
    name           = "wp-pz-db"
    size           = "db-s-1vcpu-1gb"
    engine_version = "8"
    node_count     = 1
    db_name        = "wp_prod"
    db_user        = "wp_app"
  }
}

variable "db_bz" {
  description = "DB config for Backup Zone (BZ)"
  type = object({
    region         = string
    name           = string
    size           = string
    engine_version = string
    node_count     = number
    db_name        = string
    db_user        = string
  })
  default = {
    region         = "sfo3"
    name           = "wp-bz-db"
    size           = "db-s-1vcpu-1gb"
    engine_version = "8"
    node_count     = 1
    db_name        = "wp_prod"
    db_user        = "wp_app"
  }
}

