targetScope = 'subscription'

@description('Azure region')
param location string = 'eastus'

@description('Resource group name')
param resourceGroupName string = 'hub-spoke-rg'

@description('SSH public key')
@secure()
param sshPublicKey string

@description('Storage account name')
param storageAccountName string = 'sthubspokedata'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = 'law-hub-spoke'

@description('Alert email')
param alertEmail string = ''

@description('Resource tags')
param tags object = {
  Project: 'Hub-Spoke-Network'
  Environment: 'Dev'
  ManagedBy: 'Bicep'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Hub Network
module hubNetwork 'modules/hub-network.bicep' = {
  scope: rg
  name: 'hub-network'
  params: {
    location: location
    firewallPrivateIp: '10.0.1.4'
    sshPublicKey: sshPublicKey
    tags: tags
  }
}

// Firewall
module firewall 'modules/firewall.bicep' = {
  scope: rg
  name: 'firewall'
  params: {
    location: location
    firewallSubnetId: hubNetwork.outputs.firewallSubnetId
    tags: tags
  }
}

// Web Spoke
module spokeWeb 'modules/spoke-network.bicep' = {
  scope: rg
  name: 'spoke-web'
  params: {
    location: location
    spokeName: 'web'
    addressSpace: '10.1.0.0/16'
    subnetPrefix: '10.1.1.0/24'
    hubVnetId: hubNetwork.outputs.vnetId
    hubVnetName: hubNetwork.outputs.vnetName
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
    deployTestVm: true
    sshPublicKey: sshPublicKey
    tags: tags
  }
}

// Data Spoke
module spokeData 'modules/spoke-network.bicep' = {
  scope: rg
  name: 'spoke-data'
  params: {
    location: location
    spokeName: 'data'
    addressSpace: '10.2.0.0/16'
    subnetPrefix: '10.2.1.0/24'
    hubVnetId: hubNetwork.outputs.vnetId
    hubVnetName: hubNetwork.outputs.vnetName
    firewallPrivateIp: firewall.outputs.firewallPrivateIp
    deployTestVm: false
    tags: tags
  }
}

// Storage
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage'
  params: {
    location: location
    storageAccountName: storageAccountName
    dataSubnetId: spokeData.outputs.subnetId
    hubVnetId: hubNetwork.outputs.vnetId
    webSpokeVnetId: spokeWeb.outputs.vnetId
    dataSpokeVnetId: spokeData.outputs.vnetId
    tags: tags
  }
}

// App Service (commented out, Azure quota limitation on Free/Basic App Service VMs)
// module appService 'modules/app-service.bicep' = {
//   scope: rg
//   name: 'app-service'
//   params: {
//     location: location
//     appServiceName: appServiceName
//     tags: tags
//   }
// }

// Front Door + WAF (commented out — depends on App Service)
// module frontDoor 'modules/front-door.bicep' = {
//   scope: rg
//   name: 'front-door'
//   params: {
//     resourceGroupName: resourceGroupName
//     frontDoorName: frontDoorName
//     wafPolicyName: wafPolicyName
//     appServiceHostname: appService.outputs.appServiceHostname
//     geoBlockCountries: geoBlockCountries
//     tags: tags
//   }
// }

// Monitoring
module monitoring 'modules/monitoring.bicep' = {
  scope: rg
  name: 'monitoring'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    hubVnetId: hubNetwork.outputs.vnetId
    webSpokeVnetId: spokeWeb.outputs.vnetId
    dataSpokeVnetId: spokeData.outputs.vnetId
    alertEmail: alertEmail
    tags: tags
  }
}

// Outputs
output firewallPrivateIp string = firewall.outputs.firewallPrivateIp
