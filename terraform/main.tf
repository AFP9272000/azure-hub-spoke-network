# --- Resource Group ---
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# --- Firewall (deployed first to get private IP for UDRs) ---
module "firewall" {
  source = "./modules/firewall"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  firewall_subnet_id       = module.hub_network.firewall_subnet_id
  firewall_sku_tier        = var.firewall_sku_tier
  hub_address_prefix       = var.hub_vnet_address_space[0]
  web_spoke_address_prefix = var.web_spoke_address_space[0]
  data_spoke_address_prefix = var.data_spoke_address_space[0]
  web_vm_private_ip        = "10.1.1.4"
  tags                     = var.tags

  depends_on = [module.hub_network]
}

# --- Hub Network ---
module "hub_network" {
  source = "./modules/hub-network"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  address_space            = var.hub_vnet_address_space
  firewall_private_ip      = "10.0.1.4" # Known default for first IP in AzureFirewallSubnet
  ssh_public_key           = var.ssh_public_key
  tags                     = var.tags
}

# --- Web Spoke ---
module "spoke_web" {
  source = "./modules/spoke-network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  spoke_name          = "web"
  address_space       = var.web_spoke_address_space
  subnet_prefix       = "10.1.1.0/24"
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  firewall_private_ip = module.firewall.firewall_private_ip
  deploy_test_vm      = true
  ssh_public_key           = var.ssh_public_key
  tags                = var.tags

  depends_on = [module.firewall]
}

# --- Data Spoke ---
module "spoke_data" {
  source = "./modules/spoke-network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  spoke_name          = "data"
  address_space       = var.data_spoke_address_space
  subnet_prefix       = "10.2.1.0/24"
  hub_vnet_id         = module.hub_network.vnet_id
  hub_vnet_name       = module.hub_network.vnet_name
  firewall_private_ip = module.firewall.firewall_private_ip
  deploy_test_vm      = false
  tags                = var.tags

  depends_on = [module.firewall]
}

# --- Storage (Data Tier) ---
module "storage" {
  source = "./modules/storage"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  storage_account_name = var.storage_account_name
  data_subnet_id       = module.spoke_data.subnet_id
  vnet_ids_for_dns = {
    hub  = module.hub_network.vnet_id
    web  = module.spoke_web.vnet_id
    data = module.spoke_data.vnet_id
  }
  tags = var.tags

  depends_on = [module.spoke_data]
}

# --- App Service (Web Tier) ---
# module "app_service" {
#  source = "./modules/app-service"
#
#  resource_group_name = azurerm_resource_group.main.name
#  location            = azurerm_resource_group.main.location
#  app_service_name    = var.app_service_name
#  tags                = var.tags
#}

# --- Front Door + WAF ---
# module "front_door" {
#  source = "./modules/front-door"
#
#  resource_group_name  = azurerm_resource_group.main.name
#  front_door_name      = var.front_door_name
#  waf_policy_name      = var.waf_policy_name
#  app_service_hostname = module.app_service.app_service_hostname
#  geo_block_countries  = var.geo_block_countries
#  tags                 = var.tags
#
#  depends_on = [module.app_service]
#}

# --- Monitoring ---
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  log_analytics_workspace_name = var.log_analytics_workspace_name
  hub_vnet_id                  = module.hub_network.vnet_id
  web_spoke_vnet_id            = module.spoke_web.vnet_id
  data_spoke_vnet_id           = module.spoke_data.vnet_id
  firewall_id                  = module.firewall.firewall_id
  alert_email                  = var.alert_email
  tags                         = var.tags

  depends_on = [module.firewall]
}
