# ===========================================================================
#  Load balancer SETTINGS.
#
#  To create a new load balancer, copy this whole "load-balancer-configs"
#  folder to a new name (that name becomes the load balancer's id), e.g.:
#      cp -r load-balancer-configs acme
#  then fill in acme/settings.tfvars, acme/pools.tfvars, acme/monitor.tfvars.
# ===========================================================================

# ---- WHERE (required) ----
account_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Cloudflare Account ID
zone_id    = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # Zone ID of the domain below

# ---- LOAD BALANCER SETTINGS (required) ----
load_balancer = {
  name    = "lb.example.com" # the public hostname to serve
  proxied = true             # true = proxied/orange-cloud | false = DNS-only

  # off | random | geo | dynamic_latency | proximity | least_outstanding_requests | least_connections
  steering_policy = "random"

  # none | cookie | ip_cookie | header   (requires proxied = true)
  session_affinity = "none"

  default_pool_keys = ["main"] # keys from pools.tfvars, in priority order
  fallback_pool_key = "main"   # used when everything else is unhealthy
}
