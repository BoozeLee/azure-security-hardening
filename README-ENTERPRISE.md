# Azure Security Hardening - Enterprise Edition

> **Enterprise-grade security** for Azure infrastructure deployment with comprehensive compliance frameworks, advanced threat protection, and enterprise governance.

## 📋 Project Overview

This repository contains Azure Bicep templates and GitHub Actions workflows for deploying enterprise-grade security-hardened Azure infrastructure. The configuration implements defense-in-depth security principles with full compliance framework support.

**Owner:** kiliaan@bakerstreetproject221b.store  
**Environment:** Production  
**Tier:** Enterprise  
**Threat Level:** High  
**Compliance:** Multi-Framework Support (ISO 27001, SOC 2, HIPAA, PCI DSS, NIST)  

## 🏗️ Architecture Components

### Core Infrastructure
- **Key Vault**: Premium tier with HSM-backed keys, private endpoints, and RBAC
- **Storage Account**: ZRS with customer-managed encryption and private endpoints
- **Virtual Network**: DDoS Protection Standard, restrictive NSGs, and service endpoints
- **Log Analytics**: Centralized logging with 90-day retention
- **Security Center**: Defender for ALL services with enhanced enterprise features
- **Recovery Services Vault**: Enterprise backup with geo-redundant storage and cross-region restore
- **Azure Firewall**: Premium tier with threat intelligence and IDS/IPS
- **Web Application Firewall**: OWASP 3.2 protection with bot management
- **Application Insights**: Enterprise application monitoring and telemetry

### Enterprise Security Features
- ✅ **Comprehensive Defender for Cloud** - Protection for Servers, Storage, Key Vault, SQL, Containers, App Services, Databases, Resource Manager, and DNS
- ✅ **Multi-Framework Compliance** - ISO 27001, SOC 2, HIPAA, PCI DSS, NIST SP 800-53
- ✅ **Zero Public Access** - All resources behind private endpoints
- ✅ **Encryption at Rest & Transit** - Customer-managed keys from Key Vault
- ✅ **Network Isolation** - VNet with Azure Firewall Premium and WAF
- ✅ **Advanced Threat Protection** - IDS/IPS, threat intelligence, and behavioral analytics
- ✅ **Comprehensive Logging** - Diagnostic settings for all resources with 90-day retention
- ✅ **Policy Enforcement** - Azure Policy for compliance automation
- ✅ **Enterprise RBAC** - Team-based access control (Security, Development, Operations)
- ✅ **Disaster Recovery** - Geo-redundant backup with cross-region restore
- ✅ **Cost Management** - Multi-tier budgets with proactive alerts
- ✅ **Advanced Monitoring** - Application Insights with custom alerts and dashboards

## 📁 Repository Structure

```
azure-security-hardening/
├── .vscode/                           # VS Code workspace configuration
├── .github/workflows/                 # GitHub Actions workflows
│   └── azure-security-hardening.yml  # Main deployment workflow
├── .copilot/                          # GitHub Copilot configuration
├── infra/                             # Bicep infrastructure templates
│   ├── main.bicep                    # Main orchestration template
│   ├── keyvault.bicep                # Key Vault with maximum security
│   ├── storage.bicep                 # Secure storage configuration
│   ├── network-security.bicep        # VNet, NSG, and DDoS Protection
│   ├── security-center.bicep         # Defender for Cloud (all services)
│   ├── log-analytics.bicep           # Centralized logging
│   ├── azure-policy.bicep            # Policy assignments
│   ├── compliance-frameworks.bicep   # Enterprise compliance (ISO, SOC2, HIPAA, PCI, NIST)
│   ├── backup-recovery.bicep         # Enterprise backup and disaster recovery
│   ├── enterprise-network-security.bicep  # Azure Firewall Premium and WAF
│   ├── enterprise-monitoring.bicep   # Advanced monitoring and alerting
│   ├── enterprise-rbac.bicep         # Team-based RBAC templates
│   └── cost-management.bicep         # Budget management and cost alerts
├── deploy-security.sh                # Direct deployment script
├── trigger-security-deployment.sh    # GitHub Actions trigger
└── README.md                         # This file
```

## 🚀 Quick Start

### Prerequisites
- Azure CLI installed and authenticated
- Azure subscription with Enterprise Agreement or Pay-As-You-Go
- Proper Azure permissions (Owner or Contributor + Security Admin)
- Azure AD groups for team-based RBAC (optional)

### Deploy Enterprise Infrastructure

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Validate Templates**:
   ```bash
   az deployment sub validate \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  securityContactEmail=your-email@company.com
   ```

3. **Deploy Infrastructure**:
   ```bash
   az deployment sub create \
     --name "enterprise-security-$(date +%Y%m%d-%H%M%S)" \
     --location westeurope \
     --template-file infra/main.bicep \
     --parameters environmentName=prod \
                  securityContactEmail=your-email@company.com
   ```

## 🛡️ Enterprise Security Features

### Microsoft Defender for Cloud - Complete Coverage
- **Defender for Servers** - VM threat detection and vulnerability assessment
- **Defender for Storage** - Malware scanning and anomaly detection
- **Defender for Key Vault** - Secret access monitoring
- **Defender for SQL** - SQL threat protection and vulnerability assessment
- **Defender for Containers** - Container registry and Kubernetes security
- **Defender for App Service** - Web application threat detection
- **Defender for Open-Source Databases** - PostgreSQL, MySQL, MariaDB protection
- **Defender for Azure Cosmos DB** - NoSQL database threat protection
- **Defender for Resource Manager** - Control plane attack detection
- **Defender for DNS** - DNS layer threat detection

### Compliance Frameworks
All major compliance frameworks are automatically enforced:
- **ISO 27001:2013** - Information security management
- **SOC 2 Type 2** - Trust service criteria
- **HIPAA/HITRUST** - Healthcare data protection
- **PCI DSS 3.2.1** - Payment card data security
- **NIST SP 800-53 Rev. 5** - Federal security controls

### Network Security
- **Azure Firewall Premium** - Application and network filtering with IDS/IPS
- **Web Application Firewall** - OWASP 3.2 protection with bot management
- **DDoS Protection Standard** - Network-layer DDoS mitigation
- **Network Security Groups** - Zero-trust network policies
- **Private Endpoints** - All resources isolated from public internet

### Backup and Disaster Recovery
- **Geo-Redundant Backup** - Data replicated across Azure regions
- **Cross-Region Restore** - Restore to paired region during disasters
- **10-Year Retention** - Long-term backup retention for compliance
- **Multiple Policies** - VM, SQL, and File Share backup policies

### Enterprise Monitoring
- **Application Insights** - Application performance monitoring
- **Advanced Alerts** - 8+ pre-configured security and performance alerts
- **Custom Dashboards** - Executive and operational dashboards
- **Log Analytics** - Centralized logging with 90-day retention

### Cost Management
- **Multi-Tier Budgets** - Monthly, quarterly, and annual budgets
- **Proactive Alerts** - Notifications at 50%, 75%, 90%, 100%, and 110% thresholds
- **Cost Anomaly Detection** - Alerts for unexpected cost increases
- **Forecasting** - Budget forecasting for financial planning

### Enterprise RBAC (Optional)
Team-based access control templates for:
- **Security Team** - Security Admin, Security Reader, Key Vault Administrator
- **Development Team** - Contributor, Storage Blob Contributor, Key Vault Secrets User
- **Operations Team** - Monitoring Contributor, Log Analytics Contributor, Backup Contributor

Configure by uncommenting the RBAC module in `main.bicep` and providing Azure AD group IDs.

## 📊 Cost Considerations

Enterprise-grade security comes with costs. Estimated monthly costs for a typical deployment:

| Service | SKU/Tier | Estimated Monthly Cost |
|---------|----------|------------------------|
| Microsoft Defender for Cloud | All Plans | $300-500 |
| Azure Firewall Premium | 2 instances | $1,500-2,000 |
| Application Gateway WAF v2 | Autoscale (2-10) | $500-1,000 |
| DDoS Protection Standard | Per VNet | $2,944 |
| Log Analytics | Per GB ingestion | $200-500 |
| Recovery Services Vault | Based on protected data | $100-300 |
| Key Vault Premium | HSM-backed keys | $50-100 |
| Storage ZRS | Based on data stored | $50-200 |
| Application Insights | Per GB ingestion | $100-300 |
| **Total Estimated** | | **$5,744-7,844/month** |

*Costs vary based on usage, data volume, and region. Use Azure Cost Calculator for precise estimates.*

## 🔧 Configuration Options

### Environment Variables
Set these parameters when deploying:
- `environmentName` - Environment identifier (prod, staging, dev)
- `location` - Azure region (westeurope, eastus, etc.)
- `securityContactEmail` - Email for security alerts
- `resourcePrefix` - Naming prefix for resources (default: sec-bsp)

### Optional Modules
Some enterprise features can be enabled/disabled:
- **Compliance Frameworks** - Enable/disable specific frameworks in `compliance-frameworks.bicep`
- **Azure Firewall Premium** - Can use Standard tier by setting `enablePremiumFirewall: false`
- **Geo-Redundant Backup** - Can use Locally Redundant by setting `enableGeoRedundantBackup: false`
- **Enterprise RBAC** - Uncomment in `main.bicep` and configure Azure AD group IDs

## 🔐 Security Best Practices

- **No Secrets in Code** - All sensitive values use Key Vault references
- **Network Isolation** - All resources use private endpoints
- **Encryption Everywhere** - Customer-managed keys for all data
- **Monitoring Always On** - Comprehensive logging and alerting
- **Compliance First** - Multiple framework enforcement
- **Team-Based Access** - RBAC with least privilege principle
- **Regular Backups** - Automated backup with long-term retention
- **Disaster Recovery Ready** - Cross-region restore capability

## 🤝 Contributing

When contributing to this repository:
1. Follow the established naming conventions (prefix: `sec-bsp`)
2. Ensure all resources implement maximum security controls
3. Update documentation for any new components
4. Test compliance impact before submitting changes
5. Validate cost implications of new resources

## 📞 Support

For questions or issues:
- **Owner**: kiliaan@bakerstreetproject221b.store
- **GitHub Issues**: Use repository issues for tracking
- **Security Concerns**: Contact owner directly for security-related issues

## 📋 Deployment Checklist

Before deploying to production:

- [ ] Review and adjust monthly budget amount ($10,000 default)
- [ ] Configure Azure AD groups for RBAC (if using team-based access)
- [ ] Review compliance frameworks and disable any not required
- [ ] Verify security contact email is correct
- [ ] Confirm Azure subscription has sufficient quota
- [ ] Review estimated costs and get budget approval
- [ ] Plan for backup storage requirements
- [ ] Configure private connectivity for accessing resources
- [ ] Review and customize firewall and WAF rules for your applications
- [ ] Set up incident response procedures for security alerts

---

**⚠️ Important**: This is an enterprise-grade deployment designed for high-threat environments with comprehensive compliance requirements. Review all costs and configurations before deployment. Do not modify security settings without proper review and approval.

## 🎯 What's New in Enterprise Edition

Compared to the standard deployment, Enterprise Edition adds:

✨ **Enhanced Defender Coverage** - 6 additional Defender plans (Containers, App Service, SQL, Open-Source DBs, Cosmos DB)  
✨ **Multi-Framework Compliance** - ISO 27001, SOC 2, HIPAA, PCI DSS, NIST enforcement  
✨ **Enterprise Backup** - Geo-redundant with cross-region restore  
✨ **Azure Firewall Premium** - IDS/IPS and threat intelligence  
✨ **Web Application Firewall** - OWASP 3.2 and bot protection  
✨ **Advanced Monitoring** - Application Insights with 8+ custom alerts  
✨ **Cost Management** - Multi-tier budgets with anomaly detection  
✨ **Enterprise RBAC** - Pre-configured team-based access control  
✨ **10-Year Retention** - Long-term backup compliance  

This represents a complete enterprise-ready security posture for Azure.
