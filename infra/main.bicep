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
    enableDefenderForAppService: true
    enableDefenderForContainers: true
    enableDefenderForSql: true
    enableDefenderForOpenSourceDatabases: true
    enableDefenderForCosmosDb: true
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

// Azure Automation Account with Security Runbooks
module automationAccount 'automation-account.bicep' = {
  name: 'automationAccountDeployment'
  scope: resourceGroup
  params: {
    automationAccountName: '${resourcePrefix}-auto-${environmentName}'
    location: location
    sku: 'Basic'
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// Enterprise Compliance Frameworks
module complianceFrameworks 'compliance-frameworks.bicep' = {
  name: 'complianceFrameworksDeployment'
  scope: subscription()
  params: {
    enableISO27001: true
    enableSOC2: true
    enableHIPAA: true
    enablePCIDSS: true
    enableNIST: true
  }
}

// Enterprise Backup and Disaster Recovery
module backupRecovery 'backup-recovery.bicep' = {
  name: 'backupRecoveryDeployment'
  scope: resourceGroup
  params: {
    vaultName: '${resourcePrefix}-rsv-${environmentName}'
    location: location
    backupRetentionDays: 90
    enableGeoRedundantBackup: true
    enableCrossRegionRestore: true
    tags: tags
  }
}

// Enterprise Network Security (Firewall and WAF)
module enterpriseNetworkSecurity 'enterprise-network-security.bicep' = {
  name: 'enterpriseNetworkSecurityDeployment'
  scope: resourceGroup
  params: {
    firewallName: '${resourcePrefix}-fw-${environmentName}'
    vnetName: networkSecurity.outputs.vnetName
    location: location
    enablePremiumFirewall: true
    enableThreatIntelligence: true
    enableDnsProxy: true
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Enterprise Cost Management
module costManagement 'cost-management.bicep' = {
  name: 'costManagementDeployment'
  scope: subscription()
  params: {
    monthlyBudgetAmount: 10000
    notificationEmails: [securityContactEmail]
    resourceGroupName: resourceGroupName
  }
}

// Enterprise Monitoring and Alerting
module enterpriseMonitoring 'enterprise-monitoring.bicep' = {
  name: 'enterpriseMonitoringDeployment'
  scope: resourceGroup
  params: {
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    actionGroupName: '${resourcePrefix}-critical-alerts-${environmentName}'
    notificationEmails: [securityContactEmail]
    location: location
    tags: tags
  }
}

// Enterprise RBAC (optional - requires group IDs to be configured)
// Uncomment and configure with your Azure AD group IDs
// module enterpriseRBAC 'enterprise-rbac.bicep' = {
//   name: 'enterpriseRBACDeployment'
//   scope: resourceGroup
//   params: {
//     securityTeamGroupId: '<your-security-team-group-id>'
//     devTeamGroupId: '<your-dev-team-group-id>'
//     opsTeamGroupId: '<your-ops-team-group-id>'
//     enableSecurityTeam: true
//     enableDevTeam: true
//     enableOpsTeam: true
//   }
// }
// Outputs
output resourceGroupName string = resourceGroup.name
output automationAccountId string = automationAccount.outputs.automationAccountId
output automationPrincipalId string = automationAccount.outputs.principalId
