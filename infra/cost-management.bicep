// Enterprise Cost Management and Budgets
// Implements enterprise-grade cost tracking and budget alerts

targetScope = 'subscription'

@description('Budget amount in USD')
param monthlyBudgetAmount int = 10000

@description('Budget alert threshold percentages')
param alertThresholds array = [
  50
  75
  90
  100
  110
]

@description('Alert notification emails')
param notificationEmails array

@description('Resource Group name for scoped budget (optional)')
param resourceGroupName string = ''

// Monthly budget with multiple alert thresholds
resource monthlyBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'EnterpriseMonthlyCostBudget'
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: '2024-01-01'
      endDate: '2026-12-31'
    }
    filter: resourceGroupName != '' ? {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    } : {}
    notifications: {
      Actual_50Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[0]
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      Actual_75Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[1]
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      Actual_90Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[2]
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      Actual_100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[3]
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Actual'
      }
      Forecasted_110Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholds[4]
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
        thresholdType: 'Forecasted'
      }
    }
  }
}

// Quarterly budget for strategic planning
resource quarterlyBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'EnterpriseQuarterlyCostBudget'
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount * 3
    timeGrain: 'Quarterly'
    timePeriod: {
      startDate: '2024-01-01'
      endDate: '2026-12-31'
    }
    filter: resourceGroupName != '' ? {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    } : {}
    notifications: {
      Actual_75Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 75
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
        ]
        thresholdType: 'Actual'
      }
      Actual_100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// Annual budget for fiscal planning
resource annualBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'EnterpriseAnnualCostBudget'
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount * 12
    timeGrain: 'Annually'
    timePeriod: {
      startDate: '2024-01-01'
      endDate: '2026-12-31'
    }
    filter: resourceGroupName != '' ? {
      dimensions: {
        name: 'ResourceGroupName'
        operator: 'In'
        values: [
          resourceGroupName
        ]
      }
    } : {}
    notifications: {
      Actual_90Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 90
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
        ]
        thresholdType: 'Actual'
      }
      Actual_100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: notificationEmails
        contactRoles: [
          'Owner'
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// Outputs
output monthlyBudgetId string = monthlyBudget.id
output quarterlyBudgetId string = quarterlyBudget.id
output annualBudgetId string = annualBudget.id
