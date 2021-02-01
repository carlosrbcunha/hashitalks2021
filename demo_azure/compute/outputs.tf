output "vm_ips" {
  value       = azurerm_network_interface.generic-nic.*.private_ip_address
  description = "IP Address array of the created virtual machines"
}

output "private_ip" {
  description = "IP address of server"
  value       = azurerm_network_interface.generic-nic[*].private_ip_address
}

output "gateway_public_ip" {
  description = "IP address of gateway"
  value       = azurerm_public_ip.gateway-ip[*].ip_address
}

output "gateway_private_ip" {
  description = "IP address of gateway"
  value       = azurerm_network_interface.generic-nic-with-external-ip[*].private_ip_address
}