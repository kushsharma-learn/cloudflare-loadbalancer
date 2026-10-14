# Plumbing. DO NOT EDIT.
# These inputs are populated by a load-balancer-config folder's tfvars:
#   settings.tfvars -> account_id, zone_id, load_balancer
#   pools.tfvars    -> pools
#   monitor.tfvars  -> monitors
# The full shape/validation lives in modules/load-balancer/variables.tf.

variable "account_id" {
  description = "Cloudflare Account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID of the domain the load balancer serves."
  type        = string
}

variable "monitors" {
  description = "Health-check monitors."
  type        = any
  default     = {}
}

variable "pools" {
  description = "Origin pools (your backend servers)."
  type        = any
}

variable "load_balancer" {
  description = "The load balancer definition (hostname, steering, affinity, pools)."
  type        = any
}
