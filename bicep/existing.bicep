targetScope = 'subscription'

param applicationName string
param location string
param tags object

import { getPrefix } from '../common/bicep/functions.bicep'

resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toLower('${applicationName}-monitoring-rg')
  location: location
  tags: tags
}

resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: toLower('${applicationName}-network-rg')
  location: location
  tags: tags
}

module logAnalyticsWorkspace '../common/bicep/log-analytics-workspace.bicep' = {
  name: 'log-analytics-workspace'
  scope: monitoringResourceGroup
  params: {
    name: '${getPrefix(applicationName, monitoringResourceGroup.id)}-log-analytics-workspace'
    location: location
  }
}

module virtualNetwork '../common/bicep/virtual-network.bicep' = {
  name: 'virtual-network'
  scope: networkResourceGroup
  params: {
    name: '${getPrefix(applicationName, networkResourceGroup.id)}-virtual-network'
    location: location
    addressPrefixes: [
      '10.0.0.0/24'
    ]
    tags: tags
  }
}
