// Network Security Configuration - Maximum Protection
// High-threat environment protection

@description('Virtual Network name')
param vnetName string

@description('Network Security Group name')
param nsgName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// Network Security Group with strict rules
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // Deny all inbound traffic by default
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Inbound'
          description: 'Deny all inbound traffic by default'
        }
      }
      // Allow only Azure Load Balancer health probes
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          description: 'Allow Azure Load Balancer health probes'
        }
      }
      // Allow outbound HTTPS for Azure services only
      {
        name: 'AllowOutboundHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
          description: 'Allow outbound HTTPS to Azure services'
        }
      }
      // Deny all other outbound traffic
      {
        name: 'DenyAllOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4000
          direction: 'Outbound'
          description: 'Deny all other outbound traffic'
        }
      }
    ]
  }
}

// Virtual Network with maximum security
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: true
    ddosProtectionPlan: {
      id: ddosProtectionPlan.id
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// DDoS Protection Plan
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-09-01' = {
  name: '${vnetName}-ddos-plan'
  location: location
  tags: tags
  properties: {}
}

// Network Watcher for monitoring
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-09-01' = {
  name: 'NetworkWatcher_${location}'
  location: location
  tags: tags
  properties: {}
}

// Flow logs for NSG monitoring
resource flowLogs 'Microsoft.Network/networkWatchers/flowLogs@2023-09-01' = {
  name: '${networkWatcher.name}/${nsgName}-flowlogs'
  location: location
  tags: tags
  properties: {
    targetResourceId: networkSecurityGroup.id
    storageId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Storage/storageAccounts/secbspsaprod${uniqueString(resourceGroup().id)}'
    enabled: true
    retentionPolicy: {
      days: 90
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}

// Outputs
output vnetId string = virtualNetwork.id
output subnetId string = virtualNetwork.properties.subnets[0].id
output nsgId string = networkSecurityGroup.id
