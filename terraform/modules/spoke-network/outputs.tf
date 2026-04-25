output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_id" {
  description = "ID of the spoke subnet"
  value       = azurerm_subnet.spoke.id
}

output "nsg_id" {
  description = "ID of the spoke NSG"
  value       = azurerm_network_security_group.spoke.id
}

output "vm_private_ip" {
  description = "Private IP of the test VM (if deployed)"
  value       = var.deploy_test_vm ? azurerm_network_interface.vm[0].private_ip_address : null
}
