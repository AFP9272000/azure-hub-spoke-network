@description('Azure region')
param location string

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string

@description('Flow logs storage account name')
param flowLogsStorageName string = 'sthubspokeflowlogs'

@description('Hub VNet ID')
param hubVnetId string

@description('Web spoke VNet ID')
param webSpokeVnetId string

@description('Data spoke VNet ID')
param dataSpokeVnetId string

@description('Alert email')
param alertEmail string = ''

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Flow Logs Storage Account
resource flowLogsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: flowLogsStorageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Network Watcher
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-11-01' existing = {
  name: 'NetworkWatcher_${location}'
  scope: resourceGroup('NetworkWatcherRG')
}

// VNet Flow Logs
resource flowLogHub 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  parent: networkWatcher
  name: 'flowlog-vnet-hub'
  location: location
  tags: tags
  properties: {
    targetResourceId: hubVnetId
    storageId: flowLogsStorage.id
    enabled: true
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      enabled: true
      days: 30
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
        workspaceId: logAnalytics.properties.customerId
        workspaceRegion: location
        trafficAnalyticsInterval: 10
      }
    }
  }
}

resource flowLogWeb 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  parent: networkWatcher
  name: 'flowlog-vnet-spoke-web'
  location: location
  tags: tags
  properties: {
    targetResourceId: webSpokeVnetId
    storageId: flowLogsStorage.id
    enabled: true
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      enabled: true
      days: 30
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
        workspaceId: logAnalytics.properties.customerId
        workspaceRegion: location
        trafficAnalyticsInterval: 10
      }
    }
  }
}

resource flowLogData 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  parent: networkWatcher
  name: 'flowlog-vnet-spoke-data'
  location: location
  tags: tags
  properties: {
    targetResourceId: dataSpokeVnetId
    storageId: flowLogsStorage.id
    enabled: true
    format: {
      type: 'JSON'
      version: 2
    }
    retentionPolicy: {
      enabled: true
      days: 30
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: logAnalytics.id
        workspaceId: logAnalytics.properties.customerId
        workspaceRegion: location
        trafficAnalyticsInterval: 10
      }
    }
  }
}

// Firewall Diagnostic Settings
//resource firewallDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//  name: 'fw-diag'
//  scope: az.resourceId('Microsoft.Network/azureFirewalls', last(split(firewallId, '/')))
//  properties: {
//    workspaceId: logAnalytics.id
//    logs: [
//      { categoryGroup: 'allLogs', enabled: true }
//    ]
//    metrics: [
//      { category: 'AllMetrics', enabled: true }
//    ]
//  }
//}

// Front Door Diagnostic Settings
//resource frontDoorDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//  name: 'fd-diag'
//  scope: az.resourceId('Microsoft.Cdn/profiles', last(split(frontDoorId, '/')))
//  properties: {
//    workspaceId: logAnalytics.id
//    logs: [
//      { categoryGroup: 'allLogs', enabled: true }
//    ]
//    metrics: [
//      { category: 'AllMetrics', enabled: true }
//    ]
//  }
//}

// Action Group (conditional)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (!empty(alertEmail)) {
  name: 'ag-hub-spoke-alerts'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'hubspoke'
    enabled: true
    emailReceivers: [
      {
        name: 'admin-email'
        emailAddress: alertEmail
      }
    ]
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
