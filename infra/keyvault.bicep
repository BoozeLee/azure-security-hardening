// Azure Key Vault - Maximum Security Configuration
// High-threat environment protection

@description('The name of the Key Vault')
param keyVaultName string

@description('The Azure location where the key vault should be created')
param location string = resourceGroup().location

@description('The Azure tenant ID')
param tenantId string

@description('Enable Key Vault for disk encryption')
param enabledForDiskEncryption bool = true

@description('Enable Key Vault for template deployment')
param enabledForTemplateDeployment bool = true

@description('Enable RBAC authorization for Key Vault')
param enableRbacAuthorization bool = true

@description('Enable soft delete for Key Vault')
param enableSoftDelete bool = true

@description('Soft delete retention period in days')
param softDeleteRetentionInDays int = 90

@description('Enable purge protection for Key Vault')
param enablePurgeProtection bool = true

@description('Resource tags')
param tags object = {}

// Key Vault with maximum security
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'premium' // Premium tier for HSM-backed keys
    }
    tenantId: tenantId
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    publicNetworkAccess: 'Disabled' // Block all public access
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny' // Deny all traffic by default
      ipRules: []
      virtualNetworkRules: []
    }
    // Advanced security features
    provisioningState: 'Succeeded'
    vaultUri: 'https://${keyVaultName}.vault.azure.net/'
  }
}

// Private Endpoint for Key Vault (maximum security)
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${keyVaultName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/sec-bsp-vnet-prod/subnets/default'
    }
    privateLinkServiceConnections: [
      {
        name: 'keyVaultConnection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

// Diagnostic Settings for Key Vault
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: '${keyVaultName}-diagnostics'
  properties: {
    workspaceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.OperationalInsights/workspaces/sec-bsp-law-prod'
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

// Output
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
