variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique storage account name"
  type        = string
}

variable "data_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
}

variable "vnet_ids_for_dns" {
  description = "Map of VNet names to IDs for Private DNS Zone links"
  type        = map(string)
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
