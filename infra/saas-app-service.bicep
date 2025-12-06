// SaaS Application Service - Secure Multi-Tenant Configuration
// Designed for enterprise B2B SaaS applications

@description('App Service Plan name')
param appServicePlanName string

@description('App Service name')
param appServiceName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Virtual Network ID for integration')
param vnetId string

@description('Subnet ID for VNet integration')
param subnetId string

@description('Key Vault ID for secrets')
param keyVaultId string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

@description('SKU for App Service Plan')
param skuName string = 'P1v3'

@description('Number of instances')
param skuCapacity int = 2

// App Service Plan with auto-scaling
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  kind: 'linux'
  properties: {
    reserved: true // Linux
    zoneRedundant: true // High availability
  }
}

// App Service with maximum security
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    publicNetworkAccess: 'Disabled' // Private endpoints only
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/health'
      ipSecurityRestrictions: [
        {
          action: 'Deny'
          priority: 2147483647
          name: 'Deny all'
          description: 'Deny all access by default'
        }
      ]
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'KEY_VAULT_URI'
          value: reference(keyVaultId, '2023-07-01').vaultUri
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
      ]
    }
  }
}

// Private Endpoint for App Service
resource appServicePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${appServiceName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'appServiceConnection'
        properties: {
          privateLinkServiceId: appService.id
          groupIds: ['sites']
        }
      }
    ]
  }
}

// Application Insights for monitoring
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appServiceName}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Auto-scaling rules
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${appServicePlanName}-autoscale'
  location: location
  tags: tags
  properties: {
    enabled: true
    targetResourceUri: appServicePlan.id
    profiles: [
      {
        name: 'Auto scale based on CPU'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appService
  name: '${appServiceName}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Outputs
output appServiceId string = appService.id
output appServiceName string = appService.name
output appServicePrincipalId string = appService.identity.principalId
output appServiceDefaultHostName string = appService.properties.defaultHostName
output applicationInsightsId string = applicationInsights.id
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey