provider "digitalocean" {
  # Usa el token desde la variable o desde la env var DIGITALOCEAN_TOKEN
  token = var.do_token != "" ? var.do_token : null
}

