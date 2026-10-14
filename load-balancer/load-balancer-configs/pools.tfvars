# ===========================================================================
#  Origin POOLS and their ORIGINS (your backend servers).
#
#  Using PRIVATE IPs? Set virtual_network_id on each origin to the Cloudflare
#  virtual network (Magic WAN / Tunnel) that can reach those internal IPs.
#  Find it in the dashboard, or:  cloudflared tunnel vnet list
#  For PUBLIC IPs/hostnames, remove the virtual_network_id line.
# ===========================================================================
pools = {
  main = {
    name            = "xxxx-pool-name" # must be unique within your account
    minimum_origins = 1
    monitor_key     = "http" # references a key in monitor.tfvars

    origins = [
      {
        name               = "origin-1"
        address            = "10.0.0.10" # private IP of your backend
        port               = 80
        weight             = 1
        virtual_network_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # required for private IPs
      },
      {
        name               = "origin-2"
        address            = "10.0.0.11"
        port               = 80
        weight             = 1
        virtual_network_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      },
    ]
  }
}
