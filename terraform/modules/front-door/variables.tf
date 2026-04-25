variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "front_door_name" {
  description = "Name for the Front Door profile"
  type        = string
}

variable "waf_policy_name" {
  description = "Name for the WAF policy"
  type        = string
}

variable "app_service_hostname" {
  description = "Default hostname of the App Service origin"
  type        = string
}

variable "geo_block_countries" {
  description = "Country codes to block via geo-filtering"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
