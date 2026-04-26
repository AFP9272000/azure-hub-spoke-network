using '../main.bicep'

param location = 'eastus'
param resourceGroupName = 'hub-spoke-rg'
param sshPublicKey = ''
param storageAccountName = 'sthubspokedata'
param logAnalyticsWorkspaceName = 'law-hub-spoke'
param alertEmail = ''
param tags = {
  Project: 'Hub-Spoke-Network'
  Environment: 'Dev'
  ManagedBy: 'Bicep'
}
