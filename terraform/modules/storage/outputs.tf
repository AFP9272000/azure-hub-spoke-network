output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.data.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.data.name
}

output "private_endpoint_ip" {
  description = "Private IP of the storage private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "private_dns_zone_id" {
  description = "ID of the blob private DNS zone"
  value       = azurerm_private_dns_zone.blob.id
}
