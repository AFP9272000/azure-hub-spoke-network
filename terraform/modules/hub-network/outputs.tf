output "vnet_id" {
  description = "ID of the hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_name" {
  description = "Name of the hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  value       = azurerm_subnet.firewall.id
}

output "bastion_subnet_id" {
  description = "ID of the AzureBastionSubnet"
  value       = azurerm_subnet.bastion.id
}

output "management_subnet_id" {
  description = "ID of the management subnet"
  value       = azurerm_subnet.management.id
}

output "nsg_mgmt_id" {
  description = "ID of the management NSG"
  value       = azurerm_network_security_group.management.id
}

output "bastion_id" {
  description = "ID of the Bastion Host"
  value       = azurerm_bastion_host.hub.id
}
