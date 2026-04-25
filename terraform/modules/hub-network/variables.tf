variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "address_space" {
  description = "Hub VNet address space"
  type        = list(string)
}

variable "firewall_subnet_prefix" {
  description = "CIDR for AzureFirewallSubnet"
  type        = string
  default     = "10.0.1.0/26"
}

variable "bastion_subnet_prefix" {
  description = "CIDR for AzureBastionSubnet"
  type        = string
  default     = "10.0.2.0/26"
}

variable "management_subnet_prefix" {
  description = "CIDR for management subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "firewall_private_ip" {
  description = "Private IP of the Azure Firewall for UDR next hop"
  type        = string
}

variable "vm_size" {
  description = "Size of the management test VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
