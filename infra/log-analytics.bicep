// Log Analytics Workspace Configuration
// High-threat environment monitoring and logging

@description('Log Analytics Workspace name')
param workspaceName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Data retention in days')
param retentionInDays int = 90

@description('Resource tags')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: false
    }
    workspaceCapping: {
      dailyQuotaGb: 10 // Set appropriate daily quota
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
  }
}

// Security Solutions
resource securitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'Security(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Azure Activity solution
resource azureActivitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'AzureActivity(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'AzureActivity(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/AzureActivity'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Security Alerts and Monitoring Queries
resource securityAlertQueries 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalyticsWorkspace
  name: 'SecurityAlerts'
  properties: {
    displayName: 'Security Alerts'
    category: 'Security'
    query: '''
      SecurityAlert
      | where TimeGenerated > ago(24h)
      | where AlertSeverity in ("High", "Medium")
      | summarize count() by AlertName, AlertSeverity
      | order by count_ desc
    '''
    functionAlias: 'SecurityAlerts'
  }
}

// Failed Login Attempts Query
resource failedLoginsQuery 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalyticsWorkspace
  name: 'FailedLogins'
  properties: {
    displayName: 'Failed Login Attempts'
    category: 'Security'
    query: '''
      SigninLogs
      | where TimeGenerated > ago(1h)
      | where ResultType != 0
      | summarize FailedAttempts = count() by UserPrincipalName, IPAddress
      | where FailedAttempts > 5
      | order by FailedAttempts desc
    '''
    functionAlias: 'FailedLogins'
  }
}

// Output
output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
