using '../main.bicep'

param location = 'eastus'
param resourceGroupName = 'hub-spoke-rg'
param storageAccountName = 'sthubspokedata'
param appServiceName = 'app-hubspoke-web'
param frontDoorName = 'fd-hubspoke'
param wafPolicyName = 'wafpolicyhubspoke'
param logAnalyticsWorkspaceName = 'law-hub-spoke'
param alertEmail = ''
param geoBlockCountries = ['CN', 'RU', 'KP', 'IR']
param tags = {
  Project: 'Hub-Spoke-Network'
  Environment: 'Dev'
  ManagedBy: 'Bicep'
}
