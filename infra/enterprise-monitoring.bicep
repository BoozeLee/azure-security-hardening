// Enterprise Monitoring and Alerting
// Implements enterprise-grade monitoring, dashboards, and alerts

targetScope = 'resourceGroup'

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Action group name for alerts')
param actionGroupName string

@description('Alert notification emails')
param notificationEmails array

@description('Location for resources')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// Application Insights for enterprise application monitoring
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'enterprise-appinsights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 90
  }
}

// Enterprise Action Group for Critical Alerts
resource criticalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'CritAlert'
    enabled: true
    emailReceivers: [for (email, i) in notificationEmails: {
      name: 'email-${i}'
      emailAddress: email
      useCommonAlertSchema: true
    }]
    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    voiceReceivers: []
  }
}

// Security Alert - Failed Authentication Attempts
resource failedAuthAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'FailedAuthenticationAlert'
  location: location
  tags: tags
  properties: {
    displayName: 'High Number of Failed Authentication Attempts'
    description: 'Triggers when there are more than 10 failed authentication attempts in 5 minutes'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'SecurityEvent | where EventID == 4625 | summarize count() by Computer | where count_ > 10'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Security Alert - Suspicious Network Activity
resource suspiciousNetworkAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SuspiciousNetworkActivity'
  location: location
  tags: tags
  properties: {
    displayName: 'Suspicious Network Activity Detected'
    description: 'Triggers when unusual network patterns are detected'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'AzureNetworkAnalytics_CL | where FlowType_s == "MaliciousFlow" | summarize count() | where count_ > 0'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Performance Alert - High CPU Usage
resource highCpuAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'HighCPUUsage'
  location: location
  tags: tags
  properties: {
    displayName: 'High CPU Usage Alert'
    description: 'Triggers when CPU usage exceeds 90% for 15 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where CounterName == "% Processor Time" | summarize avg(CounterValue) by Computer | where avg_CounterValue > 90'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 90
          failingPeriods: {
            numberOfEvaluationPeriods: 3
            minFailingPeriodsToAlert: 3
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Performance Alert - High Memory Usage
resource highMemoryAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'HighMemoryUsage'
  location: location
  tags: tags
  properties: {
    displayName: 'High Memory Usage Alert'
    description: 'Triggers when memory usage exceeds 90% for 15 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'Perf | where CounterName == "% Committed Bytes In Use" | summarize avg(CounterValue) by Computer | where avg_CounterValue > 90'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 90
          failingPeriods: {
            numberOfEvaluationPeriods: 3
            minFailingPeriodsToAlert: 3
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Security Alert - Key Vault Access Anomaly
resource keyVaultAnomalyAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'KeyVaultAccessAnomaly'
  location: location
  tags: tags
  properties: {
    displayName: 'Key Vault Access Anomaly'
    description: 'Triggers when unusual Key Vault access patterns are detected'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics | where ResourceProvider == "MICROSOFT.KEYVAULT" | where ResultType != "Success" | summarize count() | where count_ > 5'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Security Alert - Storage Account Unusual Activity
resource storageAnomalyAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'StorageAccountAnomaly'
  location: location
  tags: tags
  properties: {
    displayName: 'Storage Account Unusual Activity'
    description: 'Triggers when unusual storage access patterns are detected'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT15M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT1H'
    criteria: {
      allOf: [
        {
          query: 'StorageBlobLogs | where StatusCode >= 400 | summarize count() | where count_ > 100'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Availability Alert - Service Health
resource serviceHealthAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'ServiceHealthAlert'
  location: location
  tags: tags
  properties: {
    displayName: 'Service Availability Alert'
    description: 'Triggers when service availability drops below 99.9%'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: 'AzureMetrics | where MetricName == "Availability" | summarize avg(Average) | where avg_Average < 99.9'
          timeAggregation: 'Average'
          operator: 'LessThan'
          threshold: 99
          failingPeriods: {
            numberOfEvaluationPeriods: 2
            minFailingPeriodsToAlert: 2
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Cost Alert - Unexpected Cost Increase
resource costAnomalyAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'UnexpectedCostIncrease'
  location: location
  tags: tags
  properties: {
    displayName: 'Unexpected Cost Increase'
    description: 'Triggers when daily cost increases by more than 50% compared to previous day'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT1H'
    scopes: [
      logAnalyticsWorkspaceId
    ]
    windowSize: 'PT24H'
    criteria: {
      allOf: [
        {
          query: 'Usage | summarize sum(Quantity) by bin(TimeGenerated, 1d) | extend PrevDay = prev(sum_Quantity, 1) | where sum_Quantity > PrevDay * 1.5'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalActionGroup.id
      ]
    }
  }
}

// Outputs
output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output actionGroupId string = criticalActionGroup.id
