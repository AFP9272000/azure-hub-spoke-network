# Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.front_door_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "web" {
  name                     = "hubspoke-web"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = var.tags
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "web" {
  name                     = "og-web-app"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 30
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }
}

# Origin
resource "azurerm_cdn_frontdoor_origin" "web_app" {
  name                          = "origin-app-hubspoke"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  enabled                       = true

  host_name          = var.app_service_hostname
  origin_host_header = var.app_service_hostname
  http_port          = 80
  https_port         = 443
  priority           = 1
  weight             = 1000

  certificate_name_check_enabled = true
}

# Route
resource "azurerm_cdn_frontdoor_route" "default" {
  name                          = "route-default"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.web.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.web.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.web_app.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  enabled                = true
}

# WAF Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                              = var.waf_policy_name
  resource_group_name               = var.resource_group_name
  sku_name                          = "Standard_AzureFrontDoor"
  mode                              = "Prevention"
  enabled                           = true
  tags                              = var.tags

  # Rate Limiting
  custom_rule {
    name     = "RateLimitPerIP"
    type     = "RateLimitRule"
    priority = 1
    action   = "Block"

    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 100

    match_condition {
      match_variable = "RequestUri"
      operator       = "Contains"
      match_values   = ["/"]
      transforms     = ["Lowercase"]
    }
  }

  # Geo-Filtering
  custom_rule {
    name     = "GeoBlock"
    type     = "MatchRule"
    priority = 2
    action   = "Block"

    match_condition {
      match_variable = "RemoteAddr"
      operator       = "GeoMatch"
      match_values   = var.geo_block_countries
    }
  }

  # Path Traversal / Bad Patterns in URI
  custom_rule {
    name     = "BlockKnownBadPatterns"
    type     = "MatchRule"
    priority = 3
    action   = "Block"

    match_condition {
      match_variable = "RequestUri"
      operator       = "Contains"
      match_values   = ["../", "etc/passwd", "<script>"]
      transforms     = ["UrlDecode", "Lowercase"]
    }
  }

  # SQL Injection in Query String
  custom_rule {
    name     = "BlockSQLInjection"
    type     = "MatchRule"
    priority = 4
    action   = "Block"

    match_condition {
      match_variable = "QueryString"
      operator       = "Contains"
      match_values   = ["' or", "1=1", "union select", "drop table", "--"]
      transforms     = ["UrlDecode", "Lowercase"]
    }
  }

  # XSS in Query String
  custom_rule {
    name     = "BlockXSS"
    type     = "MatchRule"
    priority = 5
    action   = "Block"

    match_condition {
      match_variable = "QueryString"
      operator       = "Contains"
      match_values   = ["<script>", "javascript:", "onerror="]
      transforms     = ["UrlDecode", "Lowercase"]
    }
  }
}

# Security Policy (WAF <-> Endpoint association)
resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  name                     = "secpol-waf"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id

      association {
        patterns_to_match = ["/*"]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.web.id
        }
      }
    }
  }
}
