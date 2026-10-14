output "load_balancer_id" {
  description = "ID of the created load balancer."
  value       = cloudflare_load_balancer.lb.id
}

output "load_balancer_hostname" {
  description = "Hostname served by the load balancer."
  value       = cloudflare_load_balancer.lb.name
}

output "pool_ids" {
  description = "Map of logical pool key to generated pool ID."
  value       = { for k, p in cloudflare_load_balancer_pool.pool : k => p.id }
}

output "monitor_ids" {
  description = "Map of logical monitor key to generated monitor ID."
  value       = { for k, m in cloudflare_load_balancer_monitor.monitor : k => m.id }
}
