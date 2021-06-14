output "wg_server_ipv4_address" {
  value       = hcloud_server.wg_server.ipv4_address
  description = "IPv4 address"
}

output "wg_server_ipv6_address" {
  value       = hcloud_server.wg_server.ipv6_address
  description = "IPv6 address"
}
