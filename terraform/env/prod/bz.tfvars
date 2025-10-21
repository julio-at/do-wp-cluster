region               = "sfo3"
cluster_name         = "wp-bz-doks-sfo3"
kubernetes_version   = ""        # vacío -> escogerá el último que haga match con kubernetes_minor_prefix
kubernetes_minor_prefix = "1.30"

node_size            = "s-2vcpu-4gb"
node_count           = 3

enable_autoscale     = true
min_nodes            = 3
max_nodes            = 6
vpc_cidr             = "10.20.0.0/16"

tags = [
  "project:wp",
  "env:prod",
  "zone:bz",
  "region:sfo3"
]

