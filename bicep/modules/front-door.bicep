@description('Resource group name')
param resourceGroupName string

@description('Front Door name')
param frontDoorName string

@description('WAF policy name')
param wafPolicyName string

@description('App Service hostname')
param appServiceHostname string

@description('Countries to geo-block')
param geoBlockCountries array = ['CN', 'RU', 'KP', 'IR']

@description('Resource tags')
param tags object = {}

// Front Door Profile
resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

// Endpoint
resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoor
  name: 'hubspoke-web'
  location: 'global'
  tags: tags
  properties: {
    enabledState: 'Enabled'
  }
}

// Origin Group
resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoor
  name: 'og-web-app'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 30
      probeRequestType: 'HEAD'
    }
    sessionAffinityState: 'Disabled'
  }
}

// Origin
resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'origin-app-hubspoke'
  properties: {
    hostName: appServiceHostname
    originHostHeader: appServiceHostname
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

// Route
resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'route-default'
  dependsOn: [origin]
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: ['Http', 'Https']
    patternsToMatch: ['/*']
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    enabledState: 'Enabled'
  }
}

// WAF Policy
resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: wafPolicyName
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      mode: 'Prevention'
      enabledState: 'Enabled'
    }
    customRules: {
      rules: [
        {
          name: 'RateLimitPerIP'
          priority: 1
          ruleType: 'RateLimitRule'
          action: 'Block'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 100
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              matchValue: ['/']
              transforms: ['Lowercase']
            }
          ]
        }
        {
          name: 'GeoBlock'
          priority: 2
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'RemoteAddr'
              operator: 'GeoMatch'
              matchValue: geoBlockCountries
            }
          ]
        }
        {
          name: 'BlockKnownBadPatterns'
          priority: 3
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              matchValue: ['../', 'etc/passwd', '<script>']
              transforms: ['UrlDecode', 'Lowercase']
            }
          ]
        }
        {
          name: 'BlockSQLInjection'
          priority: 4
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'QueryString'
              operator: 'Contains'
              matchValue: ['\' or', '1=1', 'union select', 'drop table', '--']
              transforms: ['UrlDecode', 'Lowercase']
            }
          ]
        }
        {
          name: 'BlockXSS'
          priority: 5
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'QueryString'
              operator: 'Contains'
              matchValue: ['<script>', 'javascript:', 'onerror=']
              transforms: ['UrlDecode', 'Lowercase']
            }
          ]
        }
      ]
    }
  }
}

// Security Policy
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoor
  name: 'secpol-waf'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: ['/*']
        }
      ]
    }
  }
}

output frontDoorId string = frontDoor.id
output frontDoorEndpointHostname string = endpoint.properties.hostName
output wafPolicyId string = wafPolicy.id
