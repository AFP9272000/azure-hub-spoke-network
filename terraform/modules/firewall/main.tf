# Firewall Public IP
resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                     = "fw-policy-hub"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Deny"
  tags                     = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "fw-hub"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Application Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "application" {
  name               = "DefaultApplicationRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  application_rule_collection {
    name     = "app-rules-baseline"
    priority = 200
    action   = "Allow"

    rule {
      name = "allow-azure-updates"
      source_addresses = [var.hub_address_prefix]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "*.ubuntu.com",
        "*.microsoft.com",
        "*.azure.com"
      ]
    }
  }

  application_rule_collection {
    name     = "app-rules-outbound"
    priority = 300
    action   = "Allow"

    rule {
      name = "allow-web-spoke-outbound"
      source_addresses = [var.web_spoke_address_prefix]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com",
        "*.ubuntu.com",
        "*.docker.io",
        "*.github.com",
        "github.com"
      ]
    }

    rule {
      name = "allow-data-spoke-limited"
      source_addresses = [var.data_spoke_address_prefix]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com"
      ]
    }
  }
}

# Network Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  network_rule_collection {
    name     = "net-rules-baseline"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-dns"
      source_addresses      = [var.hub_address_prefix]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
      protocols             = ["TCP", "UDP"]
    }
  }

  network_rule_collection {
    name     = "net-rules-web-to-data"
    priority = 200
    action   = "Allow"

    rule {
      name                  = "allow-web-to-sql"
      source_addresses      = [var.web_spoke_address_prefix]
      destination_addresses = [var.data_spoke_address_prefix]
      destination_ports     = ["1433"]
      protocols             = ["TCP"]
    }

    rule {
      name                  = "allow-web-to-storage"
      source_addresses      = [var.web_spoke_address_prefix]
      destination_addresses = [var.data_spoke_address_prefix]
      destination_ports     = ["443"]
      protocols             = ["TCP"]
    }
  }

  network_rule_collection {
    name     = "net-rules-deny-spoke-to-spoke"
    priority = 300
    action   = "Deny"

    rule {
      name                  = "deny-data-to-web"
      source_addresses      = [var.data_spoke_address_prefix]
      destination_addresses = [var.web_spoke_address_prefix]
      destination_ports     = ["*"]
      protocols             = ["Any"]
    }
  }
}

# DNAT Rule Collection Group
resource "azurerm_firewall_policy_rule_collection_group" "dnat" {
  name               = "DefaultDnatRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  nat_rule_collection {
    name     = "nat-rules-inbound"
    priority = 100
    action   = "Dnat"

    rule {
      name                = "dnat-web-http"
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["80"]
      translated_address  = var.web_vm_private_ip
      translated_port     = "80"
      protocols           = ["TCP"]
    }
  }
}
