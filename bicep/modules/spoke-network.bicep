@description('Azure region')
param location string

@description('Spoke name identifier')
param spokeName string

@description('Spoke VNet address space')
param addressSpace string

@description('Spoke subnet prefix')
param subnetPrefix string

@description('Hub VNet ID for peering')
param hubVnetId string

@description('Hub VNet name for peering')
param hubVnetName string

@description('Firewall private IP for UDR')
param firewallPrivateIp string

@description('Deploy test VM')
param deployTestVm bool = false

@description('VM size')
param vmSize string = 'Standard_D2s_v3'

@description('SSH public key')
@secure()
param sshPublicKey string = ''

@description('Resource tags')
param tags object = {}

// Spoke VNet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-spoke-${spokeName}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
    subnets: [
      {
        name: 'snet-${spokeName}'
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: rt.id
          }
        }
      }
    ]
  }
}

// NSG
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${spokeName}'
  location: location
  tags: tags
}

// Route Table
resource rt 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-spoke-${spokeName}'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// Peering: Hub to Spoke
resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: '${hubVnetName}/hub-to-spoke-${spokeName}'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
  }
}

// Peering: Spoke to Hub
resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: spokeVnet
  name: 'spoke-${spokeName}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
  }
}

// Test VM NIC (conditional)
resource vmNic 'Microsoft.Network/networkInterfaces@2023-11-01' = if (deployTestVm) {
  name: 'nic-vm-${spokeName}-test'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: spokeVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Test VM (conditional)
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = if (deployTestVm) {
  name: 'vm-${spokeName}-test'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm-${spokeName}-test'
      adminUsername: 'azureuser'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
  }
}

output vnetId string = spokeVnet.id
output vnetName string = spokeVnet.name
output subnetId string = spokeVnet.properties.subnets[0].id
output nsgId string = nsg.id
