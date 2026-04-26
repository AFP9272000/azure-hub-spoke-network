variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "hub-spoke-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "hub_vnet_address_space" {
  description = "Address space for the hub VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "web_spoke_address_space" {
  description = "Address space for the web spoke VNet"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "data_spoke_address_space" {
  description = "Address space for the data spoke VNet"
  type        = list(string)
  default     = ["10.2.0.0/16"]
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "storage_account_name" {
  description = "Globally unique name for the data tier storage account"
  type        = string
  default     = "sthubspokedata"
}

#variable "app_service_name" {
#  description = "Globally unique name for the web app"
#  type        = string
#  default     = "app-hubspoke-web"
#}

#variable "front_door_name" {
# description = "Name for the Front Door profile"
#  type        = string
#  default     = "fd-hubspoke"
#}

#variable "waf_policy_name" {
#  description = "Name for the WAF policy"
#  type        = string
#  default     = "wafpolicyhubspoke"
#}

variable "log_analytics_workspace_name" {
  description = "Name for the Log Analytics workspace"
  type        = string
  default     = "law-hub-spoke"
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}

#variable "geo_block_countries" {
#  description = "List of country codes to block via WAF geo-filtering"
#  type        = list(string)
#  default     = ["CN", "RU", "KP", "IR"]
#}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Hub-Spoke-Network"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}
variable "ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  sensitive   = true
 }
