# --- Log Analytics Workspace ---
resource "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# --- Storage Account for Flow Logs ---
resource "azurerm_storage_account" "flow_logs" {
  name                     = var.flow_logs_storage_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# --- Network Watcher (uses existing) ---
data "azurerm_network_watcher" "main" {
  name                = "NetworkWatcher_${var.location}"
  resource_group_name = "NetworkWatcherRG"
}

# --- VNet Flow Logs (using AzAPI for VNet-level flow logs) ---
resource "azapi_resource" "flowlog_hub" {
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "flowlog-vnet-hub"
  location  = var.location
  parent_id = data.azurerm_network_watcher.main.id
  tags      = var.tags

  body = jsonencode({
    properties = {
      targetResourceId = var.hub_vnet_id
      storageId        = azurerm_storage_account.flow_logs.id
      enabled          = true
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        enabled = true
        days    = 30
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceResourceId      = azurerm_log_analytics_workspace.main.id
          workspaceId              = azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.location
          trafficAnalyticsInterval = 10
        }
      }
    }
  })
}

resource "azapi_resource" "flowlog_spoke_web" {
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "flowlog-vnet-spoke-web"
  location  = var.location
  parent_id = data.azurerm_network_watcher.main.id
  tags      = var.tags

  body = jsonencode({
    properties = {
      targetResourceId = var.web_spoke_vnet_id
      storageId        = azurerm_storage_account.flow_logs.id
      enabled          = true
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        enabled = true
        days    = 30
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceResourceId      = azurerm_log_analytics_workspace.main.id
          workspaceId              = azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.location
          trafficAnalyticsInterval = 10
        }
      }
    }
  })
}

resource "azapi_resource" "flowlog_spoke_data" {
  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "flowlog-vnet-spoke-data"
  location  = var.location
  parent_id = data.azurerm_network_watcher.main.id
  tags      = var.tags

  body = jsonencode({
    properties = {
      targetResourceId = var.data_spoke_vnet_id
      storageId        = azurerm_storage_account.flow_logs.id
      enabled          = true
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        enabled = true
        days    = 30
      }
      flowAnalyticsConfiguration = {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled                  = true
          workspaceResourceId      = azurerm_log_analytics_workspace.main.id
          workspaceId              = azurerm_log_analytics_workspace.main.workspace_id
          workspaceRegion          = var.location
          trafficAnalyticsInterval = 10
        }
      }
    }
  })
}

# --- Firewall Diagnostic Settings ---
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "fw-diag"
  target_resource_id         = var.firewall_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  enabled_log {
    category = "AZFWNatRule"
  }

  enabled_log {
    category = "AZFWThreatIntel"
  }

  metric {
    category = "AllMetrics"
  }
}

# --- Front Door Diagnostic Settings ---
# resource "azurerm_monitor_diagnostic_setting" "front_door" {
#  name                       = "fd-diag"
#  target_resource_id         = var.front_door_id
#  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
#
#  enabled_log {
#    category = "FrontDoorAccessLog"
#  }
#
#  enabled_log {
#    category = "FrontDoorHealthProbeLog"
#  }
#
#  enabled_log {
#    category = "FrontDoorWebApplicationFirewallLog"
#  }
#
#  metric {
#    category = "AllMetrics"
#  }
#}

# --- Action Group for Alerts ---
resource "azurerm_monitor_action_group" "alerts" {
  count               = var.alert_email != "" ? 1 : 0
  name                = "ag-hub-spoke-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "hubspoke"
  tags                = var.tags

  email_receiver {
    name          = "admin-email"
    email_address = var.alert_email
  }
}

# --- Alert: Firewall Denied Traffic Spike ---
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "denied_traffic_spike" {
  count               = var.alert_email != "" ? 1 : 0
  name                = "alert-denied-traffic-spike"
  location            = var.location
  resource_group_name = var.resource_group_name
  severity            = 2
  window_duration     = "PT5M"
  evaluation_frequency = "PT5M"
  tags                = var.tags

  scopes = [azurerm_log_analytics_workspace.main.id]

  criteria {
    query = <<-QUERY
      AzureDiagnostics
      | where Category == "AzureFirewallNetworkRule" or Category == "AzureFirewallApplicationRule"
      | where msg_s has "Deny"
      | summarize DeniedCount = count() by bin(TimeGenerated, 5m)
      | where DeniedCount > 50
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.alerts[0].id]
  }
}

# --- Alert: WAF Blocks Spike ---
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "waf_blocks_spike" {
  count               = var.alert_email != "" ? 1 : 0
  name                = "alert-waf-blocks-spike"
  location            = var.location
  resource_group_name = var.resource_group_name
  severity            = 2
  window_duration     = "PT5M"
  evaluation_frequency = "PT5M"
  tags                = var.tags

  scopes = [azurerm_log_analytics_workspace.main.id]

  criteria {
    query = <<-QUERY
      AzureDiagnostics
      | where Category == "FrontDoorWebApplicationFirewallLog"
      | where msg_s has "Block"
      | summarize BlockCount = count() by bin(TimeGenerated, 5m)
      | where BlockCount > 20
    QUERY

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.alerts[0].id]
  }
}
