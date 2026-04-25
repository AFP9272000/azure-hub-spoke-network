variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "firewall_sku_tier" {
  description = "SKU tier for Azure Firewall"
  type        = string
  default     = "Standard"
}

variable "hub_address_prefix" {
  description = "Hub VNet CIDR for firewall rules"
  type        = string
  default     = "10.0.0.0/16"
}

variable "web_spoke_address_prefix" {
  description = "Web spoke VNet CIDR for firewall rules"
  type        = string
  default     = "10.1.0.0/16"
}

variable "data_spoke_address_prefix" {
  description = "Data spoke VNet CIDR for firewall rules"
  type        = string
  default     = "10.2.0.0/16"
}

variable "web_vm_private_ip" {
  description = "Private IP of the web spoke test VM for DNAT rule"
  type        = string
  default     = "10.1.1.4"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
