output "app_service_id" {
  description = "ID of the web app"
  value       = azurerm_linux_web_app.web.id
}

output "app_service_hostname" {
  description = "Default hostname of the web app"
  value       = azurerm_linux_web_app.web.default_hostname
}

output "app_service_name" {
  description = "Name of the web app"
  value       = azurerm_linux_web_app.web.name
}
