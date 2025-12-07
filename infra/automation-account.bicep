// Azure Automation Account with Security Runbooks
// Provides automated security compliance checks and resource management

@description('Name of the Automation Account')
param automationAccountName string = 'sec-automation-${uniqueString(resourceGroup().id)}'

@description('Location for the Automation Account')
param location string = resourceGroup().location

@description('SKU for the Automation Account')
@allowed([
  'Free'
  'Basic'
])
param sku string = 'Basic'

@description('Tags to apply to resources')
param tags object = {
  Environment: 'Production'
  Purpose: 'Security-Automation'
  ManagedBy: 'Bicep'
}

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Schedule start time (must be at least 5 minutes in the future)')
param scheduleStartTime string = utcNow('u')

@description('Enable public network access for automation account')
param enablePublicNetworkAccess bool = true

// Automation Account
resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: automationAccountName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: sku
    }
    encryption: {
      keySource: 'Microsoft.Automation'
    }
    // Public network access enabled by default to allow runbooks to access Azure APIs
    // Set to false only if private endpoints are configured
    publicNetworkAccess: enablePublicNetworkAccess
    disableLocalAuth: false
  }
}

// Security Compliance Check Runbook
// Note: Runbook scripts are located in infra/runbooks/ directory
// For deployment, upload scripts to Azure Storage or use Azure DevOps/GitHub for publishing
resource complianceRunbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'Security-ComplianceCheck'
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell72'
    logProgress: true
    logVerbose: true
    description: 'Automated security compliance scanning for Azure resources. Script: infra/runbooks/Security-ComplianceCheck.ps1'
  }
}

// Resource Tagging Runbook
resource taggingRunbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'Resource-AutoTagging'
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell72'
    logProgress: true
    logVerbose: true
    description: 'Automatically tag Azure resources for compliance and governance. Script: infra/runbooks/Resource-AutoTagging.ps1'
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'automation-diagnostics'
  scope: automationAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'JobLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'JobStreams'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'DscNodeStatus'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

// Schedule for Compliance Check (Daily at 2 AM UTC)
resource complianceSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: 'DailyComplianceCheck'
  properties: {
    description: 'Run security compliance check daily'
    startTime: dateTimeAdd(scheduleStartTime, 'PT1H') // Start 1 hour from schedule start time
    expiryTime: dateTimeAdd(scheduleStartTime, 'P1Y') // Expires in 1 year
    interval: 1
    frequency: 'Day'
    timeZone: 'UTC'
  }
}

// Link Schedule to Compliance Runbook
resource complianceJobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2023-11-01' = {
  parent: automationAccount
  name: guid(automationAccount.id, complianceRunbook.id, complianceSchedule.id)
  properties: {
    runbook: {
      name: complianceRunbook.name
    }
    schedule: {
      name: complianceSchedule.name
    }
  }
}

// Outputs
output automationAccountId string = automationAccount.id
output automationAccountName string = automationAccount.name
output principalId string = automationAccount.identity.principalId
output complianceRunbookName string = complianceRunbook.name
output taggingRunbookName string = taggingRunbook.name
