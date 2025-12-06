// Enterprise Network Security - Azure Firewall and WAF
// Implements enterprise-grade network protection

targetScope = 'resourceGroup'

@description('Azure Firewall name')
param firewallName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Virtual Network name for firewall')
param vnetName string

@description('Enable Azure Firewall Premium SKU')
param enablePremiumFirewall bool = true

@description('Enable threat intelligence')
param enableThreatIntelligence bool = true

@description('Enable DNS proxy')
param enableDnsProxy bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

// Reference to existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

// Public IP for Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${firewallName}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    ddosSettings: {
      protectionMode: 'Enabled' // DDoS Protection
    }
  }
}

// Azure Firewall Subnet (must be named 'AzureFirewallSubnet')
resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: '10.0.1.0/26' // /26 minimum for Azure Firewall
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// Azure Firewall Policy - Enterprise Grade
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: '${firewallName}-policy'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: enablePremiumFirewall ? 'Premium' : 'Standard'
    }
    threatIntelMode: enableThreatIntelligence ? 'Alert' : 'Off'
    threatIntelWhitelist: {
      ipAddresses: []
      fqdns: []
    }
    intrusionDetection: enablePremiumFirewall ? {
      mode: 'Alert'
      configuration: {
        signatureOverrides: []
        bypassTrafficSettings: []
      }
    } : null
    dnsSettings: enableDnsProxy ? {
      servers: []
      enableProxy: true
    } : null
    insights: {
      isEnabled: true
      retentionDays: 90
      logAnalyticsResources: {
        workspaces: [
          {
            workspaceId: logAnalyticsWorkspaceId
          }
        ]
      }
    }
  }
}

// Application Rule Collection - Enterprise Outbound Rules
resource appRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'EnterpriseApplicationRules'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowAzureServices'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzureMonitor'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.ods.opinsights.azure.com'
              '*.oms.opinsights.azure.com'
              '*.monitoring.azure.com'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzureBackup'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              '*.backup.windowsazure.com'
              '*.blob.${environment().suffixes.storage}'
            ]
            sourceAddresses: [
              '*'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowWindowsUpdate'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            targetFqdns: [
              '*.windowsupdate.microsoft.com'
              '*.update.microsoft.com'
              '*.windowsupdate.com'
            ]
            sourceAddresses: [
              '*'
            ]
          }
        ]
      }
    ]
  }
}

// Network Rule Collection - Enterprise Network Rules
resource networkRuleCollection 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'EnterpriseNetworkRules'
  dependsOn: [
    appRuleCollection
  ]
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AllowCriticalServices'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowDNS'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '53'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowNTP'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
    ]
  }
}

// Azure Firewall - Premium Enterprise Grade
resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: enablePremiumFirewall ? 'Premium' : 'Standard'
    }
    threatIntelMode: enableThreatIntelligence ? 'Alert' : 'Off'
    ipConfigurations: [
      {
        name: 'firewallIpConfig'
        properties: {
          publicIPAddress: {
            id: firewallPublicIP.id
          }
          subnet: {
            id: firewallSubnet.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

// Diagnostic Settings for Azure Firewall
resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: firewall
  name: '${firewallName}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Public IP for Application Gateway (WAF)
resource wafPublicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'waf-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    ddosSettings: {
      protectionMode: 'Enabled'
    }
  }
}

// Application Gateway Subnet
resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  parent: vnet
  name: 'AppGatewaySubnet'
  dependsOn: [
    firewallSubnet
  ]
  properties: {
    addressPrefix: '10.0.2.0/26'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

// Web Application Firewall (WAF) Policy
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: 'enterprise-waf-policy'
  location: location
  tags: tags
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
    customRules: [
      {
        name: 'BlockSuspiciousUserAgents'
        priority: 100
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'User-Agent'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'bot'
              'crawler'
              'spider'
            ]
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
      {
        name: 'RateLimitPerIP'
        priority: 200
        ruleType: 'RateLimitRule'
        rateLimitDuration: 'OneMin'
        rateLimitThreshold: 100
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '0.0.0.0/0'
            ]
          }
        ]
      }
    ]
  }
}

// Application Gateway with WAF - Enterprise Grade
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: 'enterprise-waf'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: wafPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port443'
        properties: {
          port: 443
        }
      }
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServicePool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appServiceHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'enterprise-waf', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'enterprise-waf', 'port443')
          }
          protocol: 'Https'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'appServiceRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'enterprise-waf', 'appServiceHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'enterprise-waf', 'appServicePool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'enterprise-waf', 'appServiceBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 10
    }
  }
}

// Diagnostic Settings for Application Gateway
resource wafDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: applicationGateway
  name: 'waf-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Outputs
output firewallId string = firewall.id
output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output wafId string = applicationGateway.id
output wafPublicIP string = wafPublicIP.properties.ipAddress
