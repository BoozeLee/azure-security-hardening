// Azure Action Groups Configuration
// Creates action groups for security alerts, budget notifications, and automation

@description('Resource group location')
param location string = resourceGroup().location

@description('Email address for security notifications')
param securityContactEmail string

@description('Optional webhook URL for qwe notifications')
param qweWebhookUrl string = ''

@description('Resource prefix for naming')
param resourcePrefix string = 'sec-bsp'

@description('Environment name')
param environmentName string = 'prod'

@description('Tags for resources')
param tags object = {}

// Security Alerts Action Group
resource securityAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${resourcePrefix}-security-ag-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'SecAlert'
    enabled: true
    emailReceivers: [
      {
        name: 'SecurityTeam'
        emailAddress: securityContactEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: !empty(qweWebhookUrl)
      ? [
          {
            name: 'qweNotification'
            serviceUri: qweWebhookUrl
            useCommonAlertSchema: true
          }
        ]
      : []
  }
}

// Budget Alerts Action Group
resource budgetAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${resourcePrefix}-budget-ag-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'BudgetAlert'
    enabled: true
    emailReceivers: [
      {
        name: 'BudgetContact'
        emailAddress: securityContactEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: !empty(qweWebhookUrl)
      ? [
          {
            name: 'qweBudgetNotification'
            serviceUri: qweWebhookUrl
            useCommonAlertSchema: true
          }
        ]
      : []
  }
}

// Critical Alerts Action Group (for immediate response)
resource criticalAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${resourcePrefix}-critical-ag-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'Critical'
    enabled: true
    emailReceivers: [
      {
        name: 'CriticalContact'
        emailAddress: securityContactEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: !empty(qweWebhookUrl)
      ? [
          {
            name: 'qweCriticalNotification'
            serviceUri: qweWebhookUrl
            useCommonAlertSchema: true
          }
        ]
      : []
  }
}

// Outputs
output securityActionGroupId string = securityAlertsActionGroup.id
output budgetActionGroupId string = budgetAlertsActionGroup.id
output criticalActionGroupId string = criticalAlertsActionGroup.id
output securityActionGroupName string = securityAlertsActionGroup.name
output budgetActionGroupName string = budgetAlertsActionGroup.name
output criticalActionGroupName string = criticalAlertsActionGroup.name
