output "firewall_id" {
  description = "ID of the Azure Firewall"
  value       = azurerm_firewall.hub.id
}

output "firewall_private_ip" {
  description = "Private IP address of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP address of the Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}

output "firewall_policy_id" {
  description = "ID of the Firewall Policy"
  value       = azurerm_firewall_policy.hub.id
}
