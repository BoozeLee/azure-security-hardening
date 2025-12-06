// Azure Security Hardening + SaaS Infrastructure - Complete Solution
// Enterprise-grade multi-tenant SaaS platform with zero-trust security

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

@description('SQL Administrator login')
@secure()
param sqlAdminLogin string

@description('SQL Administrator password')
@secure()
param sqlAdminPassword string

@description('Enable SaaS components')
param enableSaaSComponents bool = true

// Variables
var resourceGroupName = '${resourcePrefix}-rg-${environmentName}'
var tags = {
  Environment: environmentName
  Owner: 'kiliaan@bakerstreetproject.com'
  Purpose: 'Security-Hardened-SaaS-Platform'
  ThreatLevel: 'High'
  Compliance: 'Required'
  Platform: 'Multi-Tenant-SaaS'
}

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ========================================
// SECURITY FOUNDATION (Existing)
// ========================================

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

// ========================================
// SAAS PLATFORM COMPONENTS (New)
// ========================================

// App Service for SaaS Application
module appService 'saas-app-service.bicep' = if (enableSaaSComponents) {
  name: 'appServiceDeployment'
  scope: resourceGroup
  params: {
    appServicePlanName: '${resourcePrefix}-asp-${environmentName}'
    appServiceName: '${resourcePrefix}-app-${environmentName}'
    location: location
    vnetId: networkSecurity.outputs.vnetId
    subnetId: networkSecurity.outputs.subnetId
    keyVaultId: keyVault.outputs.keyVaultId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
    skuName: environmentName == 'prod' ? 'P1v3' : 'B1'
    skuCapacity: environmentName == 'prod' ? 2 : 1
  }
  dependsOn: [
    networkSecurity
    keyVault
    logAnalytics
  ]
}

// SQL Database for Multi-Tenant Data
module sqlDatabase 'saas-database.bicep' = if (enableSaaSComponents) {
  name: 'sqlDatabaseDeployment'
  scope: resourceGroup
  params: {
    sqlServerName: '${resourcePrefix}-sql-${environmentName}'
    location: location
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    vnetId: networkSecurity.outputs.vnetId
    subnetId: networkSecurity.outputs.subnetId
    keyVaultId: keyVault.outputs.keyVaultId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
    enableAzureADAuth: true
  }
  dependsOn: [
    networkSecurity
    keyVault
    logAnalytics
  ]
}

// Redis Cache for Session Management
module redisCache 'saas-redis-cache.bicep' = if (enableSaaSComponents) {
  name: 'redisCacheDeployment'
  scope: resourceGroup
  params: {
    redisCacheName: '${resourcePrefix}-redis-${environmentName}'
    location: location
    subnetId: networkSecurity.outputs.subnetId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
    redisSku: environmentName == 'prod' ? 'Premium' : 'Basic'
    redisFamily: environmentName == 'prod' ? 'P' : 'C'
    redisCapacity: environmentName == 'prod' ? 1 : 0
  }
  dependsOn: [
    networkSecurity
    logAnalytics
  ]
}

// API Management for API Gateway
module apiManagement 'saas-api-management.bicep' = if (enableSaaSComponents) {
  name: 'apiManagementDeployment'
  scope: resourceGroup
  params: {
    apimName: '${resourcePrefix}-apim-${environmentName}'
    location: location
    publisherEmail: securityContactEmail
    publisherName: 'Baker Street Project'
    subnetId: networkSecurity.outputs.subnetId
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
    skuName: environmentName == 'prod' ? 'Developer' : 'Developer'
    skuCapacity: 1
  }
  dependsOn: [
    networkSecurity
    logAnalytics
  ]
}

// Azure Front Door for Global CDN and WAF
module frontDoor 'saas-front-door.bicep' = if (enableSaaSComponents) {
  name: 'frontDoorDeployment'
  scope: resourceGroup
  params: {
    frontDoorName: '${resourcePrefix}-fd-${environmentName}'
    location: 'global'
    backendHostname: enableSaaSComponents ? appService.outputs.appServiceDefaultHostName : 'placeholder.azurewebsites.net'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
  dependsOn: [
    appService
    logAnalytics
  ]
}

// ========================================
// RBAC Assignments for SaaS Components
// ========================================

// Grant App Service access to Key Vault
resource appServiceKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSaaSComponents) {
  name: guid(resourceGroup.id, 'appservice-keyvault-access')
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: enableSaaSComponents ? appService.outputs.appServicePrincipalId : ''
    principalType: 'ServicePrincipal'
  }
}

// Grant SQL Server access to Key Vault
resource sqlServerKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSaaSComponents) {
  name: guid(resourceGroup.id, 'sqlserver-keyvault-access')
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    principalId: enableSaaSComponents ? sqlDatabase.outputs.sqlServerPrincipalId : ''
    principalType: 'ServicePrincipal'
  }
}

// Grant API Management access to Key Vault
resource apimKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSaaSComponents) {
  name: guid(resourceGroup.id, 'apim-keyvault-access')
  scope: resourceGroup
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: enableSaaSComponents ? apiManagement.outputs.apimPrincipalId : ''
    principalType: 'ServicePrincipal'
  }
}

// ========================================
// Outputs
// ========================================

// Security Foundation Outputs
output resourceGroupName string = resourceGroup.name
output keyVaultName string = keyVault.outputs.keyVaultName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId

// SaaS Platform Outputs
output appServiceUrl string = enableSaaSComponents ? 'https://${appService.outputs.appServiceDefaultHostName}' : ''
output frontDoorUrl string = enableSaaSComponents ? 'https://${frontDoor.outputs.frontDoorEndpointHostname}' : ''
output apiManagementGatewayUrl string = enableSaaSComponents ? apiManagement.outputs.apimGatewayUrl : ''
output sqlServerFqdn string = enableSaaSComponents ? sqlDatabase.outputs.sqlServerFqdn : ''
output redisCacheHostname string = enableSaaSComponents ? redisCache.outputs.redisCacheHostName : ''
output applicationInsightsKey string = enableSaaSComponents ? appService.outputs.applicationInsightsInstrumentationKey : ''