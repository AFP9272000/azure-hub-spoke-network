terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sthubspoketerraform"
    container_name       = "tfstate"
    key                  = "hub-spoke-network.tfstate"
    use_oidc             = true
  }
}
