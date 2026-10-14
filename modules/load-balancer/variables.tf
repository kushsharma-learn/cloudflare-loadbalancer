# ===========================================================================
# cloudflare-load-balancer module inputs
# ---------------------------------------------------------------------------
# How to read this file:
#   * Every field has a description (shown by `terraform` tooling).
#   * Inline comments list the ALLOWED VALUES you can copy/paste.
#   * `optional(...)` fields can be omitted; the value in parentheses is the
#     default that will be used if you leave the field out.
# ===========================================================================


# ---------------------------------------------------------------------------
# 1. IDENTIFIERS (where the resources live)
# ---------------------------------------------------------------------------
variable "account_id" {
  description = "Cloudflare Account ID. Owns the account-scoped monitors and pools. Find it in: Dashboard > any zone > Overview (right sidebar), or Manage Account > Account ID."
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID of the domain where the load balancer hostname lives. Find it in: Dashboard > <your domain> > Overview (right sidebar)."
  type        = string
}


# ---------------------------------------------------------------------------
# 2. MONITORS  (account-scoped health checks, keyed by a logical name)
#    The key you give each monitor (e.g. "http") is referenced later from a
#    pool via `monitor_key`.
# ---------------------------------------------------------------------------
variable "monitors" {
  description = "Health-check monitors to create, keyed by a logical name of your choice."
  type = map(object({
    # Free-text label shown in the dashboard.
    description = optional(string, "")

    # Protocol used to probe origins.
    # Allowed: "http" | "https" | "tcp" | "udp_icmp" | "icmp_ping" | "smtp"
    type = optional(string, "http")

    # HTTP(S) request method. Common: "GET" | "HEAD"
    # (TCP checks use "connection_established")
    method = optional(string, "GET")

    # Path to probe (HTTP/HTTPS only). e.g. "/" | "/health" | "/status"
    path = optional(string, "/")

    # Port to connect to. HTTP default 80, HTTPS default 443. Required for TCP/UDP/SMTP.
    # e.g. 80 | 443 | 8080
    port = optional(number)

    # Seconds between checks. e.g. 15 | 30 | 60
    interval = optional(number, 60)

    # Seconds to wait before a probe is considered failed. e.g. 3 | 5 | 10
    timeout = optional(number, 5)

    # Retries before marking an origin unhealthy. e.g. 1 | 2 | 3
    retries = optional(number, 2)

    # Expected HTTP response code or range (HTTP/HTTPS only).
    # e.g. "200" | "2xx" | "200-299"
    expected_codes = optional(string, "200")

    # Case-insensitive substring expected in the body (HTTP/HTTPS). "" = not checked.
    expected_body = optional(string, "")

    # Follow 3xx redirects (HTTP/HTTPS only). true | false
    follow_redirects = optional(bool, false)

    # Skip TLS certificate validation (HTTPS only). true | false
    allow_insecure = optional(bool, false)

    # Extra request headers, e.g. { Host = ["example.com"] }. null = none.
    header = optional(map(list(string)))
  }))
  default = {}
}


# ---------------------------------------------------------------------------
# 3. POOLS  (account-scoped groups of origins, keyed by a logical name)
#    The key you give each pool (e.g. "delhi") is referenced later from the
#    load balancer via `default_pool_keys` / `fallback_pool_key`.
# ---------------------------------------------------------------------------
variable "pools" {
  description = "Origin pools to create, keyed by a logical name of your choice."
  type = map(object({
    # Pool name. MUST be unique across the whole account.
    # Only letters, numbers, hyphens and underscores. e.g. "delhi-pool"
    name = string

    # Whether the pool can receive traffic. true | false
    enabled = optional(bool, true)

    # Healthy origins required before the pool serves traffic. e.g. 1 | 2
    minimum_origins = optional(number, 1)

    # Free-text label.
    description = optional(string, "")

    # Key of the monitor (from var.monitors) to health-check this pool. null = no health check.
    monitor_key = optional(string)

    # Regions to run health checks from. null = all Cloudflare data centers.
    # Copy the ones you need, e.g. ["WNAM", "ENAM"] or ["ALL_REGIONS"].
    # Allowed: "ALL_REGIONS" | "WNAM" | "ENAM" | "WEU" | "EEU" | "NSAM" |
    #          "SSAM" | "OC" | "ME" | "NAF" | "SAF" | "SAS" | "SEAS" |
    #          "NEAS"
    check_regions = optional(list(string))

    # Deprecated by Cloudflare (use Notifications). Comma-separated emails or "".
    notification_email = optional(string)

    # The backend servers in this pool.
    origins = list(object({
      # Human label for the origin. e.g. "web-server-1"
      name = string

      # IPv4/IPv6 or publicly-resolvable hostname of the origin.
      # For internal/reserved IPs you MUST also set virtual_network_id.
      # e.g. "203.0.113.10" | "origin.example.com" | "10.0.0.10" (internal)
      address = string

      # Whether this origin receives traffic. true | false
      enabled = optional(bool, true)

      # Relative traffic weight. 0.0 - 1.0 (or any positive number). e.g. 1 | 0.6
      weight = optional(number, 1)

      # Upstream port. 0 or null = default for the protocol. e.g. 80 | 443
      port = optional(number)

      # Required ONLY for internal/reserved addresses (Magic WAN / Tunnel virtual network).
      # e.g. "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx". null for public origins.
      virtual_network_id = optional(string)

      # Resolve CNAME to A/AAAA before returning. true | false
      flatten_cname = optional(bool)

      # Override the Host header sent to this origin, e.g. ["example.com"]. null = none.
      header_host = optional(list(string))
    }))
  }))
}


# ---------------------------------------------------------------------------
# 4. LOAD BALANCER  (zone-scoped; ties a hostname to the pools above)
# ---------------------------------------------------------------------------
variable "load_balancer" {
  description = "The zone-scoped load balancer definition (the hostname + steering behaviour)."
  type = object({
    # The DNS hostname the load balancer answers on. e.g. "lb.example.com"
    name = string

    # Free-text label.
    description = optional(string, "")

    # Turn the load balancer on/off. true | false
    enabled = optional(bool, true)

    # Orange-cloud (proxied through Cloudflare) vs grey-cloud (DNS only).
    # true  = proxied (required for session affinity, WAF, etc.)
    # false = DNS-only
    proxied = optional(bool, true)

    # How a pool is chosen for each request.
    # Allowed:
    #   "off"                        -> always use default_pools in order
    #   "random"                     -> pick a pool at random (use random_steering_default_weight)
    #   "geo"                        -> use region/country/pop pool maps
    #   "dynamic_latency"            -> closest pool by round-trip time (needs health checks)
    #   "proximity"                  -> closest pool by lat/long
    #   "least_outstanding_requests" -> pool with fewest in-flight requests
    #   "least_connections"          -> pool with fewest open connections
    steering_policy = optional(string, "off")

    # ---- Session affinity (sticky sessions) -------------------------------
    # Keeps a client pinned to the same origin. Requires proxied = true.
    # Allowed:
    #   "none"      -> no stickiness (default)
    #   "cookie"    -> Cloudflare sets a cookie choosing the origin
    #   "ip_cookie" -> like cookie, but first origin chosen by client IP
    #   "header"    -> stickiness keyed on request headers (set session_affinity_attributes.headers)
    session_affinity = optional(string, "none")

    # Seconds until a client's session expires.
    #   cookie / ip_cookie: 1800 - 604800 (default ~23h)
    #   header:             30 - 3600     (default 1800)
    # Leave null to use Cloudflare's default.
    session_affinity_ttl = optional(number)

    # Fine-grained session affinity settings. Leave null unless session_affinity != "none".
    session_affinity_attributes = optional(object({
      # Seconds to keep draining existing sessions to an origin marked unhealthy. e.g. 0 | 60 | 100
      drain_duration = optional(number)

      # Required when session_affinity = "header". Header names to key the session on, e.g. ["x-session-id"].
      headers = optional(list(string))

      # "header" only: require ALL listed headers to match. true | false
      require_all_headers = optional(bool)

      # SameSite attribute for the affinity cookie.
      # Allowed: "Auto" | "Lax" | "None" | "Strict"
      samesite = optional(string)

      # Secure attribute for the affinity cookie.
      # Allowed: "Auto" | "Always" | "Never"
      secure = optional(string)

      # Behaviour if the pinned origin becomes unhealthy.
      # Allowed: "none" | "temporary" | "sticky"
      zero_downtime_failover = optional(string)
    }))
    # -----------------------------------------------------------------------

    # Pools used by default, ordered by failover priority. Values are KEYS from var.pools.
    # e.g. ["delhi"] or ["primary", "secondary"]
    default_pool_keys = list(string)

    # Pool used when every other pool is unhealthy. A KEY from var.pools. e.g. "delhi"
    fallback_pool_key = string

    # Networks the load balancer runs on. Usually ["cloudflare"]. null = default.
    networks = optional(list(string))

    # Retry one healthy origin in the same pool on 521/522/523 between health checks.
    # true | false | null (omit)
    adaptive_routing_failover_across_pools = optional(bool)

    # Only used when steering_policy = "random". Weight applied to pools with no explicit weight.
    # e.g. 1 | 0.5. null to omit.
    random_steering_default_weight = optional(number)

    # Controls geo steering for NON-proxied (DNS-only) requests. Omit (null) if proxied.
    location_strategy = optional(object({
      # How the client location is determined.
      # Allowed: "pop" (Cloudflare PoP) | "resolver_ip" (client DNS resolver IP)
      mode = optional(string)

      # Whether to prefer the EDNS client subnet when present.
      # Allowed: "always" | "never" | "proximity" | "geo"
      prefer_ecs = optional(string)
    }))
  })
}
