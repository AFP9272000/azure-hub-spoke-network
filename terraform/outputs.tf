output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "hub_vnet_id" {
  description = "ID of the hub VNet"
  value       = module.hub_network.vnet_id
}

output "firewall_private_ip" {
  description = "Private IP of the Azure Firewall"
  value       = module.firewall.firewall_private_ip
}

output "firewall_public_ip" {
  description = "Public IP of the Azure Firewall"
  value       = module.firewall.firewall_public_ip
}

#output "front_door_endpoint" {
#  description = "Front Door endpoint hostname"
#  value       = module.front_door.front_door_endpoint_hostname
#}

#output "app_service_hostname" {
#  description = "App Service default hostname"
#  value       = module.app_service.app_service_hostname
#}

output "log_analytics_workspace" {
  description = "Log Analytics workspace name"
  value       = module.monitoring.log_analytics_workspace_name
}

output "storage_private_endpoint_ip" {
  description = "Private IP of the storage private endpoint"
  value       = module.storage.private_endpoint_ip
}
