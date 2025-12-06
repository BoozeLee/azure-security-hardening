// Storage Account Security Configuration
// High-threat environment protection

@description('Storage account name')
param storageAccountName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Key Vault resource ID for encryption keys')
param keyVaultId string

@description('Resource tags')
param tags object = {}

// Secure Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS' // Zone-redundant storage for high availability
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false // Block all public blob access
    allowSharedKeyAccess: false // Disable shared key access
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled' // Block all public access
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: true
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyvaulturi: reference(keyVaultId, '2023-07-01').vaultUri
        keyname: 'storage-encryption-key'
      }
      services: {
        file: {
          enabled: true
          keyType: 'Service'
        }
        blob: {
          enabled: true
          keyType: 'Service'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
  }
}

// Private Endpoint for Storage Account
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${storageAccountName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/sec-bsp-vnet-prod/subnets/private-endpoints'
    }
    privateLinkServiceConnections: [
      {
        name: 'storageConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

// Advanced Threat Protection
resource storageDefender 'Microsoft.Security/advancedThreatProtectionSettings@2019-01-01' = {
  name: 'current'
  scope: storageAccount
  properties: {
    isEnabled: true
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount
  name: '${storageAccountName}-diagnostics'
  properties: {
    workspaceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.OperationalInsights/workspaces/sec-bsp-law-prod'
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Output
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
