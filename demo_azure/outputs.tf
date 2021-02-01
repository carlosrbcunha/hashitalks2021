output "nomad_server" {
  description = "Ip address of Nomad Server"
  value       = module.nomad-server.private_ip
}

output "nomad_clients" {
  description = "IP address of Nomad Clients"
  value       = module.nomad-client[*].private_ip
}

output "gateway_ip_address" {
  description = "Ip address of Gateway"
  value       = module.nomad-server.gateway_public_ip
}