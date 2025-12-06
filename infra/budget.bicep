// Azure Budget Configuration with Alerts
// Creates monthly budget with threshold alerts and action group integration

targetScope = 'subscription'

@description('Budget name')
param budgetName string = 'monthly-security-budget'

@description('Budget amount in USD per month')
param budgetAmount int = 100

@description('Email address for budget alerts')
param contactEmail string

@description('Action group ID for budget alerts')
param actionGroupId string = ''

@description('Start date for budget (YYYY-MM-01)')
param startDate string = '${utcNow('yyyy-MM')}-01'

@description('Optional webhook URL for budget notifications')
param webhookUrl string = ''

@description('Resource group name for budget scope')
param resourceGroupName string

// Get the resource group to scope the budget
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: resourceGroupName
}

// Budget resource
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: budgetName
  scope: resourceGroup
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual_GreaterThan_50_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [
          contactEmail
        ]
        contactRoles: []
        thresholdType: 'Actual'
      }
      actual_GreaterThan_75_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 75
        contactEmails: [
          contactEmail
        ]
        contactRoles: []
        thresholdType: 'Actual'
        contactGroups: !empty(actionGroupId)
          ? [
              actionGroupId
            ]
          : []
      }
      actual_GreaterThan_90_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: [
          contactEmail
        ]
        contactRoles: []
        thresholdType: 'Actual'
        contactGroups: !empty(actionGroupId)
          ? [
              actionGroupId
            ]
          : []
      }
      actual_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          contactEmail
        ]
        contactRoles: []
        thresholdType: 'Actual'
        contactGroups: !empty(actionGroupId)
          ? [
              actionGroupId
            ]
          : []
      }
      forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [
          contactEmail
        ]
        contactRoles: []
        thresholdType: 'Forecasted'
        contactGroups: !empty(actionGroupId)
          ? [
              actionGroupId
            ]
          : []
      }
    }
  }
}

// Outputs
output budgetId string = budget.id
output budgetName string = budget.name
output budgetAmount int = budgetAmount
