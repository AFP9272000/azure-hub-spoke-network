# Storage Account
resource "azurerm_storage_account" "data" {
  name                     = var.storage_account_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false
  tags                     = var.tags
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# DNS Zone VNet Links
resource "azurerm_private_dns_zone_virtual_network_link" "blob_links" {
  for_each              = var.vnet_ids_for_dns
  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = each.value
  registration_enabled  = false
}

# Private Endpoint
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-data"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-data"
    private_connection_resource_id = azurerm_storage_account.data.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
