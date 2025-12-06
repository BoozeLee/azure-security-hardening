// Security Center Configuration - Maximum Protection
// High-threat environment protection

targetScope = 'subscription'

@description('Security contact email for alerts')
param securityContactEmail string

@description('Enable Defender for Servers')
param enableDefenderForServers bool = true

@description('Enable Defender for Storage')
param enableDefenderForStorage bool = true

@description('Enable Defender for Key Vault')
param enableDefenderForKeyVault bool = true

@description('Enable Defender for Resource Manager')
param enableDefenderForResourceManager bool = true

@description('Enable Defender for DNS')
param enableDefenderForDns bool = true

// Security Center Contact
resource securityContact 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    emails: securityContactEmail
    phone: ''
    alertNotifications: {
      state: 'On'
      minimalSeverity: 'Low'
    }
    notificationsByRole: {
      state: 'On'
      roles: [
        'Owner'
        'Contributor'
      ]
    }
  }
}

// Defender for Servers
resource defenderForServers 'Microsoft.Security/pricings@2022-03-01' = if (enableDefenderForServers) {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Storage
resource defenderForStorage 'Microsoft.Security/pricings@2022-03-01' = if (enableDefenderForStorage) {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Key Vault
resource defenderForKeyVault 'Microsoft.Security/pricings@2022-03-01' = if (enableDefenderForKeyVault) {
  name: 'KeyVaults'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for Resource Manager
resource defenderForResourceManager 'Microsoft.Security/pricings@2022-03-01' = if (enableDefenderForResourceManager) {
  name: 'Arm'
  properties: {
    pricingTier: 'Standard'
  }
}

// Defender for DNS
resource defenderForDns 'Microsoft.Security/pricings@2022-03-01' = if (enableDefenderForDns) {
  name: 'Dns'
  properties: {
    pricingTier: 'Standard'
  }
}

// Security Center Auto Provisioning
resource autoProvisioning 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: 'On'
  }
}

// Outputs
output securityContactEmail string = securityContact.properties.emails
