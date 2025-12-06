// API Management for SaaS - Secure API Gateway
// Multi-tenant API management with rate limiting and authentication

@description('API Management service name')
param apimName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Publisher email')
param publisherEmail string

@description('Publisher name')
param publisherName string

@description('Subnet ID for APIM')
param subnetId string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

@description('SKU for API Management')
param skuName string = 'Developer'

@description('SKU capacity')
param skuCapacity int = 1

// API Management Service
resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'True'
    }
    publicNetworkAccess: 'Disabled'
  }
}

// API for SaaS Tenants
resource tenantsApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'tenants-api'
  properties: {
    displayName: 'Tenants API'
    path: 'tenants'
    protocols: ['https']
    subscriptionRequired: true
    isCurrent: true
    apiVersion: 'v1'
    apiVersionSetId: tenantsApiVersionSet.id
  }
}

// API Version Set
resource tenantsApiVersionSet 'Microsoft.ApiManagement/service/apiVersionSets@2023-05-01-preview' = {
  parent: apiManagement
  name: 'tenants-api-version-set'
  properties: {
    displayName: 'Tenants API'
    versioningScheme: 'Segment'
  }
}

// Rate Limiting Policy (per tenant)
resource rateLimitPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: tenantsApi
  name: 'policy'
  properties: {
    value: '''
    <policies>
      <inbound>
        <base />
        <rate-limit-by-key calls="1000" renewal-period="3600" counter-key="@(context.Subscription.Id)" />
        <quota-by-key calls="10000" renewal-period="86400" counter-key="@(context.Subscription.Id)" />
        <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
          <openid-config url="https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration" />
          <required-claims>
            <claim name="aud" match="all">
              <value>api://saas-platform</value>
            </claim>
          </required-claims>
        </validate-jwt>
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
    '''
    format: 'xml'
  }
}

// Product for Free Tier
resource freeProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apiManagement
  name: 'free-tier'
  properties: {
    displayName: 'Free Tier'
    description: 'Free tier with limited API calls'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

// Product for Premium Tier
resource premiumProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apiManagement
  name: 'premium-tier'
  properties: {
    displayName: 'Premium Tier'
    description: 'Premium tier with unlimited API calls'
    subscriptionRequired: true
    approvalRequired: true
    state: 'published'
  }
}

// Link API to Products
resource freeProductApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: freeProduct
  name: tenantsApi.name
}

resource premiumProductApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: premiumProduct
  name: tenantsApi.name
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apiManagement
  name: '${apimName}-diagnostics'
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
output apimId string = apiManagement.id
output apimName string = apiManagement.name
output apimGatewayUrl string = apiManagement.properties.gatewayUrl
output apimPrincipalId string = apiManagement.identity.principalId