# Azure Automation Components

This directory contains Azure Automation resources for automated security compliance and resource management.

## Overview

The automation solution includes:
- **Automation Account**: Azure Automation account with system-assigned managed identity
- **Security Runbooks**: PowerShell runbooks for security compliance and resource management
- **Scheduled Jobs**: Automated daily security scans

## Components

### Automation Account (`automation-account.bicep`)

Provisions an Azure Automation account with:
- System-assigned managed identity for secure Azure resource access
- Integration with Log Analytics for diagnostics
- Private network access enforcement
- Basic SKU for cost-effective operations

**Parameters:**
- `automationAccountName`: Name of the automation account
- `location`: Azure region
- `sku`: Pricing tier (Free or Basic)
- `logAnalyticsWorkspaceId`: Log Analytics workspace for diagnostics
- `scheduleStartTime`: Start time for scheduled jobs

**Outputs:**
- `automationAccountId`: Resource ID of the automation account
- `automationAccountName`: Name of the automation account
- `principalId`: Managed identity principal ID for RBAC assignments
- `complianceRunbookName`: Name of compliance check runbook
- `taggingRunbookName`: Name of tagging runbook

### Runbooks

#### 1. Security-ComplianceCheck.ps1

Automated security compliance scanning for Azure resources.

**Checks performed:**
- Storage Accounts: HTTPS-only enforcement
- Virtual Machines: Disk encryption status
- Network Security Groups: Unrestricted RDP/SSH access
- Key Vaults: Soft delete and purge protection

**Parameters:**
- `SubscriptionId` (optional): Target subscription
- `ResourceGroupName` (optional): Target resource group

**Output:**
JSON compliance report with findings categorized by severity (Critical, High, Medium).

**Schedule:**
Runs daily at 2 AM UTC via automated schedule.

#### 2. Resource-AutoTagging.ps1

Automatically tags Azure resources for compliance and governance.

**Features:**
- Applies standard organizational tags
- Preserves existing tags
- Adds resource-type-specific tags
- Supports subscription-wide or resource group scope

**Standard Tags:**
- `ManagedBy`: Automation
- `LastTagged`: Current date
- `Environment`: Production/Staging/Dev
- `ComplianceRequired`: true

**Resource-Specific Tags:**
- Storage Accounts: `DataClassification: Confidential`
- Key Vaults: `SecurityLevel: Critical`
- Virtual Machines: `BackupRequired: true`
- Network Resources: `NetworkZone: Restricted`

**Parameters:**
- `SubscriptionId` (optional): Target subscription
- `ResourceGroupName` (optional): Target resource group
- `Environment` (optional): Environment tag value

## Deployment

### Upload Runbook Scripts

Before deploying, the runbook PowerShell scripts need to be uploaded to the automation account. After the Bicep deployment creates the runbook resources, upload the scripts:

```bash
# Upload Security Compliance Check runbook
az automation runbook replace-content \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Security-ComplianceCheck \
  --content @infra/runbooks/Security-ComplianceCheck.ps1

# Publish the runbook
az automation runbook publish \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Security-ComplianceCheck

# Upload Resource Auto-Tagging runbook
az automation runbook replace-content \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Resource-AutoTagging \
  --content @infra/runbooks/Resource-AutoTagging.ps1

# Publish the runbook
az automation runbook publish \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Resource-AutoTagging
```

### Using Bicep

Deploy as part of main infrastructure:

```bash
az deployment sub create \
  --location westeurope \
  --template-file infra/main.bicep \
  --parameters environmentName=prod
```

Or deploy standalone:

```bash
# Create resource group
az group create --name sec-automation-rg --location westeurope

# Deploy automation account
az deployment group create \
  --resource-group sec-automation-rg \
  --template-file infra/automation-account.bicep \
  --parameters \
    automationAccountName=sec-automation-prod \
    logAnalyticsWorkspaceId=/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}
```

### RBAC Permissions

The automation account's managed identity requires the following roles:

- **Reader**: To scan resources for compliance
- **Contributor**: To apply tags (for tagging runbook)
- **Security Reader**: To access security-related properties

Assign roles using:

```bash
# Get the managed identity principal ID
PRINCIPAL_ID=$(az automation account show \
  --name sec-automation-prod \
  --resource-group sec-automation-rg \
  --query identity.principalId -o tsv)

# Assign Reader role at subscription level
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Reader \
  --scope /subscriptions/{subscription-id}

# Assign Contributor role for tagging (if needed)
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/{subscription-id}
```

## Running Runbooks

### Manual Execution

Run a runbook manually:

```bash
# Start compliance check
az automation runbook start \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Security-ComplianceCheck \
  --parameters '{"SubscriptionId":"sub-id","ResourceGroupName":"rg-name"}'

# Start auto-tagging
az automation runbook start \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name Resource-AutoTagging \
  --parameters '{"Environment":"Production"}'
```

### View Job Results

```bash
# List recent jobs
az automation job list \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg

# Get job output
az automation job show \
  --automation-account-name sec-automation-prod \
  --resource-group sec-automation-rg \
  --name {job-id}
```

## Monitoring

### Diagnostics

All runbook job logs are sent to Log Analytics workspace:
- Job Logs: Runbook job execution logs
- Job Streams: Detailed output and errors
- Metrics: Job success/failure rates

Query logs in Log Analytics:

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.AUTOMATION"
| where Category == "JobLogs"
| project TimeGenerated, RunbookName_s, ResultType, JobId_g
| order by TimeGenerated desc
```

### Alerts

Configure alerts for failed jobs:

```bash
az monitor metrics alert create \
  --name automation-job-failures \
  --resource-group sec-automation-rg \
  --scopes /subscriptions/{sub-id}/resourceGroups/sec-automation-rg/providers/Microsoft.Automation/automationAccounts/sec-automation-prod \
  --condition "total TotalJob > 0 where ResultType = Failed" \
  --description "Alert on automation job failures"
```

## Security Considerations

1. **Managed Identity**: Uses system-assigned managed identity to avoid credential storage
2. **Private Access**: Public network access disabled by default
3. **Encryption**: All data encrypted at rest using Microsoft-managed keys
4. **Audit Logs**: All operations logged to Log Analytics
5. **RBAC**: Principle of least privilege - assign only required roles
6. **Soft Delete**: Runbooks support versioning for rollback

## Customization

### Adding New Runbooks

1. Create PowerShell script in `infra/runbooks/`
2. Add runbook resource to `automation-account.bicep`:

```bicep
resource myRunbook 'Microsoft.Automation/automationAccounts/runbooks@2023-11-01' = {
  parent: automationAccount
  name: 'My-CustomRunbook'
  location: location
  properties: {
    runbookType: 'PowerShell72'
    logProgress: true
    logVerbose: true
    description: 'My custom automation runbook'
    publishContentLink: {
      uri: 'https://your-storage-url/runbook.ps1'
    }
  }
}
```

### Modifying Schedules

Update the `complianceSchedule` resource in `automation-account.bicep`:

```bicep
resource complianceSchedule 'Microsoft.Automation/automationAccounts/schedules@2023-11-01' = {
  parent: automationAccount
  name: 'WeeklyComplianceCheck'
  properties: {
    interval: 1
    frequency: 'Week'  // Changed from 'Day'
    // ... other properties
  }
}
```

## Troubleshooting

### Common Issues

1. **Runbook fails with authentication error**
   - Verify managed identity has required RBAC roles
   - Check identity is enabled: `az automation account show --query identity`

2. **Schedule not triggering**
   - Verify schedule is linked to runbook
   - Check schedule start time is in the future
   - Review job history for errors

3. **Missing resources in compliance scan**
   - Ensure managed identity has Reader role at appropriate scope
   - Check resource group parameter is correct

### Debug Mode

Enable verbose logging in runbooks by adding:

```powershell
$VerbosePreference = "Continue"
Write-Verbose "Debug information here"
```

## Cost Optimization

- **Free Tier**: First 500 minutes/month free
- **Basic Tier**: $0.002/minute after free tier
- **Optimization Tips**:
  - Use schedules wisely (daily vs hourly)
  - Scope runbooks to specific resource groups
  - Monitor job duration and optimize scripts
  - Consider disabling schedules in dev environments

## Integration

### AI Workflow Orchestrator

The automation account integrates with `ai-workflow-orchestrator.sh`:

```bash
# Orchestrator automatically registers required providers
# and validates automation account deployment
QWE_DRY_RUN=true bash ai-workflow-orchestrator.sh
```

### CI/CD Pipeline

Bicep templates are validated in CI:

```yaml
- name: "Build Bicep Templates"
  run: |
    bicep build infra/automation-account.bicep --stdout
```

## References

- [Azure Automation Documentation](https://docs.microsoft.com/azure/automation/)
- [PowerShell Runbooks](https://docs.microsoft.com/azure/automation/automation-runbook-types)
- [Managed Identities](https://docs.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
