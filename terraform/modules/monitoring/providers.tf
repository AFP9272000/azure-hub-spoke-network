terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}
