@description('Azure region')
param location string

@description('Firewall subnet ID')
param firewallSubnetId string

@description('Firewall SKU tier')
param firewallSkuTier string = 'Standard'

@description('Hub address prefix')
param hubAddressPrefix string = '10.0.0.0/16'

@description('Web spoke address prefix')
param webSpokeAddressPrefix string = '10.1.0.0/16'

@description('Data spoke address prefix')
param dataSpokeAddressPrefix string = '10.2.0.0/16'

@description('Web VM private IP for DNAT')
param webVmPrivateIp string = '10.1.1.4'

@description('Resource tags')
param tags object = {}

// Firewall Public IP
resource firewallPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-fw-hub'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Firewall Policy
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-11-01' = {
  name: 'fw-policy-hub'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: firewallSkuTier
    }
    threatIntelMode: 'Deny'
  }
}

// Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: 'fw-hub'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: firewallSkuTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'fw-ip-config'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
  }
}

// Application Rule Collection Group
resource appRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  dependsOn: [firewall]
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-rules-baseline'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'allow-azure-updates'
            sourceAddresses: [hubAddressPrefix]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.ubuntu.com'
              '*.microsoft.com'
              '*.azure.com'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'app-rules-outbound'
        priority: 300
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'allow-web-spoke-outbound'
            sourceAddresses: [webSpokeAddressPrefix]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
              '*.azure.com'
              '*.ubuntu.com'
              '*.docker.io'
              '*.github.com'
              'github.com'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'allow-data-spoke-limited'
            sourceAddresses: [dataSpokeAddressPrefix]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
              '*.azure.com'
            ]
          }
        ]
      }
    ]
  }
}

// Network Rule Collection Group
resource netRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  dependsOn: [appRuleGroup]
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'net-rules-baseline'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-dns'
            sourceAddresses: [hubAddressPrefix]
            destinationAddresses: ['*']
            destinationPorts: ['53']
            ipProtocols: ['TCP', 'UDP']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'net-rules-web-to-data'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-web-to-sql'
            sourceAddresses: [webSpokeAddressPrefix]
            destinationAddresses: [dataSpokeAddressPrefix]
            destinationPorts: ['1433']
            ipProtocols: ['TCP']
          }
          {
            ruleType: 'NetworkRule'
            name: 'allow-web-to-storage'
            sourceAddresses: [webSpokeAddressPrefix]
            destinationAddresses: [dataSpokeAddressPrefix]
            destinationPorts: ['443']
            ipProtocols: ['TCP']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'net-rules-deny-spoke-to-spoke'
        priority: 300
        action: {
          type: 'Deny'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'deny-data-to-web'
            sourceAddresses: [dataSpokeAddressPrefix]
            destinationAddresses: [webSpokeAddressPrefix]
            destinationPorts: ['*']
            ipProtocols: ['Any']
          }
        ]
      }
    ]
  }
}

// DNAT Rule Collection Group
resource dnatRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-11-01' = {
  parent: firewallPolicy
  name: 'DefaultDnatRuleCollectionGroup'
  dependsOn: [netRuleGroup]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        name: 'nat-rules-inbound'
        priority: 100
        action: {
          type: 'DNAT'
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'dnat-web-http'
            sourceAddresses: ['*']
            destinationAddresses: [firewallPip.properties.ipAddress]
            destinationPorts: ['80']
            translatedAddress: webVmPrivateIp
            translatedPort: '80'
            ipProtocols: ['TCP']
          }
        ]
      }
    ]
  }
}

output firewallId string = firewall.id
output firewallPrivateIp string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = firewallPip.properties.ipAddress
output firewallPolicyId string = firewallPolicy.id
