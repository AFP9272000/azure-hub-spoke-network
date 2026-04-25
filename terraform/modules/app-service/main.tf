# --- App Service Plan ---
resource "azurerm_service_plan" "web" {
  name                = "asp-hubspoke-web"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "D1"
  tags                = var.tags
}

# --- Web App ---
resource "azurerm_linux_web_app" "web" {
  name                = var.app_service_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.web.id
  tags                = var.tags

  site_config {
    application_stack {
      node_version = "20-lts"
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
