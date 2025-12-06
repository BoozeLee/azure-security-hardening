// Azure Security Hardening - Simplified Working Template
// High-threat environment protection for kiliaan@bakerstreetproject221b.store

targetScope = 'subscription'

// Parameters
@description('Environment name (prod, staging, dev)')
param environmentName string = 'prod'

@description('Location for all resources')
param location string = 'westeurope'

@description('Your email for security alerts')
param securityContactEmail string = 'kiliaan@bakerstreetproject221b.store'

@description('Resource prefix for naming')
param resourcePrefix string = 'sec-bsp'

// Variables
var resourceGroupName = '${resourcePrefix}-rg-${environmentName}'
var keyVaultName = '${resourcePrefix}kv${environmentName}${uniqueString(subscription().subscriptionId)}'
var storageAccountName = '${resourcePrefix}sa${environmentName}${uniqueString(subscription().subscriptionId)}'
var workspaceName = '${resourcePrefix}-law-${environmentName}'

var tags = {
  Environment: environmentName
  Owner: 'kiliaan@bakerstreetproject221b.store'
  Purpose: 'Security-Hardened-Resources'
  ThreatLevel: 'High'
  Compliance: 'Required'
}

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Key Vault (deployed directly)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  scope: resourceGroup
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: tenant().tenantId
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Storage Account (deployed directly)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  scope: resourceGroup
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_ZRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: true
      keySource: 'Microsoft.Storage'
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

// Log Analytics Workspace (deployed directly)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  scope: resourceGroup
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: false
    }
    workspaceCapping: {
      dailyQuotaGb: 10
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output keyVaultId string = keyVault.id
output storageAccountId string = storageAccount.id
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id