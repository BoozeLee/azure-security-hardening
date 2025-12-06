# Quick Start Guide - Enterprise Deployment

This guide provides step-by-step instructions for deploying the enterprise-grade Azure security infrastructure.

## Prerequisites Checklist

Before deploying, ensure you have:

- [ ] Azure subscription with Enterprise Agreement or Pay-As-You-Go
- [ ] Azure CLI installed and authenticated (`az --version`)
- [ ] Owner or Contributor + Security Admin permissions
- [ ] Budget approval (~$5,744-7,844/month)
- [ ] Security contact email address
- [ ] (Optional) Azure AD groups for team-based RBAC

## Deployment Options

### Option 1: GitHub Actions (Recommended)

**Advantages:**
- Automated deployment with validation
- Security compliance report generated
- Deployment history tracked
- Easy rollback if needed

**Steps:**

1. **Configure GitHub Secrets**
   
   In your GitHub repository, go to Settings → Secrets and variables → Actions
   
   Add these secrets:
   ```
   AZURE_CLIENT_ID: <your-service-principal-client-id>
   AZURE_TENANT_ID: <your-azure-ad-tenant-id>
   AZURE_SUBSCRIPTION_ID: <your-subscription-id>
   ```

2. **Trigger Deployment**
   
   - Go to Actions tab in GitHub
   - Select "Azure Security Hardening - Enterprise Edition"
   - Click "Run workflow"
   - Select environment (prod recommended)
   - Click "Run workflow" button

3. **Monitor Progress**
   
   - Watch the workflow execution in real-time
   - Check each step for success ✅
   - Review the security compliance report

4. **Download Report**
   
   - After completion, download the security-compliance-report artifact
   - Review compliance status and recommendations

### Option 2: Azure CLI (Direct)

**Advantages:**
- Full control over deployment
- Immediate feedback
- No CI/CD setup required

**Steps:**

1. **Login to Azure**
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   az account show
   ```

2. **Clone Repository**
   ```bash
   git clone https://github.com/BoozeLee/azure-security-hardening.git
   cd azure-security-hardening
   ```

3. **Validate Templates**
   ```bash
   az deployment sub validate \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  location=westeurope \
                  securityContactEmail=your-email@company.com \
                  resourcePrefix=sec-bsp
   ```

4. **Preview Changes (What-If)**
   ```bash
   az deployment sub what-if \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  location=westeurope \
                  securityContactEmail=your-email@company.com \
                  resourcePrefix=sec-bsp
   ```

5. **Deploy Infrastructure**
   ```bash
   az deployment sub create \
     --name "enterprise-security-$(date +%Y%m%d-%H%M%S)" \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  location=westeurope \
                  securityContactEmail=your-email@company.com \
                  resourcePrefix=sec-bsp \
     --confirm-with-what-if
   ```

6. **Enable All Defender Services**
   ```bash
   # Execute the commands from .github/workflows/azure-security-hardening.yml
   # Lines 100-130 (Defender for Cloud configuration)
   
   az security pricing create --name VirtualMachines --tier Standard
   az security pricing create --name StorageAccounts --tier Standard
   az security pricing create --name KeyVaults --tier Standard
   az security pricing create --name Arm --tier Standard
   az security pricing create --name Dns --tier Standard
   az security pricing create --name Containers --tier Standard
   az security pricing create --name AppServices --tier Standard
   az security pricing create --name SqlServers --tier Standard
   az security pricing create --name SqlServerVirtualMachines --tier Standard
   az security pricing create --name OpenSourceRelationalDatabases --tier Standard
   az security pricing create --name CosmosDbs --tier Standard
   ```

## Post-Deployment Configuration

### 1. Configure Team-Based RBAC (Optional)

If you want to use team-based access control:

1. **Create Azure AD Groups**
   ```bash
   # In Azure Portal: Azure Active Directory → Groups → New Group
   # Create three groups:
   - Security Team
   - Development Team
   - Operations Team
   ```

2. **Get Group Object IDs**
   ```bash
   az ad group show --group "Security Team" --query id -o tsv
   az ad group show --group "Development Team" --query id -o tsv
   az ad group show --group "Operations Team" --query id -o tsv
   ```

3. **Update main.bicep**
   
   Uncomment the RBAC module section (lines 197-208) and update with your group IDs:
   ```bicep
   module enterpriseRBAC 'enterprise-rbac.bicep' = {
     name: 'enterpriseRBACDeployment'
     scope: resourceGroup
     params: {
       securityTeamGroupId: '<security-team-group-id>'
       devTeamGroupId: '<dev-team-group-id>'
       opsTeamGroupId: '<ops-team-group-id>'
       enableSecurityTeam: true
       enableDevTeam: true
       enableOpsTeam: true
     }
   }
   ```

4. **Redeploy**
   ```bash
   az deployment sub create \
     --name "rbac-update-$(date +%Y%m%d-%H%M%S)" \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  securityContactEmail=your-email@company.com
   ```

### 2. Adjust Budget

The default monthly budget is $10,000. To adjust:

1. Open `infra/main.bicep`
2. Find the `costManagement` module (around line 165)
3. Change `monthlyBudgetAmount: 10000` to your desired amount
4. Redeploy

Or update directly in Azure Portal:
- Cost Management → Budgets → EnterpriseMonthlyCostBudget → Edit

### 3. Customize Firewall Rules

The default firewall rules allow Azure services. To add custom rules:

1. Open `infra/enterprise-network-security.bicep`
2. Find `appRuleCollection` resource (around line 98)
3. Add your application rules
4. Redeploy the network security module only:
   ```bash
   az deployment group create \
     --resource-group sec-bsp-rg-prod \
     --template-file infra/enterprise-network-security.bicep \
     --parameters firewallName=sec-bsp-fw-prod \
                  vnetName=sec-bsp-vnet-prod \
                  logAnalyticsWorkspaceId=/subscriptions/.../workspaces/sec-bsp-law-prod
   ```

### 4. Configure Application Insights

Connect your applications to Application Insights:

1. **Get Connection String**
   ```bash
   az monitor app-insights component show \
     --resource-group sec-bsp-rg-prod \
     --app enterprise-appinsights \
     --query connectionString -o tsv
   ```

2. **Add to Application Configuration**
   
   For .NET applications:
   ```json
   {
     "ApplicationInsights": {
       "ConnectionString": "<your-connection-string>"
     }
   }
   ```
   
   For Node.js:
   ```javascript
   const appInsights = require("applicationinsights");
   appInsights.setup("<your-connection-string>");
   appInsights.start();
   ```

### 5. Test Backup and Restore

Validate backup configuration:

```bash
# List backup policies
az backup policy list \
  --resource-group sec-bsp-rg-prod \
  --vault-name sec-bsp-rsv-prod

# Test backup (after creating a VM)
az backup protection enable-for-vm \
  --resource-group sec-bsp-rg-prod \
  --vault-name sec-bsp-rsv-prod \
  --vm <vm-name> \
  --policy-name EnterpriseVMBackupPolicy

# Trigger backup
az backup protection backup-now \
  --resource-group sec-bsp-rg-prod \
  --vault-name sec-bsp-rsv-prod \
  --container-name <vm-name> \
  --item-name <vm-name>
```

## Verification Steps

After deployment, verify everything is working:

### 1. Check Resource Deployment

```bash
# List all resources in resource group
az resource list \
  --resource-group sec-bsp-rg-prod \
  --output table
```

Expected resources:
- Key Vault (Premium)
- Storage Account (ZRS)
- Virtual Network with subnets
- Azure Firewall Premium
- Application Gateway (WAF)
- Recovery Services Vault
- Log Analytics Workspace
- Application Insights

### 2. Verify Defender for Cloud

```bash
# Check all Defender plans
az security pricing list \
  --query "[].{Service:name,Tier:pricingTier}" \
  --output table
```

All services should show "Standard" tier.

### 3. Check Compliance Status

```bash
# View policy compliance
az policy state summarize \
  --resource-group sec-bsp-rg-prod
```

### 4. Test Alerts

Verify alerts are configured:

```bash
# List alert rules
az monitor scheduled-query list \
  --resource-group sec-bsp-rg-prod \
  --output table
```

You should see 8+ alert rules.

### 5. Verify Budgets

```bash
# List budgets
az consumption budget list \
  --output table
```

You should see monthly, quarterly, and annual budgets.

## Troubleshooting

### Common Issues

**Issue: Deployment fails with quota error**
```
Solution: Request quota increase in Azure Portal
Settings → Quotas → Request increase
```

**Issue: Firewall deployment fails with subnet conflict**
```
Solution: The firewall creates its own subnets. Ensure VNet has available address space.
Check: infra/network-security.bicep for VNet configuration (10.0.0.0/16)
```

**Issue: Cost exceeds budget**
```
Solution: Review deployed resources and scale down if needed:
- Azure Firewall: Consider Standard tier instead of Premium
- Application Gateway: Reduce max instance count in autoscaling
- Defender services: Disable services not needed for your workload
```

**Issue: Private endpoint connectivity**
```
Solution: Ensure you have private connectivity configured:
- Azure VPN Gateway or ExpressRoute for on-premises
- VNet peering for other Azure VNets
- Azure Bastion for VM management
```

## Support

For assistance:
- Check logs in Log Analytics Workspace
- Review Azure Advisor recommendations
- Check Security Center recommendations
- Contact: kiliaan@bakerstreetproject221b.store

## Next Steps

After successful deployment:

1. [ ] Review security compliance report
2. [ ] Configure application connections to private endpoints
3. [ ] Set up monitoring dashboards
4. [ ] Train team members on new security features
5. [ ] Schedule monthly security reviews
6. [ ] Test disaster recovery procedures
7. [ ] Document custom configurations
8. [ ] Set up incident response procedures

---

**Congratulations!** You now have an enterprise-grade Azure security infrastructure.

For detailed information, see:
- `README-ENTERPRISE.md` - Full documentation
- `ENTERPRISE-UPGRADE-SUMMARY.md` - Upgrade details
- `.github/workflows/azure-security-hardening.yml` - Automation workflow
