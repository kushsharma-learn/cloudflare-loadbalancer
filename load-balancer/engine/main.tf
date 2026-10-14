# Plumbing. DO NOT EDIT.
#
# Builds ONE load balancer from the variables supplied by a single config
# folder's tfvars (settings.tfvars + pools.tfvars + monitor.tfvars). GitHub
# Actions loops over each config folder and runs Terraform once per load
# balancer, passing that folder's *.tfvars via -var-file and using a separate
# state file per load balancer.
module "load_balancer" {
  source = "../../modules/load-balancer"

  account_id    = var.account_id
  zone_id       = var.zone_id
  monitors      = var.monitors
  pools         = var.pools
  load_balancer = var.load_balancer
}

output "load_balancer_id" {
  description = "ID of the created load balancer."
  value       = module.load_balancer.load_balancer_id
}

output "load_balancer_hostname" {
  description = "Hostname served by the load balancer."
  value       = module.load_balancer.load_balancer_hostname
}
