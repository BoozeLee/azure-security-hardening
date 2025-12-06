// Azure Security Hardening - Main Template
// High-threat environment protection for kiliaan@bakerstreetproject.com
// Follows Azure best practices for maximum security

targetScope = 'subscription'

// Parameters
@description('Environment name (prod, staging, dev)')
param environmentName string = 'prod'

@description('Location for all resources')
param location string = 'westeurope'

@description('Your email for security alerts')
param securityContactEmail string = 'kiliaan@bakerstreetproject.com'

@description('Resource prefix for naming')
param resourcePrefix string = 'sec-bsp'

// Variables
var resourceGroupName = '${resourcePrefix}-rg-${environmentName}'
var tags = {
  Environment: environmentName
  Owner: 'kiliaan@bakerstreetproject.com'
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

// Key Vault Module
module keyVault 'keyvault.bicep' = {
  name: 'keyVaultDeployment'
  scope: resourceGroup
  params: {
    keyVaultName: '${resourcePrefix}-kv-${environmentName}'
    location: location
    tenantId: tenant().tenantId
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    tags: tags
  }
}

// Security Center Configuration
module securityCenter 'security-center.bicep' = {
  name: 'securityCenterDeployment'
  scope: subscription()
  params: {
    securityContactEmail: securityContactEmail
    enableDefenderForServers: true
    enableDefenderForStorage: true
    enableDefenderForKeyVault: true
    enableDefenderForResourceManager: true
    enableDefenderForDns: true
  }
}

// Network Security Configuration
module networkSecurity 'network-security.bicep' = {
  name: 'networkSecurityDeployment'
  scope: resourceGroup
  params: {
    vnetName: '${resourcePrefix}-vnet-${environmentName}'
    nsgName: '${resourcePrefix}-nsg-${environmentName}'
    location: location
    tags: tags
  }
}

// Storage Security Configuration
module storageAccount 'storage.bicep' = {
  name: 'storageDeployment'
  scope: resourceGroup
  params: {
    storageAccountName: '${resourcePrefix}sa${environmentName}${uniqueString(resourceGroup.id)}'
    location: location
    keyVaultId: keyVault.outputs.keyVaultId
    tags: tags
  }
}

// Log Analytics Workspace
module logAnalytics 'log-analytics.bicep' = {
  name: 'logAnalyticsDeployment'
  scope: resourceGroup
  params: {
    workspaceName: '${resourcePrefix}-law-${environmentName}'
    location: location
    retentionInDays: 90
    tags: tags
  }
}

// Azure Policy Assignment
module azurePolicyAssignment 'azure-policy.bicep' = {
  name: 'azurePolicyDeployment'
  scope: resourceGroup
  params: {
    policyAssignmentName: 'security-baseline-assignment'
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
