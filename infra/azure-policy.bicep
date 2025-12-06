// Azure Policy Assignment for Security Baseline
// High-threat environment compliance and governance

targetScope = 'resourceGroup'

@description('Policy assignment name')
param policyAssignmentName string

// Security Baseline Policy Initiative Assignment
resource securityBaselineAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  properties: {
    displayName: 'Azure Security Baseline - High Threat Environment'
    description: 'Assigns the Azure Security Baseline policy initiative for maximum protection'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab'
    parameters: {
      requiredRetentionDays: {
        value: '90'
      }
      enableLogAnalytics: {
        value: true
      }
    }
    enforcementMode: 'Default'
    nonComplianceMessages: [
      {
        message: 'This resource does not meet security baseline requirements for high-threat environments'
      }
    ]
  }
}

// Output
output securityBaselineAssignmentId string = securityBaselineAssignment.id
