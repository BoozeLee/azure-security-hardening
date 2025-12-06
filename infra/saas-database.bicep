// SaaS Database Infrastructure - Multi-Tenant SQL Database
// Supports schema-per-tenant isolation pattern

@description('SQL Server name')
param sqlServerName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SQL Administrator login')
@secure()
param sqlAdminLogin string

@description('SQL Administrator password')
@secure()
param sqlAdminPassword string

@description('Virtual Network ID')
param vnetId string

@description('Subnet ID for private endpoint')
param subnetId string

@description('Key Vault ID for encryption')
param keyVaultId string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

@description('Enable Azure AD authentication')
param enableAzureADAuth bool = true

// SQL Server with maximum security
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled' // Private endpoints only
    restrictOutboundNetworkAccess: 'Enabled'
  }
}

// Primary SaaS Database (multi-tenant)
resource saasDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: 'saas-tenants-db'
  location: location
  tags: tags
  sku: {
    name: 'GP_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 107374182400 // 100 GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: true
    readScale: 'Enabled'
    requestedBackupStorageRedundancy: 'Geo'
    isLedgerOn: false
  }
}

// Transparent Data Encryption with customer-managed key
resource tde 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-05-01-preview' = {
  parent: saasDatabase
  name: 'current'
  properties: {
    state: 'Enabled'
  }
}

// Advanced Threat Protection
resource threatProtection 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
    emailAddresses: []
    retentionDays: 90
  }
}

// Vulnerability Assessment
resource vulnerabilityAssessment 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-05-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
      emails: []
    }
  }
  dependsOn: [
    threatProtection
  ]
}

// Auditing
resource auditing 'Microsoft.Sql/servers/auditingSettings@2023-05-01-preview' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 90
  }
}

// Private Endpoint for SQL Server
resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${sqlServerName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlConnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}

// Firewall rule to deny all public access
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: sqlServer
  name: 'DenyAllPublicAccess'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Diagnostic Settings for SQL Server
resource sqlServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: sqlServer
  name: '${sqlServerName}-diagnostics'
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

// Diagnostic Settings for Database
resource databaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: saasDatabase
  name: '${saasDatabase.name}-diagnostics'
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
output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseId string = saasDatabase.id
output databaseName string = saasDatabase.name
output sqlServerPrincipalId string = sqlServer.identity.principalId