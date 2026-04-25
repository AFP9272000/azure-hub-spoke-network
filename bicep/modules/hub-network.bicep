@description('Azure region')
param location string

@description('Hub VNet address space')
param addressSpace string = '10.0.0.0/16'

@description('Firewall subnet prefix')
param firewallSubnetPrefix string = '10.0.1.0/26'

@description('Bastion subnet prefix')
param bastionSubnetPrefix string = '10.0.2.0/26'

@description('Management subnet prefix')
param managementSubnetPrefix string = '10.0.3.0/24'

@description('Firewall private IP for UDR')
param firewallPrivateIp string

@description('VM size')
param vmSize string = 'Standard_D2s_v3'

@description('SSH public key')
@secure()
param sshPublicKey string

@description('Resource tags')
param tags object = {}

// Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-hub'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [addressSpace]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
      {
        name: 'snet-management'
        properties: {
          addressPrefix: managementSubnetPrefix
          networkSecurityGroup: {
            id: nsgMgmt.id
          }
          routeTable: {
            id: rtMgmt.id
          }
        }
      }
    ]
  }
}

// Management NSG
resource nsgMgmt 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-mgmt'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSHFromVNet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Management Route Table
resource rtMgmt 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-mgmt'
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

// Bastion Public IP
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-bastion-hub'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion Host
resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: 'bastion-hub'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ip-config'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
  }
}

// Management VM NIC
resource mgmtNic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-vm-mgmt-test'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[2].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// Management VM
resource mgmtVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-mgmt-test'
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
      computerName: 'vm-mgmt-test'
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
          id: mgmtNic.id
        }
      ]
    }
  }
}

output vnetId string = hubVnet.id
output vnetName string = hubVnet.name
output firewallSubnetId string = hubVnet.properties.subnets[0].id
output bastionSubnetId string = hubVnet.properties.subnets[1].id
output managementSubnetId string = hubVnet.properties.subnets[2].id
