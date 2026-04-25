variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name for the Log Analytics workspace"
  type        = string
}

variable "flow_logs_storage_name" {
  description = "Storage account name for flow logs"
  type        = string
  default     = "sthubspokeflowlogs"
}

variable "hub_vnet_id" {
  description = "ID of the hub VNet for flow logs"
  type        = string
}

variable "web_spoke_vnet_id" {
  description = "ID of the web spoke VNet for flow logs"
  type        = string
}

variable "data_spoke_vnet_id" {
  description = "ID of the data spoke VNet for flow logs"
  type        = string
}

variable "firewall_id" {
  description = "ID of the Azure Firewall for diagnostic settings"
  type        = string
}

# variable "front_door_id" {
#  description = "ID of the Front Door profile for diagnostic settings"
#  type        = string
#}

variable "alert_email" {
  description = "Email for alert notifications (empty to skip alerts)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
