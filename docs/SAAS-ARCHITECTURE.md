# 🏗️ SaaS Platform Architecture

## Overview

This document describes the complete multi-tenant SaaS architecture built on top of the Azure Security Hardening foundation.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Users                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Azure Front Door (Global)                      │
│  • WAF Protection          • SSL Termination                     │
│  • DDoS Protection         • Global Load Balancing               │
│  • Rate Limiting           • Geo-filtering                       │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  API Management (Gateway)                        │
│  • API Versioning          • Subscription Management             │
│  • Rate Limiting/Tenant    • JWT Validation                      │
│  • Multi-tier Products     • Request/Response Transformation     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    App Service (Python 3.11)                     │
│  • Auto-scaling (2-10 instances)                                 │
│  • VNet Integration                                              │
│  • Managed Identity                                              │
│  • Application Insights                                          │
└─────────┬───────────────────────────────────┬───────────────────┘
          │                                   │
          ▼                                   ▼
┌──────────────────────┐          ┌──────────────────────┐
│   SQL Database       │          │   Redis Cache        │
│   (Multi-Tenant)     │          │   (Sessions)         │
│                      │          │                      │
│ • Schema per Tenant  │          │ • Namespace/Tenant   │
│ • TDE Encryption     │          │ • Premium Tier       │
│ • Geo-Replication    │          │ • Zone Redundant     │
│ • Private Endpoint   │          │ • Private Endpoint   │
└──────────────────────┘          └──────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Key Vault (Premium)                         │
│  • Customer-Managed Keys    • API Keys per Tenant                │
│  • HSM-backed              • Secrets Management                  │
│  • Private Endpoint        • RBAC Authorization                  │
└─────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Log Analytics Workspace                        │
│  • Centralized Logging     • 90-day Retention                    │
│  • Security Monitoring     • Custom Queries                      │
│  • Application Insights    • Alerts & Dashboards                 │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Azure Front Door
- **Purpose**: Global CDN, WAF, and DDoS protection
- **Features**:
  - SSL/TLS termination
  - Geo-filtering (US, EU, GB, CA, AU only)
  - Rate limiting (1000 requests/minute per IP)
  - Bot protection
  - Custom domain support

### 2. API Management
- **Purpose**: API gateway and subscription management
- **Features**:
  - Multi-tier products (Free, Professional, Enterprise)
  - Per-tenant rate limiting and quotas
  - JWT validation
  - API versioning
  - Request/response transformation

**Tier Limits**:
| Tier | Rate Limit | Daily Quota | Features |
|------|-----------|-------------|----------|
| Free | 100/hour | 1,000/day | Basic API access |
| Professional | 1,000/hour | 10,000/day | Priority support |
| Enterprise | Unlimited | Unlimited | Dedicated support, SLA |

### 3. App Service
- **Purpose**: Host SaaS application
- **Configuration**:
  - Python 3.11 runtime
  - Auto-scaling (2-10 instances)
  - VNet integration for secure connectivity
  - Managed identity for Azure resource access
  - Application Insights for monitoring

### 4. SQL Database
- **Purpose**: Multi-tenant data storage
- **Architecture**: Schema-per-tenant isolation
- **Features**:
  - Transparent Data Encryption (TDE)
  - Geo-replication for disaster recovery
  - Advanced Threat Protection
  - Vulnerability Assessment
  - 90-day audit retention

**Schema Structure**:
```sql
-- Each tenant gets a dedicated schema
CREATE SCHEMA [tenant_acme_corp];

-- Tenant configuration
CREATE TABLE [tenant_acme_corp].[config] (
    tenant_id NVARCHAR(100),
    tier NVARCHAR(50),
    status NVARCHAR(50)
);

-- Tenant users
CREATE TABLE [tenant_acme_corp].[users] (
    user_id UNIQUEIDENTIFIER,
    email NVARCHAR(255),
    role NVARCHAR(50)
);

-- Tenant data
CREATE TABLE [tenant_acme_corp].[data] (
    data_id UNIQUEIDENTIFIER,
    user_id UNIQUEIDENTIFIER,
    content NVARCHAR(MAX)
);
```

### 5. Redis Cache
- **Purpose**: Session management and caching
- **Configuration**:
  - Premium tier for production
  - Zone redundancy
  - Namespace per tenant: `tenant-{id}:*`
  - Private endpoint only

### 6. Key Vault
- **Purpose**: Secrets and key management
- **Stored Items**:
  - API keys per tenant
  - Database encryption keys
  - Application secrets
  - SSL certificates

### 7. Storage Account
- **Purpose**: Tenant file storage
- **Configuration**:
  - Container per tenant: `tenant-{id}`
  - Private endpoints only
  - Customer-managed encryption
  - Geo-redundant storage

## Multi-Tenancy Strategy

### Tenant Isolation

1. **Database Level**: Schema-per-tenant
   - Pros: Strong isolation, easy to backup/restore individual tenants
   - Cons: Schema management complexity

2. **Cache Level**: Namespace-per-tenant
   - Keys: `tenant-{id}:session:{session-id}`
   - Prevents cross-tenant data leakage

3. **Storage Level**: Container-per-tenant
   - Blob path: `/tenant-{id}/user-{user-id}/file.pdf`
   - Access control via SAS tokens

4. **API Level**: Subscription-per-tenant
   - Rate limiting enforced per subscription
   - Usage tracking per tenant

### Tenant Onboarding Flow

```
1. Customer signs up
   ↓
2. Stripe webhook triggers onboarding
   ↓
3. Create database schema
   ↓
4. Generate API keys → Store in Key Vault
   ↓
5. Create APIM subscription
   ↓
6. Create storage container
   ↓
7. Configure Redis namespace
   ↓
8. Send welcome email with credentials
```

**Automation**: `./scripts/saas-onboard-customer.sh <tenant-id> <email> <tier>`

### Tenant Offboarding Flow

```
1. Customer cancels subscription
   ↓
2. Backup tenant data to archive storage
   ↓
3. Disable API subscription
   ↓
4. Revoke API keys
   ↓
5. Clear Redis cache
   ↓
6. Mark tenant as inactive in database
   ↓
7. Retain data for 90 days (compliance)
   ↓
8. Permanent deletion after retention period
```

**Automation**: `./scripts/saas-offboard-customer.sh <tenant-id> [backup]`

## Security Features

### Network Security
- ✅ All resources behind private endpoints
- ✅ No public internet access
- ✅ VNet integration for App Service
- ✅ DDoS protection on Front Door
- ✅ WAF with OWASP rules

### Data Security
- ✅ Encryption at rest (customer-managed keys)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ Database TDE enabled
- ✅ Secrets in Key Vault only
- ✅ No credentials in code

### Identity & Access
- ✅ Managed identities for Azure resources
- ✅ RBAC for all components
- ✅ JWT validation on API gateway
- ✅ Per-tenant API keys
- ✅ Azure AD integration ready

### Monitoring & Compliance
- ✅ Centralized logging (90 days)
- ✅ Security alerts configured
- ✅ Vulnerability scanning
- ✅ Audit logs enabled
- ✅ Application Insights

## Scaling Strategy

### Horizontal Scaling
- **App Service**: Auto-scale 2-10 instances based on CPU
- **SQL Database**: Read replicas for read-heavy workloads
- **Redis Cache**: Cluster mode for high throughput

### Vertical Scaling
- **App Service**: P1v3 → P2v3 → P3v3
- **SQL Database**: GP_Gen5_2 → GP_Gen5_4 → GP_Gen5_8
- **Redis Cache**: P1 → P2 → P3

### Geographic Distribution
- **Front Door**: Global edge locations
- **SQL Database**: Geo-replication to secondary region
- **Storage**: GRS (Geo-redundant storage)

## Cost Optimization

### Development Environment
- App Service: B1 (Basic)
- SQL Database: Basic tier
- Redis: Basic C0
- **Estimated**: ~$150/month

### Production Environment
- App Service: P1v3 (2 instances)
- SQL Database: GP_Gen5_2
- Redis: Premium P1
- Front Door: Premium
- **Estimated**: ~$800-1,200/month

### Cost Reduction Tips
1. Use reserved instances (1-year commitment = 30% savings)
2. Auto-shutdown dev environments
3. Use Azure Hybrid Benefit if applicable
4. Monitor and optimize database DTU usage

## Deployment

### Prerequisites
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Set subscription
az account set --subscription "your-subscription-id"
```

### Deploy Complete Platform
```bash
# Interactive deployment
./scripts/saas-deploy-full.sh

# Or manual deployment
az deployment sub create \
  --location westeurope \
  --template-file infra/main-saas.bicep \
  --parameters \
    environmentName=prod \
    securityContactEmail=your-email@company.com \
    sqlAdminLogin=sqladmin \
    sqlAdminPassword='YourSecurePassword123!' \
    enableSaaSComponents=true
```

### Post-Deployment
1. Configure custom domain in Front Door
2. Deploy application code to App Service
3. Run database migrations
4. Test API endpoints
5. Onboard first customer

## Monitoring & Operations

### Key Metrics to Monitor
- **App Service**: CPU %, Memory %, Response Time
- **SQL Database**: DTU %, Query Performance
- **Redis**: Cache Hit Rate, Memory Usage
- **Front Door**: Request Count, Error Rate
- **API Management**: Request Count per Tenant

### Alerts Configuration
- CPU > 80% for 5 minutes
- Memory > 90% for 5 minutes
- SQL DTU > 80% for 10 minutes
- Error rate > 5% for 5 minutes
- Failed login attempts > 10 in 1 minute

### Backup Strategy
- **SQL Database**: Automated daily backups (35 days retention)
- **Storage**: Soft delete enabled (90 days)
- **Tenant Data**: Manual backup before offboarding

## Disaster Recovery

### RTO/RPO Targets
- **RTO** (Recovery Time Objective): 4 hours
- **RPO** (Recovery Point Objective): 1 hour

### DR Procedures
1. **Database**: Geo-restore from replica
2. **Storage**: Failover to secondary region
3. **App Service**: Deploy to secondary region
4. **Front Door**: Automatic failover

## Compliance & Certifications

### Supported Frameworks
- ✅ SOC 2 Type II
- ✅ ISO 27001
- ✅ GDPR
- ✅ HIPAA (with additional configuration)
- ✅ PCI DSS Level 1

### Audit Trail
- All API requests logged
- Database access audited
- Administrative actions tracked
- 90-day retention minimum

## Support & Maintenance

### Regular Maintenance
- **Weekly**: Review security alerts
- **Monthly**: Update dependencies
- **Quarterly**: Security audit
- **Annually**: Disaster recovery drill

### Support Tiers
- **Free**: Community support (GitHub issues)
- **Professional**: Email support (30 days)
- **Enterprise**: Dedicated support (90 days) + SLA

---

## Questions?

📧 **Technical Support**: support@bakerstreetproject.com  
📧 **Sales**: kiliaan@bakerstreetproject.com  
📚 **Documentation**: https://docs.bakerstreetproject.com