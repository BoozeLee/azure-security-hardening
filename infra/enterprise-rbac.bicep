// Enterprise RBAC Role Assignments
// Implements enterprise team-based access control

targetScope = 'resourceGroup'

@description('Security team Azure AD group object ID')
param securityTeamGroupId string = ''

@description('Development team Azure AD group object ID')
param devTeamGroupId string = ''

@description('Operations team Azure AD group object ID')
param opsTeamGroupId string = ''

@description('Enable Security team roles')
param enableSecurityTeam bool = true

@description('Enable Development team roles')
param enableDevTeam bool = true

@description('Enable Operations team roles')
param enableOpsTeam bool = true

// Security Team - Security Admin Role
resource securityAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSecurityTeam && securityTeamGroupId != '') {
  name: guid(resourceGroup().id, securityTeamGroupId, 'Security Admin')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb1c8493-542b-48eb-b624-b4c8fea62acd') // Security Admin
    principalId: securityTeamGroupId
    principalType: 'Group'
    description: 'Grants Security Admin permissions to Security team for managing security policies and configurations'
  }
}

// Security Team - Security Reader Role
resource securityReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSecurityTeam && securityTeamGroupId != '') {
  name: guid(resourceGroup().id, securityTeamGroupId, 'Security Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '39bc4728-0917-49c7-9d2c-d95423bc2eb4') // Security Reader
    principalId: securityTeamGroupId
    principalType: 'Group'
    description: 'Grants Security Reader permissions to Security team for viewing security configurations'
  }
}

// Security Team - Key Vault Administrator
resource keyVaultAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableSecurityTeam && securityTeamGroupId != '') {
  name: guid(resourceGroup().id, securityTeamGroupId, 'Key Vault Admin')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b002-a05e72a3c5b8') // Key Vault Administrator
    principalId: securityTeamGroupId
    principalType: 'Group'
    description: 'Grants Key Vault Administrator permissions to Security team for managing secrets and keys'
  }
}

// Development Team - Contributor Role (scoped to resource group)
resource devContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableDevTeam && devTeamGroupId != '') {
  name: guid(resourceGroup().id, devTeamGroupId, 'Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: devTeamGroupId
    principalType: 'Group'
    description: 'Grants Contributor permissions to Development team for managing resources'
  }
}

// Development Team - Storage Blob Data Contributor
resource devStorageBlobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableDevTeam && devTeamGroupId != '') {
  name: guid(resourceGroup().id, devTeamGroupId, 'Storage Blob Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: devTeamGroupId
    principalType: 'Group'
    description: 'Grants Storage Blob Data Contributor permissions to Development team for blob storage access'
  }
}

// Development Team - Key Vault Secrets User (read-only for app configs)
resource devKeyVaultSecretsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableDevTeam && devTeamGroupId != '') {
  name: guid(resourceGroup().id, devTeamGroupId, 'Key Vault Secrets User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: devTeamGroupId
    principalType: 'Group'
    description: 'Grants Key Vault Secrets User permissions to Development team for reading application secrets'
  }
}

// Operations Team - Monitoring Contributor
resource opsMonitoringRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableOpsTeam && opsTeamGroupId != '') {
  name: guid(resourceGroup().id, opsTeamGroupId, 'Monitoring Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '749f88d5-cbae-40b8-bcfc-e573ddc772fa') // Monitoring Contributor
    principalId: opsTeamGroupId
    principalType: 'Group'
    description: 'Grants Monitoring Contributor permissions to Operations team for managing monitoring and alerts'
  }
}

// Operations Team - Log Analytics Contributor
resource opsLogAnalyticsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableOpsTeam && opsTeamGroupId != '') {
  name: guid(resourceGroup().id, opsTeamGroupId, 'Log Analytics Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '92aaf0da-9dab-42b6-94a3-d43ce8d16293') // Log Analytics Contributor
    principalId: opsTeamGroupId
    principalType: 'Group'
    description: 'Grants Log Analytics Contributor permissions to Operations team for managing logs and queries'
  }
}

// Operations Team - Backup Contributor
resource opsBackupRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableOpsTeam && opsTeamGroupId != '') {
  name: guid(resourceGroup().id, opsTeamGroupId, 'Backup Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e467623-bb1f-42f4-a55d-6e525e11384b') // Backup Contributor
    principalId: opsTeamGroupId
    principalType: 'Group'
    description: 'Grants Backup Contributor permissions to Operations team for managing backups and recovery'
  }
}

// Operations Team - Reader Role (for all resources)
resource opsReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableOpsTeam && opsTeamGroupId != '') {
  name: guid(resourceGroup().id, opsTeamGroupId, 'Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    principalId: opsTeamGroupId
    principalType: 'Group'
    description: 'Grants Reader permissions to Operations team for viewing all resources'
  }
}

// Outputs
output securityTeamRoleAssignments array = enableSecurityTeam && securityTeamGroupId != '' ? [
  securityAdminRole.id
  securityReaderRole.id
  keyVaultAdminRole.id
] : []

output devTeamRoleAssignments array = enableDevTeam && devTeamGroupId != '' ? [
  devContributorRole.id
  devStorageBlobRole.id
  devKeyVaultSecretsRole.id
] : []

output opsTeamRoleAssignments array = enableOpsTeam && opsTeamGroupId != '' ? [
  opsMonitoringRole.id
  opsLogAnalyticsRole.id
  opsBackupRole.id
  opsReaderRole.id
] : []
