// Azure Policy Assignment for Security Baseline
// High-threat environment compliance and governance

@description('Policy assignment name')
param policyAssignmentName string

@description('Resource group ID')
param resourceGroupId string

@description('Resource tags')
param tags object = {}

// Security Baseline Policy Initiative Assignment
resource securityBaselineAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  scope: resourceGroupId
  properties: {
    displayName: 'Azure Security Baseline - High Threat Environment'
    description: 'Assigns the Azure Security Baseline policy initiative for maximum protection'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab'
    parameters: {
      // Enforce specific security requirements
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

// Deny Public Network Access Policy
resource denyPublicNetworkAccess 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'deny-public-network-access'
  scope: resourceGroupId
  properties: {
    displayName: 'Deny Public Network Access'
    description: 'Denies creation of resources with public network access enabled'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/6edd7eda-6dd8-40f7-810d-67160c639cd9'
    enforcementMode: 'Default'
    parameters: {}
    nonComplianceMessages: [
      {
        message: 'Public network access is not allowed in high-threat environments'
      }
    ]
  }
}

// Require Encryption in Transit Policy
resource requireEncryptionInTransit 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'require-encryption-in-transit'
  scope: resourceGroupId
  properties: {
    displayName: 'Require Encryption in Transit'
    description: 'Requires all resources to use encryption in transit'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9'
    enforcementMode: 'Default'
    parameters: {}
    nonComplianceMessages: [
      {
        message: 'All data must be encrypted in transit for security compliance'
      }
    ]
  }
}

// Require Resource Tags Policy
resource requireResourceTags 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'require-resource-tags'
  scope: resourceGroupId
  properties: {
    displayName: 'Require Resource Tags'
    description: 'Requires all resources to have specific tags for security tracking'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025'
    enforcementMode: 'Default'
    parameters: {
      tagNames: {
        value: [
          'Environment'
          'Owner'
          'ThreatLevel'
          'Compliance'
        ]
      }
    }
    nonComplianceMessages: [
      {
        message: 'All resources must be properly tagged for security and compliance tracking'
      }
    ]
  }
}

// Diagnostic Settings Policy
resource requireDiagnosticSettings 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'require-diagnostic-settings'
  scope: resourceGroupId
  properties: {
    displayName: 'Require Diagnostic Settings'
    description: 'Requires all resources to have diagnostic settings enabled'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/7f89b1eb-583c-429a-8828-af049802c1d9'
    enforcementMode: 'Default'
    parameters: {
      logAnalytics: {
        value: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.OperationalInsights/workspaces/sec-bsp-law-prod'
      }
    }
    nonComplianceMessages: [
      {
        message: 'Diagnostic settings must be enabled for security monitoring and compliance'
      }
    ]
  }
}

// Output
output securityBaselineAssignmentId string = securityBaselineAssignment.id
output policyAssignments array = [
  securityBaselineAssignment.id
  denyPublicNetworkAccess.id
  requireEncryptionInTransit.id
  requireResourceTags.id
  requireDiagnosticSettings.id
]
