variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "spoke_name" {
  description = "Name identifier for the spoke (e.g., 'web', 'data')"
  type        = string
}

variable "address_space" {
  description = "Address space for the spoke VNet"
  type        = list(string)
}

variable "subnet_prefix" {
  description = "CIDR for the spoke subnet"
  type        = string
}

variable "hub_vnet_id" {
  description = "ID of the hub VNet for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet for peering"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of the Azure Firewall for UDR next hop"
  type        = string
}

variable "deploy_test_vm" {
  description = "Whether to deploy a test VM in this spoke"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "Size of the test VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
