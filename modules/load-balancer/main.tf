# ===========================================================================
# MONITOR — account-scoped health check(s).
# Periodically probes each origin so pools know which origins are healthy.
# One instance is created per entry in var.monitors (keyed by its logical name).
# ===========================================================================
resource "cloudflare_load_balancer_monitor" "monitor" {
  for_each = var.monitors

  account_id       = var.account_id
  description      = each.value.description
  type             = each.value.type
  method           = each.value.method
  path             = each.value.path
  port             = each.value.port
  interval         = each.value.interval
  timeout          = each.value.timeout
  retries          = each.value.retries
  expected_codes   = each.value.expected_codes
  expected_body    = each.value.expected_body
  follow_redirects = each.value.follow_redirects
  allow_insecure   = each.value.allow_insecure
  header           = each.value.header
}

# ===========================================================================
# POOL — account-scoped group of origin servers.
# Traffic sent to a pool is balanced across its healthy origins. Each pool
# can reference a monitor (via monitor_key) for health checking.
# One instance is created per entry in var.pools (keyed by its logical name).
# ===========================================================================
resource "cloudflare_load_balancer_pool" "pool" {
  for_each = var.pools

  account_id         = var.account_id
  name               = each.value.name
  enabled            = each.value.enabled
  minimum_origins    = each.value.minimum_origins
  description        = each.value.description
  check_regions      = each.value.check_regions
  notification_email = each.value.notification_email

  # Wire the pool to its monitor by the logical key given in var.monitors.
  monitor = each.value.monitor_key != null ? cloudflare_load_balancer_monitor.monitor[each.value.monitor_key].id : null

  # The backend servers that make up this pool.
  origins = [
    for o in each.value.origins : {
      name               = o.name
      address            = o.address
      enabled            = o.enabled
      weight             = o.weight
      port               = o.port
      virtual_network_id = o.virtual_network_id
      flatten_cname      = o.flatten_cname
      header             = o.header_host != null ? { host = o.header_host } : null
    }
  ]
}

# ===========================================================================
# LOAD BALANCER — zone-scoped. Binds a DNS hostname to the pools above and
# decides which pool/origin serves each request (steering + session affinity).
# Exactly one is created per module instance.
# ===========================================================================
resource "cloudflare_load_balancer" "lb" {
  zone_id         = var.zone_id
  name            = var.load_balancer.name
  description     = var.load_balancer.description
  enabled         = var.load_balancer.enabled
  proxied         = var.load_balancer.proxied
  steering_policy = var.load_balancer.steering_policy
  networks        = var.load_balancer.networks

  # ---- Session affinity (sticky sessions) ----
  session_affinity            = var.load_balancer.session_affinity
  session_affinity_ttl        = var.load_balancer.session_affinity_ttl
  session_affinity_attributes = var.load_balancer.session_affinity_attributes

  # Resolve pool logical keys (from var.pools) into their generated IDs.
  default_pools = [for k in var.load_balancer.default_pool_keys : cloudflare_load_balancer_pool.pool[k].id]
  fallback_pool = cloudflare_load_balancer_pool.pool[var.load_balancer.fallback_pool_key].id

  adaptive_routing = var.load_balancer.adaptive_routing_failover_across_pools != null ? {
    failover_across_pools = var.load_balancer.adaptive_routing_failover_across_pools
  } : null

  random_steering = var.load_balancer.random_steering_default_weight != null ? {
    default_weight = var.load_balancer.random_steering_default_weight
  } : null

  location_strategy = var.load_balancer.location_strategy
}

# ===========================================================================
# STATE MIGRATION — these blocks rename the resources from the old "this"
# label to the new descriptive labels WITHOUT destroying/recreating the live
# infrastructure. Safe to remove after one successful apply.
# ===========================================================================
moved {
  from = cloudflare_load_balancer_monitor.this
  to   = cloudflare_load_balancer_monitor.monitor
}

moved {
  from = cloudflare_load_balancer_pool.this
  to   = cloudflare_load_balancer_pool.pool
}

moved {
  from = cloudflare_load_balancer.this
  to   = cloudflare_load_balancer.lb
}
