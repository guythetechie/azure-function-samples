targetScope = 'subscription'

param applicationName string
param location string
param tags object = {}
param monitoringResourceGroupName string?
param uploadStorageAccountContainerId string?
param logAnalyticsWorkspaceId string?
param privateEndpointSubnetId string?
param vnetIntegrationSubnetId string?

module a 'existing.bicep' = {
  name: 'a'
  params: {
    applicationName: applicationName
  }
}

var prefix = '${applicationName}-${take(uniqueString(resourceGroup.id), 4)}'
var alphaNumericPrefix = replace(prefix, '-', '')

func getResourceGroupName(resourceId string) string => split(resourceId, '/')[4]
func getResourceName(resourceId string) string => last(split(resourceId, '/'))
func getResourceParentName(resourceId string) string => split(resourceId, '/')[length(split(resourceId, '/')) - 2]
func getResourceParentId(resourceId string) string =>
  join(take(split(resourceId, '/'), length(split(resourceId, '/')) - 2), '/')

resource applicationResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toLower('${applicationName}-rg')
  location: location
  tags: tags
}

resource newMonitoringResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = if(empty(monitoringResourceGroupName)) {
  name: toLower('${applicationName}-monitoring-rg')
}

resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: !empty(logAnalyticsWorkspaceId) ? empty : newMonitoringResourceGroup.name
}

resource uploadStorageAccountResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: empty(uploadStorageAccountContainerId)
    ? resourceGroup.name
    : getResourceGroupName(uploadStorageAccountContainerId!)
}

resource logAnalyticsWorkspaceResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: empty(logAnalyticsWorkspaceId) ? resourceGroup.name : getResourceGroupName(logAnalyticsWorkspaceId!)
}

resource virtualNetworkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: empty(vnetIntegrationSubnetId) ? resourceGroup.name : getResourceGroupName(vnetIntegrationSubnetId!)
}

module logAnalyticsWorkspaceDeployment '../common/bicep/log-analytics-workspace.bicep' = if (empty(logAnalyticsWorkspaceId)) {
  name: 'log-analytics-workspace-deployment'
  scope: logAnalyticsWorkspaceResourceGroup
  params: {
    name: '${prefix}-log-analytics-workspace'
    location: location
    tags: tags
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: empty(logAnalyticsWorkspaceId)
    ? logAnalyticsWorkspaceDeployment.outputs.name
    : getResourceName(logAnalyticsWorkspaceId!)
  scope: logAnalyticsWorkspaceResourceGroup
}

module applicationInsightsDeployment '../common/bicep/application-insights.bicep' = {
  name: 'application-insights-deployment'
  scope: resourceGroup
  params: {
    name: '${prefix}-application-insights'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module virtualNetworkDeployment '../common/bicep/virtual-network.bicep' = {
  name: 'virtual-network'
  scope: virtualNetworkResourceGroup
  params: {
    name: '${prefix}-virtual-network'
    location: location
    tags: tags
    addressPrefixes: [
      '10.0.0.0/24'
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: empty(vnetIntegrationSubnetId)
    ? virtualNetworkDeployment.outputs.name
    : getResourceParentName(vnetIntegrationSubnetId!)
  scope: virtualNetworkResourceGroup
}

module privateEndpointSubnetDeployment '../common/bicep/subnet.bicep' = {
  name: 'private-endpoint-subnet'
  scope: virtualNetworkResourceGroup
  params: {
    name: 'private-endpoint'
    virtualNetworkName: virtualNetwork.name
    addressPrefix: '10.0.0.0/28'
  }
}

resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: empty(privateEndpointSubnetId)
    ? privateEndpointSubnetDeployment.outputs.name
    : getResourceName(privateEndpointSubnetId!)
  parent: virtualNetwork
}

module vnetIntegrationSubnetDeployment '../common/bicep/subnet.bicep' = {
  name: 'vnet-integration-subnet'
  scope: virtualNetworkResourceGroup
  params: {
    name: 'vnet-integration'
    virtualNetworkName: virtualNetwork.name
    addressPrefix: '10.0.0.64/26'
    delegation: 'Microsoft.App/environments'
  }
}

resource vnetIntegrationSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: empty(vnetIntegrationSubnetId)
    ? vnetIntegrationSubnetDeployment.outputs.name
    : getResourceName(vnetIntegrationSubnetId!)
  parent: virtualNetwork
}

module uploadStorageAccountDeployment '../common/bicep/storage-account.bicep' = if (empty(uploadStorageAccountContainerId)) {
  name: 'storage-account'
  scope: uploadStorageAccountResourceGroup
  params: {
    name: '${take('${alphaNumericPrefix}upload', 13)}stor'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

resource uploadStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: empty(uploadStorageAccountContainerId)
    ? uploadStorageAccountDeployment.outputs.name
    : getResourceParentName(uploadStorageAccountContainerId!)
  scope: uploadStorageAccountResourceGroup
}

module uploadStorageAccountContainerDeployment '../common/bicep/storage-account-container.bicep' = if (empty(uploadStorageAccountContainerId)) {
  name: 'storage-account-container'
  scope: uploadStorageAccountResourceGroup
  params: {
    name: 'uploads'
    storageAccountName: uploadStorageAccount.name
  }
}

resource uploadStorageAccountBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' existing = {
  name: 'default'
  parent: uploadStorageAccount
}

resource uploadStorageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' existing = {
  name: empty(uploadStorageAccountContainerId)
    ? uploadStorageAccountContainerDeployment.outputs.name
    : getResourceName(uploadStorageAccountContainerId!)
  parent: uploadStorageAccountBlobServices
}

module functionAppStorageAccount '../common/bicep/storage-account.bicep' = {
  name: 'function-app-storage-account'
  scope: resourceGroup
  params: {
    name: '${take('${alphaNumericPrefix}', 19)}stor'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.id
  }
}

module functionAppStorageAccountContainer '../common/bicep/storage-account-container.bicep' = {
  name: 'function-app-storage-account-container'
  scope: resourceGroup
  params: {
    name: 'function-app'
    storageAccountName: functionAppStorageAccount.outputs.name
  }
}

module functionAppStorageAccountUploadsQueue '../common/bicep/storage-account-queue.bicep' = {
  name: 'function-app-storage-account-uploads-queue'
  scope: resourceGroup
  params: {
    name: 'uploads'
    storageAccountName: functionAppStorageAccount.outputs.name
  }
}

module storageBlobPrivateDnsZone '../common/bicep/private-dns-zone.bicep' = {
  name: 'storage-blob-private-dns-zone'
  scope: resourceGroup
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    tags: tags
    virtualNetworkId: empty(vnetIntegrationSubnetId)
      ? virtualNetwork.outputs.id
      : getResourceParentId(vnetIntegrationSubnetId!)
  }
}

output resourceGroupName string = resourceGroup.name
output functionAppName string = resourceDeployment.outputs.functionAppName
