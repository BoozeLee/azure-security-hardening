// Redis Cache for SaaS - Session Management & Caching
// High-performance, secure caching layer

@description('Redis Cache name')
param redisCacheName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Subnet ID for private endpoint')
param subnetId string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

@description('Redis SKU')
param redisSku string = 'Premium'

@description('Redis Family')
param redisFamily string = 'P'

@description('Redis Capacity')
param redisCapacity int = 1

// Redis Cache with maximum security
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisCacheName
  location: location
  tags: tags
  properties: {
    sku: {
      name: redisSku
      family: redisFamily
      capacity: redisCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled' // Private endpoints only
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
      'maxmemory-reserved': '50'
      'maxfragmentationmemory-reserved': '50'
    }
    redisVersion: '6'
    replicasPerMaster: 1
    replicasPerPrimary: 1
    shardCount: 0
    zoneRedundant: true
  }
}

// Private Endpoint for Redis
resource redisPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: '${redisCacheName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'redisConnection'
        properties: {
          privateLinkServiceId: redisCache.id
          groupIds: ['redisCache']
        }
      }
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: redisCache
  name: '${redisCacheName}-diagnostics'
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
output redisCacheId string = redisCache.id
output redisCacheName string = redisCache.name
output redisCacheHostName string = redisCache.properties.hostName
output redisCacheSslPort int = redisCache.properties.sslPort