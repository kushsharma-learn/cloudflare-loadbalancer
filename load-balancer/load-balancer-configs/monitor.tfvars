# ===========================================================================
#  Health-check MONITOR(S) for this load balancer.
#  Optional: empty this file and remove `monitor_key` in pools.tfvars to skip
#  health checks entirely.
# ===========================================================================
monitors = {
  http = {
    type           = "http" # http | https | tcp | udp_icmp | icmp_ping | smtp
    method         = "GET"
    path           = "/"
    port           = 80
    interval       = 60
    timeout        = 5
    retries        = 2
    expected_codes = "200"
  }
}
