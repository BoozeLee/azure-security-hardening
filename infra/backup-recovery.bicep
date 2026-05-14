// Enterprise Backup and Disaster Recovery Configuration
// Implements enterprise-grade backup and recovery capabilities

targetScope = 'resourceGroup'

@description('Recovery Services Vault name')
param vaultName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Backup retention in days')
param backupRetentionDays int = 90

@description('Enable geo-redundant backup')
param enableGeoRedundantBackup bool = true

@description('Enable cross-region restore')
param enableCrossRegionRestore bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Resource tags')
param tags object = {}

// Recovery Services Vault for Enterprise Backup
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = {
  name: vaultName
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Disabled' // Enterprise security: no public access
    encryption: {
      keyVaultProperties: null
      infrastructureEncryption: 'Enabled'
    }
    securitySettings: {
      immutabilitySettings: {
        state: 'Unlocked'
      }
      softDeleteSettings: {
        softDeleteState: 'Enabled'
        softDeleteRetentionPeriodInDays: 14
      }
    }
  }
}

// Backup Storage Configuration
resource backupStorageConfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2023-04-01' = {
  parent: recoveryServicesVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: enableGeoRedundantBackup ? 'GeoRedundant' : 'LocallyRedundant'
    crossRegionRestoreFlag: enableCrossRegionRestore
  }
}

// Enhanced Azure VM Backup Policy - Enterprise Grade
resource vmBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: recoveryServicesVault
  name: 'EnterpriseVMBackupPolicy'
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2024-01-01T02:00:00Z' // 2 AM UTC daily backup
      ]
      scheduleWeeklyFrequency: 0
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2024-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: backupRetentionDays
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2024-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 52 // 1 year of weekly backups
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2024-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 60 // 5 years of monthly backups
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        monthsOfYear: [
          'January'
        ]
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2024-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 10 // 10 years of yearly backups
          durationType: 'Years'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// Azure SQL Database Backup Policy - Enterprise Grade
resource sqlBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: recoveryServicesVault
  name: 'EnterpriseSQLBackupPolicy'
  properties: {
    backupManagementType: 'AzureWorkload'
    workLoadType: 'SQLDataBase'
    settings: {
      timeZone: 'UTC'
      issqlcompression: true
      isCompression: true
    }
    subProtectionPolicy: [
      {
        policyType: 'Full'
        schedulePolicy: {
          schedulePolicyType: 'SimpleSchedulePolicy'
          scheduleRunFrequency: 'Weekly'
          scheduleRunDays: [
            'Sunday'
          ]
          scheduleRunTimes: [
            '2024-01-01T02:00:00Z'
          ]
        }
        retentionPolicy: {
          retentionPolicyType: 'LongTermRetentionPolicy'
          weeklySchedule: {
            daysOfTheWeek: [
              'Sunday'
            ]
            retentionTimes: [
              '2024-01-01T02:00:00Z'
            ]
            retentionDuration: {
              count: 52
              durationType: 'Weeks'
            }
          }
          monthlySchedule: {
            retentionScheduleFormatType: 'Weekly'
            retentionScheduleWeekly: {
              daysOfTheWeek: [
                'Sunday'
              ]
              weeksOfTheMonth: [
                'First'
              ]
            }
            retentionTimes: [
              '2024-01-01T02:00:00Z'
            ]
            retentionDuration: {
              count: 60
              durationType: 'Months'
            }
          }
          yearlySchedule: {
            retentionScheduleFormatType: 'Weekly'
            monthsOfYear: [
              'January'
            ]
            retentionScheduleWeekly: {
              daysOfTheWeek: [
                'Sunday'
              ]
              weeksOfTheMonth: [
                'First'
              ]
            }
            retentionTimes: [
              '2024-01-01T02:00:00Z'
            ]
            retentionDuration: {
              count: 10
              durationType: 'Years'
            }
          }
        }
      }
      {
        policyType: 'Differential'
        schedulePolicy: {
          schedulePolicyType: 'SimpleSchedulePolicy'
          scheduleRunFrequency: 'Weekly'
          scheduleRunDays: [
            'Monday'
            'Tuesday'
            'Wednesday'
            'Thursday'
            'Friday'
            'Saturday'
          ]
          scheduleRunTimes: [
            '2024-01-01T02:00:00Z'
          ]
        }
        retentionPolicy: {
          retentionPolicyType: 'SimpleRetentionPolicy'
          retentionDuration: {
            count: 30
            durationType: 'Days'
          }
        }
      }
      {
        policyType: 'Log'
        schedulePolicy: {
          schedulePolicyType: 'LogSchedulePolicy'
          scheduleFrequencyInMins: 120 // Every 2 hours
        }
        retentionPolicy: {
          retentionPolicyType: 'SimpleRetentionPolicy'
          retentionDuration: {
            count: 15
            durationType: 'Days'
          }
        }
      }
    ]
  }
}

// Azure File Share Backup Policy
resource fileShareBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: recoveryServicesVault
  name: 'EnterpriseFileShareBackupPolicy'
  properties: {
    backupManagementType: 'AzureStorage'
    workLoadType: 'AzureFileShare'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2024-01-01T02:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2024-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: backupRetentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// Diagnostic Settings for Recovery Services Vault
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: recoveryServicesVault
  name: '${vaultName}-diagnostics'
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
        category: 'Health'
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
output recoveryServicesVaultId string = recoveryServicesVault.id
output recoveryServicesVaultName string = recoveryServicesVault.name
output vmBackupPolicyId string = vmBackupPolicy.id
output sqlBackupPolicyId string = sqlBackupPolicy.id
output fileShareBackupPolicyId string = fileShareBackupPolicy.id
