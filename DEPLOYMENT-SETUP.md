# Deployment Setup Guide

This guide will help you set up and deploy the enterprise-grade Azure security infrastructure following the recommended steps.

## Current Status

✅ **Code Ready**: All Bicep templates validated and committed  
✅ **Documentation Complete**: Enterprise guides available  
✅ **GitHub Repository**: https://github.com/BoozeLee/azure-security-hardening  
⏳ **Azure Configuration**: Requires Azure secrets setup  

## Step-by-Step Deployment Setup

### Step 1: Create Azure Service Principal

You need to create a service principal in Azure for GitHub Actions authentication.

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-azure-security" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id> \
  --sdk-auth
```

This will output JSON containing the credentials you need. **Save this securely!**

### Step 2: Configure GitHub Secrets

1. Go to your GitHub repository: https://github.com/BoozeLee/azure-security-hardening

2. Navigate to: **Settings** → **Secrets and variables** → **Actions**

3. Click **New repository secret** and add the following three secrets:

   | Secret Name | Value | Description |
   |-------------|-------|-------------|
   | `AZURE_CLIENT_ID` | From service principal output | Application (client) ID |
   | `AZURE_TENANT_ID` | From service principal output | Directory (tenant) ID |
   | `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | Target subscription |

   **Example from service principal output:**
   ```json
   {
     "clientId": "12345678-1234-1234-1234-123456789012",        // → AZURE_CLIENT_ID
     "tenantId": "87654321-4321-4321-4321-210987654321",        // → AZURE_TENANT_ID
     "subscriptionId": "abcdef12-3456-7890-abcd-ef1234567890"  // → AZURE_SUBSCRIPTION_ID
   }
   ```

### Step 3: Grant Additional Permissions (Required for Security Features)

The service principal needs additional permissions for Defender and Policy management:

```bash
# Get the service principal ID
SP_ID=$(az ad sp list --display-name "github-actions-azure-security" --query "[0].id" -o tsv)

# Assign Security Admin role (for Defender for Cloud)
az role assignment create \
  --assignee $SP_ID \
  --role "Security Admin" \
  --scope /subscriptions/<your-subscription-id>

# Assign Resource Policy Contributor (for Policy assignments)
az role assignment create \
  --assignee $SP_ID \
  --role "Resource Policy Contributor" \
  --scope /subscriptions/<your-subscription-id>
```

### Step 4: Configure Federated Credentials (Recommended for OIDC)

For enhanced security, configure OIDC instead of using secrets:

```bash
# Create federated credential for main branch
az ad app federated-credential create \
  --id <application-id> \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:BoozeLee/azure-security-hardening:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests
az ad app federated-credential create \
  --id <application-id> \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:BoozeLee/azure-security-hardening:pull_request",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Step 5: Trigger Deployment

Once secrets are configured, you can deploy in two ways:

#### Option A: Via GitHub Actions UI (Recommended)

1. Go to: https://github.com/BoozeLee/azure-security-hardening/actions
2. Select workflow: **Azure Security Hardening - Enterprise Edition**
3. Click **Run workflow**
4. Select environment: **prod**
5. Click **Run workflow** button
6. Monitor the deployment progress in real-time

#### Option B: Via GitHub CLI

```bash
# Install GitHub CLI if not already installed
# See: https://cli.github.com/

# Authenticate
gh auth login

# Trigger the workflow
gh workflow run "Azure Security Hardening - Enterprise Edition - High Threat Environment" \
  --repo BoozeLee/azure-security-hardening \
  --ref copilot/analyze-organization-profile \
  --field environment=prod

# Monitor the run
gh run watch --repo BoozeLee/azure-security-hardening
```

### Step 6: Monitor Deployment

Watch for these key steps in the workflow:

- ✅ Checkout Repository
- ✅ Azure Login via OIDC
- ✅ Install Azure CLI Extensions
- ✅ Validate Bicep Templates
- ✅ Preview Deployment (What-If)
- ✅ Deploy Azure Security Infrastructure
- ✅ Enable Microsoft Defender for Cloud (all 11 services)
- ✅ Configure Security Center Auto-Provisioning
- ✅ Configure Network Security
- ✅ Verify Security Policies
- ✅ Configure Diagnostic Settings
- ✅ Create Security Alerts
- ✅ Generate Security Compliance Report

### Step 7: Download Security Report

After deployment completes:

1. Go to the workflow run page
2. Scroll to **Artifacts** section at the bottom
3. Download **security-compliance-report**
4. Review the compliance status and recommendations

## Verification Checklist

After deployment, verify everything is working:

```bash
# Login to Azure
az login
az account set --subscription "<your-subscription-id>"

# Check deployed resources
az resource list --resource-group sec-bsp-rg-prod --output table

# Verify Defender for Cloud status
az security pricing list --query "[].{Service:name,Tier:pricingTier}" --output table

# Check compliance status
az policy state summarize --resource-group sec-bsp-rg-prod

# List security alerts
az monitor scheduled-query list --resource-group sec-bsp-rg-prod --output table

# Verify budgets
az consumption budget list --output table
```

## Expected Resources Deployed

After successful deployment, you should see:

- **Resource Group**: `sec-bsp-rg-prod`
- **Key Vault**: Premium tier with HSM-backed keys
- **Storage Account**: Zone-redundant with encryption
- **Virtual Network**: With DDoS Protection Standard
- **Azure Firewall**: Premium tier with IDS/IPS
- **Application Gateway**: WAF v2 with OWASP 3.2
- **Recovery Services Vault**: Geo-redundant backup
- **Log Analytics Workspace**: 90-day retention
- **Application Insights**: Enterprise monitoring
- **11 Microsoft Defender Plans**: All enabled

## Troubleshooting

### Issue: "Error: Azure login failed"

**Solution**: Verify your GitHub secrets are correctly configured:
- AZURE_CLIENT_ID
- AZURE_TENANT_ID  
- AZURE_SUBSCRIPTION_ID

### Issue: "Error: Insufficient permissions"

**Solution**: Ensure service principal has required roles:
- Contributor (for resource deployment)
- Security Admin (for Defender configuration)
- Resource Policy Contributor (for policy assignments)

### Issue: "Deployment validation failed"

**Solution**: 
1. Check the workflow logs for specific errors
2. Verify your Azure subscription has sufficient quota
3. Ensure the location (westeurope) supports all required services

### Issue: "Cost exceeds budget"

**Solution**: 
1. Review deployed resources in Azure Portal
2. Consider using Standard tier instead of Premium for Firewall
3. Adjust auto-scaling limits on Application Gateway
4. Disable Defender services not needed for your workload

## Post-Deployment Configuration

### 1. Configure Team-Based RBAC (Optional)

See `QUICK-START-ENTERPRISE.md` section: "Configure Team-Based RBAC"

### 2. Customize Firewall Rules

See `QUICK-START-ENTERPRISE.md` section: "Customize Firewall Rules"

### 3. Connect Applications to Application Insights

See `QUICK-START-ENTERPRISE.md` section: "Configure Application Insights"

### 4. Test Backup and Restore

See `QUICK-START-ENTERPRISE.md` section: "Test Backup and Restore"

## Cost Management

**Estimated Monthly Cost**: $5,744-7,844

Monitor your costs:
```bash
# View current month costs
az consumption usage list --output table

# Check budget status
az consumption budget list --output table

# View cost by resource group
az consumption usage list \
  --resource-group sec-bsp-rg-prod \
  --output table
```

## Support and Resources

- **Quick Start Guide**: `QUICK-START-ENTERPRISE.md`
- **Enterprise Documentation**: `README-ENTERPRISE.md`
- **Upgrade Summary**: `ENTERPRISE-UPGRADE-SUMMARY.md`
- **Security Contact**: kiliaan@bakerstreetproject221b.store
- **Repository**: https://github.com/BoozeLee/azure-security-hardening

## Security Best Practices

⚠️ **IMPORTANT**:
- Never commit Azure credentials to Git
- Rotate service principal credentials regularly (every 90 days)
- Use Azure Key Vault for application secrets
- Enable MFA for all Azure admin accounts
- Review Security Center recommendations weekly
- Monitor cost alerts and anomalies
- Test disaster recovery procedures quarterly

---

**Ready to deploy?** Follow the steps above and your enterprise-grade Azure security infrastructure will be operational within 30-45 minutes.
